$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

# Solo se filtra stdout. Flutter conserva la entrada de la consola y stderr.
$ruidoAndroid = '^\s*[VDI]/(?:EGL_emulation|InsetsController|InsetsSourceConsumer|ImeTracker|InputMethodManager(?:_LC)?|ProfileInstaller|SurfaceView(?:@[^ (]+)?|VRI\[[^\]]+\](?:@[^ (]+)?)(?:\s*\(\s*\d+\s*\))?\s*:'
& flutter.bat run @args | Where-Object { $_ -cnotmatch $ruidoAndroid }
exit $LASTEXITCODE
