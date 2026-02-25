#!/usr/bin/bash
po=(powershell.exe -NoProfile -Command)
"${po[@]}" "Start-Process 'obsidian://open?vault=${1}&file=${2}'"
