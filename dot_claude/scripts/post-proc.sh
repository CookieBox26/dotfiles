#!/usr/bin/bash
script="$(pwd)/post-proc.sh"
if [ -f "$script" ]; then
  bash "$script"
  exit 0
fi
script="$(pwd)/.claude/post-proc.sh"
if [ -f "$script" ]; then
  bash "$script"
  exit 0
fi
powershell.exe -Command "(New-Object Media.SoundPlayer 'C:\Windows\media\Ring06.wav').PlaySync()"
