#!/usr/bin/bash
set -e

marisa() {
  local po=(powershell.exe -NoProfile -Command)
  local atp="C:\tools\aquestalkplayer\AquesTalkPlayer.exe"
  "${po[@]}" "\$p=Start-Process $atp -ArgumentList /P,まりさ,/T,'$1' -PassThru; \$p.WaitForExit()"
}

media() {
  local po=(powershell.exe -NoProfile -Command)
  local wav="C:\\Windows\\media\\$1.wav"
  "${po[@]}" "(New-Object Media.SoundPlayer '$wav').PlaySync()"
}

case "$1" in
  marisa)
    marisa "$2";;
  media)
    media "$2";;
esac
