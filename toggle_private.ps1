<#
toggle_private.ps1 - включение/выключение приватной сборки (ОМНИ доступ + квадрантная сетка)

Использование:
  .\toggle_private.ps1 on   - включить приватный код
  .\toggle_private.ps1 off  - выключить (оригинальный код)
  .\toggle_private.ps1      - переключить по текущему состоянию

Добавление нового приватного кода:
  - Обычные файлы (не трогают ядро): положи в modular_solaris\_omni_access\code\
    и добавь #include в modular_solaris\_omni_access\__private.dme -
    они автоматически переключаются флагом OMNI_ACCESS.
  - Переопределение файла ядра: приватная копия в _omni_access\code\overrides\,
    в shiptest.dme блок #ifndef ФЛАГ / #else, #define ФЛАГ в code\_compile_options.dm,
    и добавь строку в список $Flags ниже.

После переключения пересобрать проект (BUILD.cmd / dm.exe shiptest.dme).
#>

param([string]$Action)

$ErrorActionPreference = 'Stop'

$root         = $PSScriptRoot
$submoduleDir = Join-Path $root 'modular_solaris\_omni_access'
$utf8NoBom    = New-Object System.Text.UTF8Encoding($false)

# Список переключаемых флагов: имя + файл + префикс комментария.
# При добавлении нового приватного кода допиши сюда строку.
# ВАЖНО: флаг для свопа инклудов обязан быть определён в code\_compile_options.dm
# (включается рано, до строк свопа в shiptest.dme).
# USE_QUADRANT_GRID - рантайм-переключатель (config\game_options.txt), работает
# на живом сервере без перекомпиляции; скрипт дублирует его для локальной разработки.
$Flags = @(
	@{ Name = 'SOLARIS_GRID';      File = 'code\_compile_options.dm';         Comment = '//' },
	@{ Name = 'OMNI_ACCESS';       File = 'modular_solaris\modular_solaris.dme'; Comment = '//' },
	@{ Name = 'USE_QUADRANT_GRID'; File = 'config\game_options.txt';          Comment = '#' }
)

function Set-Flag([string]$path, [string]$flag, [bool]$enable, [string]$comment) {
	$text = [System.IO.File]::ReadAllText($path)
	$esc = [regex]::Escape($comment)
	$prefix = '(?:#define\s+)?'
	if ($enable) {
		$pattern = '(?m)^(\s*)' + $esc + '\s*(' + $prefix + $flag + '\b[^\r\n]*)(\r?\n)'
		$newText = [regex]::Replace($text, $pattern, '$1$2$3')
		$pattern = '(?m)^(' + $prefix + $flag + '\b)([ \t]+)(\S+)(\r?\n)'
		$newText = [regex]::Replace($newText, $pattern, '$1${2}1$4')
	} else {
		$pattern = '(?m)^(' + $prefix + $flag + '\b[^\r\n]*)(\r?\n)'
		$newText = [regex]::Replace($text, $pattern, $comment + '$1$2')
	}
	if ($newText -ne $text) {
		[System.IO.File]::WriteAllText($path, $newText, $utf8NoBom)
		$state = if ($enable) { 'включён' } else { 'выключен' }
		Write-Host "  $flag : $state ($([System.IO.Path]::GetFileName($path)))" -ForegroundColor Green
	} else {
		Write-Host "  $flag : строка не найдена в $path" -ForegroundColor Yellow
	}
}

function Get-FlagOn([string]$path, [string]$flag) {
	$text = [System.IO.File]::ReadAllText($path)
	return [bool]($text -match '(?m)^#define\s+' + $flag + '\b')
}

$anyOn = Get-FlagOn (Join-Path $root $Flags[0].File) $Flags[0].Name

if (!$Action) {
	$Action = if ($anyOn) { 'off' } else { 'on' }
}

Write-Host 'Приватная сборка:' -NoNewline
if ($Action -eq 'on') {
	Write-Host ' ВКЛЮЧЕНИЕ' -ForegroundColor Cyan
	if (!(Test-Path (Join-Path $submoduleDir '.git'))) {
		Write-Host "  ВНИМАНИЕ: папка $submoduleDir не инициализирована." -ForegroundColor Yellow
		Write-Host '  Выполни: git submodule update --init modular_solaris/_omni_access' -ForegroundColor Yellow
	}
	foreach ($f in $Flags) { Set-Flag (Join-Path $root $f.File) $f.Name $true $f.Comment }
} else {
	Write-Host ' ВЫКЛЮЧЕНИЕ' -ForegroundColor Cyan
	foreach ($f in $Flags) { Set-Flag (Join-Path $root $f.File) $f.Name $false $f.Comment }
}

Write-Host 'Готово. Пересобери проект (BUILD.cmd).'