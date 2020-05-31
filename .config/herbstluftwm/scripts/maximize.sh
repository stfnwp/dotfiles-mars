#!/usr/bin/env bash
set -e
# A simple script for window maximization and window switching.
# Running this the first time script will:
#
#  1. remember the current layout
#  2. squeeze all windows into one frame using the layout defined in the first
#     argument (defaulting to max layout).
#  3. and during that, keeping the window focus
#
# Running this script again will:
#
#  1. restore the original layout
#  2. (again keeping the then current window focus)
#
# If you call this script with "grid", then you obtain a window switcher,
# similar to that of Mac OS X.
mode=${1:-max} # just some valid layout algorithm name

border_width=$(herbstclient get_attr theme.border_width)
frame_gap=$(herbstclient get frame_gap)
window_gap=$(herbstclient get window_gap)

# use attrs if they already exist (to restore previous gap values)
herbstclient silent get_attr tags.focus.my_border_width && border_width=$(herbstclient get_attr tags.focus.my_border_width)
herbstclient silent get_attr tags.focus.my_frame_gap && frame_gap=$(herbstclient get_attr tags.focus.my_frame_gap)
herbstclient silent get_attr tags.focus.my_window_gap && window_gap=$(herbstclient get_attr tags.focus.my_window_gap)

# FIXME: for some unknown reason, remove_attr always fails
#        fix that in the hlwm core and remove the "try" afterwards
layout=$(herbstclient dump)
cmd=(
# remember which client is focused
substitute FOCUS clients.focus.winid chain
. lock
. or : and # if there is more than one frame, then don't restore, but maximize again!
           , compare tags.focus.frame_count = 1
           # if we have such a stored layout, then restore it, else maximize
           , silent substitute STR tags.focus.my_unmaximized_layout load STR
           # apply old gaps
           , set_attr theme.border_width $border_width
           , set frame_gap $frame_gap
           , set window_gap $window_gap
           # remove the stored layout
           , try remove_attr tags.focus.my_unmaximized_layout
           , try remove_attr tags.focus.my_border_width
           , try remove_attr tags.focus.my_frame_gap
           , try remove_attr tags.focus.my_window_gap
     : chain , new_attr string tags.focus.my_unmaximized_layout
             , new_attr int tags.focus.my_border_width
             , new_attr int tags.focus.my_frame_gap
             , new_attr int tags.focus.my_window_gap
             # remove any gaps (for gapless maximize)
             , set_attr theme.border_width 0
             , set frame_gap 0
             , set window_gap 0
             # save old widths in attrs (needed for restoring at next call)
             , set_attr tags.focus.my_border_width $border_width
             , set_attr tags.focus.my_frame_gap $frame_gap
             , set_attr tags.focus.my_window_gap $window_gap
             # save the current layout in the attribute
             , set_attr tags.focus.my_unmaximized_layout "$layout"
             # force all windows into a single frame in max layout
             , load "(clients $mode:0 )"
# both load commands accidentally change the window focus, so restore the
# window focus from before the "load" command
. jumpto FOCUS
. unlock
)
herbstclient "${cmd[@]}"
