<#
make-mint-usb.ps1 — Windows 11 で Linux Mint（安定版）のインストール USB を作る
  対象: MATE 版 / Xfce 版（両方を1本の USB に入れられます）
  方式: Ventoy を USB に入れ、ISO ファイルをコピーする（起動時にメニューで選択）

使い方（mise から呼ぶのが基本。README 参照）:
  powershell -ExecutionPolicy Bypass -File make-mint-usb.ps1 -Step download
  powershell -ExecutionPolicy Bypass -File make-mint-usb.ps1 -Step verify
  powershell -ExecutionPolicy Bypass -File make-mint-usb.ps1 -Step usb      # 管理者で実行
  -Edition mate | xfce | both（既定 both）
#>
param(
  [ValidateSet('download','verify','usb','all')] [string]$Step = 'all',
  [ValidateSet('mate','xfce','both')] [string]$Edition = 'both',
  [string]$Version = '22.3',
  [string]$Mirror  = 'https://mirrors.edge.kernel.org/linuxmint/stable',
  [string]$WorkDir = (Join-Path $PSScriptRoot 'iso')
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Log($m) { Write-Host "`n==> $m" -ForegroundColor Cyan }
function IsoNames {
  $eds = if ($Edition -eq 'both') { @('mate','xfce') } else { @($Edition) }
  $eds | ForEach-Object { "linuxmint-$Version-$_-64bit.iso" }
}

# Windows PowerShell 5.1 does not throw on native-command failures.
function Invoke-Curl {
  & curl.exe @args
  if ($LASTEXITCODE -ne 0) { throw "curl failed (exit $LASTEXITCODE)" }
}

function Step-Download {
  New-Item -ItemType Directory -Force -Path $WorkDir | Out-Null
  Log "チェックサム一覧を取得"
  Invoke-Curl -fL -o (Join-Path $WorkDir 'sha256sum.txt') "$Mirror/$Version/sha256sum.txt"
  foreach ($iso in IsoNames) {
    Log "ダウンロード: $iso（中断しても続きから再開します）"
    Invoke-Curl -fL -C - -o (Join-Path $WorkDir $iso) "$Mirror/$Version/$iso"
  }
}

function Step-Verify {
  $sums = Get-Content (Join-Path $WorkDir 'sha256sum.txt')
  foreach ($iso in IsoNames) {
    $pattern = '^([0-9a-fA-F]{64})\s+\*?' + [regex]::Escape($iso) + '$'
    $lines = @($sums | Where-Object { $_ -match $pattern })
    if ($lines.Count -ne 1) { throw "チェックサムは ISO ごとに1行必要です: $iso" }
    $line = $lines[0]
    if (-not $line) { throw "sha256sum.txt に $iso がありません" }
    $expected = ($line -split '\s+')[0].ToLower()
    Log "SHA256 を確認: $iso"
    $actual = (Get-FileHash -Algorithm SHA256 (Join-Path $WorkDir $iso)).Hash.ToLower()
    if ($actual -ne $expected) { throw "不一致です。ISO を消して再ダウンロードしてください: $iso" }
    Write-Host "OK $actual"
  }
}

function Get-Ventoy {
  $dir = Join-Path $PSScriptRoot 'ventoy'
  $exe = Get-ChildItem $dir -Recurse -Filter Ventoy2Disk.exe -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($exe) { return $exe.FullName }
  Log "Ventoy（最新版）をダウンロード"
  $rel = Invoke-RestMethod https://api.github.com/repos/ventoy/Ventoy/releases/latest
  $asset = $rel.assets | Where-Object { $_.name -like 'ventoy-*-windows.zip' } | Select-Object -First 1
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $zip = Join-Path $dir $asset.name
  Invoke-Curl -fL -o $zip $asset.browser_download_url
  Expand-Archive -Force $zip $dir
  (Get-ChildItem $dir -Recurse -Filter Ventoy2Disk.exe | Select-Object -First 1).FullName
}

function Step-Usb {
  $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  if (-not $admin) { throw "USB への書き込みは管理者の PowerShell で実行してください" }

  Step-Verify  # usb 単独実行でも、消去前に ISO を検証する

  $disks = Get-Disk | Where-Object BusType -eq 'USB'
  if (-not $disks) { throw "USB メモリが見つかりません" }
  Log "USB ディスク一覧"
  $disks | Format-Table Number, FriendlyName, @{n='SizeGB';e={[math]::Round($_.Size/1GB,1)}} -AutoSize | Out-Host

  $num = Read-Host "書き込む USB の番号（Number）"
  $disk = $disks | Where-Object Number -eq ([int]$num)
  if (-not $disk) { throw "USB ディスクの番号ではありません: $num" }
  Write-Host "`n注意: ディスク $num（$($disk.FriendlyName)）の中身はすべて消えます。" -ForegroundColor Yellow
  if ((Read-Host "よければ ERASE と入力") -cne 'ERASE') { Write-Host "中止しました。"; return }

  $vexe = Get-Ventoy
  Log "Ventoy を USB に入れる（GPT）"
  $vdir = Split-Path $vexe
  Remove-Item (Join-Path $vdir 'cli_done.txt') -ErrorAction SilentlyContinue
  Start-Process -FilePath $vexe -ArgumentList "VTOYCLI /I /PhyDrive:$num /GPT" -WorkingDirectory $vdir -Wait
  $result = Get-Content (Join-Path $vdir 'cli_done.txt') -ErrorAction SilentlyContinue
  if ($result -ne '0') { throw "Ventoy の書き込みに失敗しました（$vdir\cli_log.txt を確認）" }

  Start-Sleep 5
  $vol = Get-Partition -DiskNumber ([int]$num) | Get-Volume |
    Where-Object FileSystemLabel -eq 'Ventoy' | Select-Object -First 1
  if (-not $vol.DriveLetter) { throw "Ventoy ドライブが見つかりません。USB を挿し直して ISO を手でコピーしてください" }
  foreach ($iso in IsoNames) {
    Log "コピー: $iso → $($vol.DriveLetter):\"
    Copy-Item (Join-Path $WorkDir $iso) "$($vol.DriveLetter):\" -Force
  }
  Log "完了。USB から起動すると、Ventoy のメニューで MATE 版 / Xfce 版を選べます。"
}

switch ($Step) {
  'download' { Step-Download }
  'verify'   { Step-Verify }
  'usb'      { Step-Usb }
  'all'      { Step-Download; Step-Usb }
}
