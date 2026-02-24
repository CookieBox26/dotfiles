#!/usr/bin/bash
po=(powershell.exe -NoProfile -Command)
"${po[@]}" "Start-Process 'obsidian://open?vault=Mercury&file=References%2Fask'"
