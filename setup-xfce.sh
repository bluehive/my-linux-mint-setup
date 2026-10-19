#!/usr/bin/env bash
# setup-xfce.sh — Linux Mint Xfce 版の初期セットアップ
#   日本語環境 / ブラウザ2点（Firefox・Google Chrome）/ オフィス（LibreOffice）
# 使い方: bash setup-xfce.sh
set -euo pipefail

log() { printf '\n==> %s\n' "$*"; }

if [ "$(id -u)" -eq 0 ]; then
  echo "root ではなく一般ユーザーで実行してください（必要な所で sudo を使います）。" >&2
  exit 1
fi

if [ "${XDG_CURRENT_DESKTOP:-}" != "" ] && ! echo "$XDG_CURRENT_DESKTOP" | grep -qi xfce; then
  echo "注意: 現在のデスクトップは $XDG_CURRENT_DESKTOP です（Xfce 版向けのスクリプトです）。続行します。"
fi

log "パッケージ一覧を更新"
sudo apt-get update
sudo apt-get upgrade -y

log "基本ツール"
sudo apt-get install -y curl wget gpg ca-certificates apt-transport-https git

log "日本語環境（ロケール・フォント・入力メソッド）"
sudo apt-get install -y \
  language-pack-ja language-pack-gnome-ja \
  fonts-noto-cjk fonts-noto-cjk-extra fonts-ipafont \
  ibus ibus-mozc mozc-utils-gui im-config \
  manpages-ja
sudo locale-gen ja_JP.UTF-8
sudo update-locale LANG=ja_JP.UTF-8
im-config -n ibus
# Xfce のログイン時に ibus を自動起動
mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/ibus-daemon.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=IBus
Exec=ibus-daemon -drx
X-GNOME-Autostart-enabled=true
DESKTOP

log "ブラウザ1: Firefox（日本語化）"
sudo apt-get install -y firefox firefox-locale-ja

log "ブラウザ2: Google Chrome"
if ! command -v google-chrome >/dev/null 2>&1; then
  tmp="$(mktemp -d)"
  wget -qO "$tmp/chrome.deb" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  sudo apt-get install -y "$tmp/chrome.deb"
  rm -rf "$tmp"
fi

log "オフィス: LibreOffice（日本語化）"
sudo apt-get install -y libreoffice libreoffice-l10n-ja libreoffice-help-ja

log "後片付け"
sudo apt-get autoremove -y

cat <<'MSG'

完了しました。日本語ロケールと入力メソッドを有効にするため、一度ログアウト（または再起動）してください。
ログイン後、Ctrl+Space（または 半角/全角）で日本語入力に切り替わります。
MSG
