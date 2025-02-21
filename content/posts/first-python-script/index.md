---
title: "My First Python Script"
date: 2024-06-27
draft: false
description: "Convert Forum Psts With Python"
tags: ["Python", "Script", "Scripting", "Programming", Linux"]
---
### What prompted me ?

Well, as I was porting all relevant forum posts to this site in **markdown**, I needed a better way to do so. Someone on **Mastodon** gave me the idea of writing a python script that does it for me. So I went on learning spree. Not really...

I gotta be honest with you guys, I had to use **ChatGPT**. Doing it by watching **YouTube** videos, or by searching the net would have taken me ages. So I went to the thing that does things much faster. And before you say it, I am well aware that we can't rely on it 100%, coz it's very inaccurate and licensing is an issue. So I was careful. Anyway, I will post what I have learned so far, maybe it can be of use to you.

### The code

Before we begin, I need to mention that code is not perfect since it's my very first script. But it did the trick for me. It could still use some tweaking, so if you know how I can make it better, please feel free to let me know how. Use any of my socials to contact me.

Issue with script is, formatting, as in result **Markdown** is not well formatted, with a huge amout of dead space, underscores all over and embedded videos are always put at the end of posts. Not to mention that `code` snippets are not labeled as Bash or Yaml etc..

With that being said, let's begin shall we ?

Before going through the code, make sure you have the following packages installed on your system. Also forum posts need to be accessible withou an account otherwise script will fail miserably.

```Bash
sudo pacman -S python python-beautifulsoup4 python-requests python-markdownify
```

Now here's the code, then I will explain...

```Python
import requests
from bs4 import BeautifulSoup
import markdownify
import os

def convert_to_markdown(url):
    response = requests.get(url)
    soup = BeautifulSoup(response.content, 'html.parser')

    # Extract the main content of the post
    post_content = soup.find('div', {'class': 'post_body'})

    if not post_content:
        return "Could not find the post content."

    # Convert HTML to Markdown, including embedded YouTube videos
    markdown = markdownify.markdownify(str(post_content), heading_style="ATX")

    # Process embedded YouTube videos
    for iframe in post_content.find_all('iframe'):
        src = iframe.get('src')
        if 'youtube.com' in src or 'youtu.be' in src:
            video_id = src.split('/')[-1].split('?')[0]
            youtube_markdown = f"\n[![YouTube Video](https://img.youtube.com/vi/{video_id}/0.jpg)]({src})\n"
            markdown += youtube_markdown

    return markdown

# URLs of the forum posts
urls = [
    "https://forum.xerolinux.xyz/thread-131.html"
]

# Create an output directory if it doesn't exist
output_dir = 'markdown_posts'
if not os.path.exists(output_dir):
    os.makedirs(output_dir)

# Convert each URL to Markdown and save to file
for url in urls:
    markdown_content = convert_to_markdown(url)

    # Extract thread ID from URL to use as filename
    thread_id = url.split('-')[-1].replace('.html', '')
    output_file = os.path.join(output_dir, f"post_{thread_id}.md")

    with open(output_file, 'w') as file:
        file.write(markdown_content)

    print(f"Saved Markdown for {url} to {output_file}")
```

### Basic Explanation

* **Import Libraries:** We use requests to fetch the webpage content and BeautifulSoup to parse the HTML. The markdownify library is used to convert HTML to Markdown.
* **Extract Content:** The script extracts the main content of the post by looking for the div with class `post_body`.
* **Convert to Markdown:** The script uses the markdownify library to convert the HTML content to Markdown and processes embedded YouTube videos.
* **Save to File:** The script saves each converted post to its own Markdown file. The filenames are derived from the thread IDs in the URLs.
* **Output Directory:** The script creates an `output_dir` directory if it doesn't exist and saves the Markdown files there.

### How to Run the Script

* Save the Script: Copy the script into a file named `forum_to_markdown.py`.
* Make sure you mark script as executable via `chmod +x forum_to_markdown.py`
* Run the Script: Execute the script by running the following command in your terminal:

```Bash
python forum_to_markdown.py
```

This script will output each post to its own Markdown file in the `markdown_posts` directory.

That's it for now. Do let me know what you think.
