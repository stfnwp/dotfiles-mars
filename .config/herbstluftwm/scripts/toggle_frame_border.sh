#!/usr/bin/env bash
current_width=$(herbstclient get frame_border_width)
target_width=0

[ $current_width -eq 0 ] && target_width=4

herbstclient set frame_border_width $target_width
