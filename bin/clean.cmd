@echo off
node "%~dp0\..\tools\build\build.js" --wait-on-error clean-all %*
