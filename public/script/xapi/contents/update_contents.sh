#!/usr/bin/env bash

scripts_url="https://github.com/XeroLinuxDev/xero-scripts.git"
binary_url="https://github.com/XeroLinuxDev/xero-cli.git"

p_info () {
  echo -e "\033[1;30m[\033[1;32mi\033[1;30m] ::\033[1;36m $1\033[0m"
}

wrong_directory () {
  echo "Wrong directory to run script in! Please run it in 'contents' directory!"
  exit 1
}

pwd_out="$(pwd)"
[[ "$(basename $pwd_out)" == "contents" ]] || wrong_directory

p_info "Preparing..."

rm -rf ./.tmp > /dev/null 2>&1
mkdir ./.tmp

p_info "Updating scripts..."

rm -rf ./scripts > /dev/null 2>&1
mkdir ./scripts

cd ./.tmp
git clone $scripts_url sc
cd ..

mv ./.tmp/sc/scripts/*.sh ./scripts

p_info "Updating binary..."

rm ./xero-cli > /dev/null 2>&1

cd ./.tmp
git clone $binary_url bc
cd bc
cargo build --release
cd ..
cd ..

mv ./.tmp/bc/target/release/xero-cli .

p_info "Cleaning up..."

rm -rf ./.tmp

p_info "Done!"
