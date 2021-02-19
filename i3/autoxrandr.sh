#!/usr/bin/env bash
#
# Script to select the monitor automatically.
# It works through i3wm and xrandr.
#
# Explanation:
# - If external monitor is plugged on, it will turn the LCD screen off.
# - To change the settings during an Xsession I use the tool lxrandr.

#for output in $(xrandr | grep '\Wconnected' | awk '{ print $1 }'); do
#  if [[ $output =~ ^eDP.*$ ]]; then
#    lvds=$output
#  fi
#donr

#for output in $(xrandr | grep '\Wconnected' | awk '{ print $1 }'); do
#  if [[ ! $output =~ ^eDP.*$ ]]; then
#    xrandr --output $lvds --off --output $output --primary --auto
#    feh --bg-fill ~/.wallpaper/firewatch-blue.png
#  else
#    xrandr --output $lvds --auto
#    feh --bg-fill ~/.wallpaper/firewatch-blue.png
#  fi
#done

autorandr --change