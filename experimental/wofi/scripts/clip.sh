#!/bin/bash

if ! command -v cliphist &> /dev/null; then
    notify-send "Clipboard Error" "cliphist is not installed. Please install it."
    exit 1
fi

if [[ $(cliphist list | wc -l) -eq 0 ]]; then
	notify-send "Clipboard" "History is empty."
	exit 0
fi

cliphist list | wofi --show dmenu \
                     --prompt "Clipboard History" \
                     --width=600 \
                     --height=400 \
                     --style=$HOME/.config/wofi/style.css \
		     | cliphist decode | wl-copy
