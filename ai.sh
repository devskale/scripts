#!/bin/zsh

# Get the text after "ai"
#text_after_ai=$(echo "$*" | cut -d 'ai' -f2)
text_after_ai=$(echo "$*")

# Echo the extracted text
echo "$text_after_ai" 