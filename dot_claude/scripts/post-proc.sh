#!/usr/bin/bash
script="$(pwd)/post-proc.sh"
if [ -f "$script" ]; then
  bash "$script"
else
  powershell.exe -Command "(New-Object Media.SoundPlayer 'C:\Windows\media\Ring06.wav').PlaySync()"
fi
