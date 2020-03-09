#!/bin/bash

if [[ $1 = "watch" ]]; then
	jekyll serve --watch
elif [[ $1 = "inc" ]]; then
	jekyll serve --incremental
else
	jekyll serve
fi
