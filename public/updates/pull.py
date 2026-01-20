#!/usr/bin/env python3
import os
import re
import json
import requests
from pathlib import Path
from urllib.parse import urlparse
from concurrent.futures import ThreadPoolExecutor, as_completed
from tqdm import tqdm
import argparse
from datetime import datetime

class ImgurDownloader:
    def __init__(self, root_dir, max_workers=5, revert=False):
        self.root_dir = root_dir
        self.max_workers = max_workers
        self.revert = revert
        self.backup_file = os.path.join(root_dir, '.imgur_backup.json')
        self.backup_data = {}

    def find_imgur_links(self, content):
        """Find all imgur links in markdown content, including those missing 'h'"""
        pattern = r'(?:https?://|ttps://|ttp://)i\.imgur\.com/[a-zA-Z0-9]+\.[a-zA-Z]+'
        return re.findall(pattern, content)

    def fix_url(self, url):
        """Fix URLs that are missing the 'h' in http/https"""
        if url.startswith('ttps://'):
            return 'h' + url
        elif url.startswith('ttp://'):
            return 'h' + url
        return url

    def download_image(self, url, save_path):
        """Download image from URL to specified path"""
        try:
            url = self.fix_url(url)

            headers = {
                'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36'
            }
            response = requests.get(url, headers=headers, timeout=15, stream=True)
            response.raise_for_status()

            # Get total file size
            total_size = int(response.headers.get('content-length', 0))

            with open(save_path, 'wb') as f:
                if total_size == 0:
                    f.write(response.content)
                else:
                    for chunk in response.iter_content(chunk_size=8192):
                        f.write(chunk)

            return True, None
        except Exception as e:
            return False, str(e)

    def save_backup(self):
        """Save backup data to JSON file"""
        try:
            with open(self.backup_file, 'w', encoding='utf-8') as f:
                json.dump(self.backup_data, f, indent=2)
            return True
        except Exception as e:
            print(f"❌ Failed to save backup: {e}")
            return False

    def load_backup(self):
        """Load backup data from JSON file"""
        try:
            if os.path.exists(self.backup_file):
                with open(self.backup_file, 'r', encoding='utf-8') as f:
                    return json.load(f)
            return {}
        except Exception as e:
            print(f"❌ Failed to load backup: {e}")
            return {}

    def revert_changes(self):
        """Revert all changes using backup data"""
        backup = self.load_backup()

        if not backup:
            print("❌ No backup file found!")
            return

        print(f"🔄 Reverting changes from backup...")
        print(f"📅 Backup created: {backup.get('timestamp', 'Unknown')}")

        files = backup.get('files', {})
        if not files:
            print("❌ No files to revert!")
            return

        reverted = 0
        errors = 0

        with tqdm(total=len(files), desc="Reverting files", unit="file") as pbar:
            for file_path, data in files.items():
                try:
                    # Restore original content
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(data['original_content'])

                    # Remove downloaded images
                    md_dir = os.path.dirname(file_path)
                    for img in data.get('downloaded_images', []):
                        img_path = os.path.join(md_dir, img)
                        if os.path.exists(img_path):
                            os.remove(img_path)

                    reverted += 1
                except Exception as e:
                    print(f"\n❌ Error reverting {file_path}: {e}")
                    errors += 1

                pbar.update(1)

        print(f"\n✅ Reverted {reverted} file(s)")
        if errors > 0:
            print(f"⚠️  {errors} error(s) occurred")

        # Remove backup file
        try:
            os.remove(self.backup_file)
            print("🗑️  Backup file removed")
        except:
            pass

    def process_markdown_file(self, md_file):
        """Process a single markdown file"""
        try:
            with open(md_file, 'r', encoding='utf-8') as f:
                original_content = f.read()
        except Exception as e:
            return {
                'file': md_file,
                'status': 'error',
                'message': f"Error reading file: {e}"
            }

        # Find all imgur links
        imgur_links = self.find_imgur_links(original_content)

        if not imgur_links:
            return {
                'file': md_file,
                'status': 'skipped',
                'message': 'No imgur links found'
            }

        # Get the directory of the markdown file
        md_dir = os.path.dirname(md_file)

        downloaded_images = []
        updated_content = original_content
        download_tasks = []

        # Prepare download tasks
        for url in imgur_links:
            parsed = urlparse(self.fix_url(url))
            filename = os.path.basename(parsed.path)
            save_path = os.path.join(md_dir, filename)

            if not os.path.exists(save_path):
                download_tasks.append((url, save_path, filename))
            else:
                # Update link even if file exists - just use the filename
                updated_content = updated_content.replace(url, filename)

        # Download images in parallel
        downloaded = 0
        failed = 0

        if download_tasks:
            with ThreadPoolExecutor(max_workers=self.max_workers) as executor:
                future_to_task = {
                    executor.submit(self.download_image, url, save_path): (url, save_path, filename)
                    for url, save_path, filename in download_tasks
                }

                for future in as_completed(future_to_task):
                    url, save_path, filename = future_to_task[future]
                    success, error = future.result()

                    if success:
                        downloaded += 1
                        downloaded_images.append(filename)
                        # Replace imgur URL with just the filename
                        updated_content = updated_content.replace(url, filename)
                    else:
                        failed += 1

        # Update the markdown file
        if updated_content != original_content:
            try:
                with open(md_file, 'w', encoding='utf-8') as f:
                    f.write(updated_content)

                # Store backup data
                self.backup_data['files'][md_file] = {
                    'original_content': original_content,
                    'downloaded_images': downloaded_images
                }

            except Exception as e:
                return {
                    'file': md_file,
                    'status': 'error',
                    'message': f"Error updating file: {e}"
                }

        return {
            'file': md_file,
            'status': 'success',
            'total_links': len(imgur_links),
            'downloaded': downloaded,
            'failed': failed,
            'skipped': len(imgur_links) - downloaded - failed
        }

    def scan_directory(self):
        """Recursively scan directory for markdown files"""
        root_path = Path(self.root_dir)
        md_files = list(root_path.rglob('*.md'))

        if not md_files:
            print("❌ No markdown files found!")
            return

        print(f"🔍 Found {len(md_files)} markdown file(s)")
        print(f"⚙️  Using {self.max_workers} parallel workers\n")

        # Initialize backup data
        self.backup_data = {
            'timestamp': datetime.now().isoformat(),
            'root_dir': self.root_dir,
            'files': {}
        }

        results = {
            'success': 0,
            'skipped': 0,
            'errors': 0,
            'total_downloaded': 0,
            'total_failed': 0
        }

        # Process files with progress bar
        with tqdm(total=len(md_files), desc="Processing files", unit="file") as pbar:
            for md_file in md_files:
                result = self.process_markdown_file(str(md_file))

                if result['status'] == 'success':
                    results['success'] += 1
                    results['total_downloaded'] += result['downloaded']
                    results['total_failed'] += result['failed']
                elif result['status'] == 'skipped':
                    results['skipped'] += 1
                elif result['status'] == 'error':
                    results['errors'] += 1
                    tqdm.write(f"❌ {result['message']}")

                pbar.update(1)

        # Save backup
        if self.backup_data['files']:
            self.save_backup()

        # Print summary
        print("\n" + "="*50)
        print("📊 SUMMARY")
        print("="*50)
        print(f"✅ Successfully processed: {results['success']}")
        print(f"⏭️  Skipped (no links): {results['skipped']}")
        print(f"❌ Errors: {results['errors']}")
        print(f"⬇️  Total images downloaded: {results['total_downloaded']}")
        if results['total_failed'] > 0:
            print(f"⚠️  Failed downloads: {results['total_failed']}")
        print("="*50)

        if self.backup_data['files']:
            print(f"\n💾 Backup saved to: {self.backup_file}")
            print(f"   Use --revert to undo changes")

def main():
    parser = argparse.ArgumentParser(
        description='Download imgur images from markdown files and replace links with local filenames',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  %(prog)s                           # Scan current directory
  %(prog)s /path/to/posts            # Scan specific directory
  %(prog)s -w 10                     # Use 10 parallel workers
  %(prog)s --revert                  # Revert all changes
  %(prog)s /path/to/posts --revert   # Revert changes in specific directory

What it does:
  - Finds imgur links (including broken ttps:// links)
  - Downloads images to the same directory as the .md file
  - Replaces "https://i.imgur.com/abc123.png" with just "abc123.png"
  - Creates backup for easy reverting
        '''
    )

    parser.add_argument(
        'directory',
        nargs='?',
        default='.',
        help='Directory to scan (default: current directory)'
    )

    parser.add_argument(
        '-w', '--workers',
        type=int,
        default=5,
        help='Number of parallel download workers (default: 5)'
    )

    parser.add_argument(
        '--revert',
        action='store_true',
        help='Revert all changes using backup file'
    )

    args = parser.parse_args()

    # Validate directory
    if not os.path.exists(args.directory):
        print(f"❌ Directory not found: {args.directory}")
        return 1

    downloader = ImgurDownloader(
        root_dir=os.path.abspath(args.directory),
        max_workers=args.workers,
        revert=args.revert
    )

    if args.revert:
        downloader.revert_changes()
    else:
        print(f"🚀 Starting imgur image downloader")
        print(f"📂 Scanning directory: {os.path.abspath(args.directory)}\n")
        downloader.scan_directory()
        print("\n✅ Processing complete!")

    return 0

if __name__ == "__main__":
    exit(main())
