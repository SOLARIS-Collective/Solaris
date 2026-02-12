@echo off
node --experimental-modules "%~dp0\..\tools\build\build.js" --wait-on-error clean-all %*
