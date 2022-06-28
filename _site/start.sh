#!/bin/bash

# OS: Ubuntu 20.04 LTS
# $ sudo apt-get update
# $ sudo apt -y install make build-essential ruby ruby-devr
# $ vi ~/.bashrc
# export GEM_HOME=$HOME/gems
# export PATH=$HOME/gems/bin:$PATH
# $ source ~/.bashrc
# $ gem install jekyll bundler

if [[ $1 = "watch" ]]; then
	jekyll serve --watch
elif [[ $1 = "inc" ]]; then
	jekyll serve --incremental
else
	jekyll serve
fi
