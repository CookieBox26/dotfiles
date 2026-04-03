$path = $args[0] -replace '^saku:', ''
Start-Process 'C:\Program Files (x86)\sakura\sakura.exe' -ArgumentList $path
