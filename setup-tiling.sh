#!/usr/bin/env bash
# setup-tiling.sh — Linux Mint 22.3 にタイル型ウィンドウマネージャ i3 を追加
#   i3 / i3status / dmenu / i3lock / alacritty / feh / rofi + 日本語環境（IBus / Mozc）
#   既定のセッション（MATE / Xfce / Cinnamon）は変えません。ログイン画面で i3 を選びます。
# 使い方: bash setup-tiling.sh
set -euo pipefail

log() { printf '\n==> %s\n' "$*"; }

if [ "$(id -u)" -eq 0 ]; then
  echo "root ではなく一般ユーザーで実行してください（必要な所で sudo を使います）。" >&2
  exit 1
fi

log "パッケージ一覧を更新"
sudo apt-get update

log "基本ツール"
sudo apt-get install -y curl wget git ca-certificates

log "日本語環境（ロケール・フォント・入力メソッド）"
sudo apt-get install -y \
  language-pack-ja language-pack-gnome-ja \
  fonts-noto-cjk fonts-noto-cjk-extra fonts-ipafont \
  ibus ibus-mozc mozc-utils-gui im-config
sudo locale-gen ja_JP.UTF-8
im-config -n ibus

log "i3 一式（dmenu は suckless-tools に含まれます）"
sudo apt-get install -y i3 i3-wm i3status i3lock suckless-tools feh rofi

log "端末: alacritty（無ければ xterm）"
if apt-cache show alacritty >/dev/null 2>&1; then
  sudo apt-get install -y alacritty
  TERM_CMD=alacritty
else
  sudo apt-get install -y xterm
  TERM_CMD=xterm
fi

log "i3 の設定（~/.config/i3/config）"
I3DIR="$HOME/.config/i3"
I3CONF="$I3DIR/config"
mkdir -p "$I3DIR"
if [ ! -f "$I3CONF" ]; then
  cp /etc/i3/config "$I3CONF"
  # 既定の Mod+Return（i3-sensible-terminal）を選んだ端末に置き換える
  sed -i "s|^bindsym \$mod+Return exec .*|bindsym \$mod+Return exec $TERM_CMD|" "$I3CONF"
fi
if ! grep -q '# my-linux-mint-setup' "$I3CONF"; then
  cat >> "$I3CONF" <<'I3'

# my-linux-mint-setup
exec --no-startup-id ibus-daemon -drx
bindsym $mod+Shift+d exec --no-startup-id rofi -show drun
I3
fi

cat <<'MSG'

完了しました。既定のセッションは変えていません。
1. 一度ログアウトします。
2. ログイン画面（LightDM）でユーザー名の横／右上のセッションアイコンから「i3」を選び、ログインします。
3. 主なキー（Mod は既定で Alt）:
   Mod+Enter 端末 / Mod+d dmenu / Mod+Shift+d rofi / Mod+Shift+q 窓を閉じる
   Mod+1〜0 ワークスペース切替 / Mod+Shift+e i3 を終了（ログアウト）
4. 元に戻すには、ログイン画面で MATE や Xfce のセッションを選び直します。
MSG
