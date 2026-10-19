#!/usr/bin/env bash
# ============================================================
# 環境構築スクリプト (新PCで restore.sh の後に実行)
# apt / mise / git クローンで開発環境を再構築する
# 使い方: bash setup.sh [--target mint|wsl2]
# ============================================================
set -euo pipefail

TARGET="${1:-mint}"   # mint | wsl2
[ "$TARGET" != "mint" ] && [ "$TARGET" != "wsl2" ] && { echo "target は mint か wsl2"; exit 1; }
log() { echo "[setup] $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"

# ============================================================
# 0. 基本ツール
# ============================================================
log "== 0. 基本ツール =="
sudo apt-get update -y
sudo apt-get install -y git curl wget build-essential ca-certificates gnupg unzip xz-utils

# ============================================================
# 1. apt 履歴ベースのパッケージ復元
# ============================================================
if [ -f "$CONFIG_DIR/packages.list" ]; then
  log "== 1. apt履歴パッケージの復元 ($(wc -l < "$CONFIG_DIR/packages.list") 件) =="
  sudo apt-get install -y $(cat "$CONFIG_DIR/packages.list" | tr '\n' ' ') || \
    log "  WARN: 一部パッケージのインストールに失敗(リポジトリ差異の可能性)"
fi

# ============================================================
# 2. 日本語環境
# ============================================================
log "== 2. 日本語環境 =="
sudo apt-get install -y ibus ibus-mozc fonts-noto-cjk mozc-utils-gui
# 入力メソッドを Mozc に設定
if [ "$TARGET" = "mint" ]; then
  im-config -n mozc 2>/dev/null || true
fi
log "  再ログイン後、Mozc が入力メソッドとして利用可能になります"

# ============================================================
# 3. ブラウザー / LibreOffice / ビュワー / メーラー
# ============================================================
log "== 3. デスクトップアプリ =="
# Firefox (apt) / LibreOffice / PDF / EPUB / Thunderbird
sudo apt-get install -y firefox firefox-locale-ja libreoffice libreoffice-l10n-ja \
                        hunspell-ja okular evince calibre thunderbird thunderbird-locale-ja || true

# Microsoft Edge (公式リポジトリ)
if [ "$TARGET" = "mint" ] && ! command -v microsoft-edge >/dev/null 2>&1; then
  log "  Microsoft Edge を導入"
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" \
    | sudo tee /etc/apt/sources.list.d/microsoft-edge.list >/dev/null
  sudo apt-get update -y
  sudo apt-get install -y microsoft-edge-stable || true
fi

# ============================================================
# 4. DrRacket / Racket
# ============================================================
log "== 4. Racket / DrRacket =="
sudo apt-get install -y racket || true
# mise で racket を管理している場合の整合
if command -v mise >/dev/null 2>&1 && [ -f "$CONFIG_DIR/mise.toml" ]; then
  log "  mise から racket を導入"
  mise install 2>/dev/null || true
fi

# ============================================================
# 5. Emacs 設定 (minimal-emacs + my-emacs-config)
# ============================================================
log "== 5. Emacs 設定 =="
# 前提: GitHub SSH 鍵が登録済みであること (private リポジトリ取得のため)
sudo apt-get install -y emacs || true
if [ ! -d "$HOME/.emacs.d" ]; then
  log "  minimal-emacs.d をクローン"
  gh repo clone bluehive/minimal-emacs.d "$HOME/.emacs.d" 2>/dev/null || \
    git clone https://github.com/bluehive/minimal-emacs.d.git "$HOME/.emacs.d" 2>/dev/null || \
    log "  WARN: minimal-emacs.d のクローン失敗"
fi
# 自分専用設定 (my-emacs-config) をクローンし、install.sh で symlink を張る
# 2026-08-04 改訂: tar からの pre/post-init 抽出は廃止（symlink 実体が
# リポジトリ側にあるため、新PCではリポジトリクローンが正）
if [ ! -d "$HOME/my-project/my-emacs-config" ]; then
  log "  my-emacs-config をクローン"
  mkdir -p "$HOME/my-project"
  gh repo clone bluehive/my-emacs-config "$HOME/my-project/my-emacs-config" 2>/dev/null || \
    git clone git@github.com:bluehive/my-emacs-config.git "$HOME/my-project/my-emacs-config" 2>/dev/null || \
    log "  WARN: my-emacs-config のクローン失敗"
fi
if [ -d "$HOME/my-project/my-emacs-config" ]; then
  (cd "$HOME/my-project/my-emacs-config" && bash install.sh) || \
    log "  WARN: install.sh の実行に失敗"
fi

# ============================================================
# 6. mise (ランタイム管理)
# ============================================================
log "== 6. mise =="
if ! command -v mise >/dev/null 2>&1; then
  curl https://mise.run | sh
  echo 'eval "$(~/.local/bin/mise activate bash)"' >> "$HOME/.bashrc"
fi
if [ -f "$CONFIG_DIR/mise.toml" ]; then
  mkdir -p "$HOME/.config/mise"
  cp "$CONFIG_DIR/mise.toml" "$HOME/.config/mise/config.toml"
  mise install 2>/dev/null || true
fi

# ============================================================
# 7. my-project リポジトリ (restore.sh で未取得の場合)
# ============================================================
log "== 7. my-project リポジトリ =="
if [ -f "$CONFIG_DIR/repos.txt" ]; then
  mkdir -p "$HOME/my-project"
  while IFS='|' read -r name url; do
    [ -z "$name" ] && continue
    if [ ! -d "$HOME/my-project/$name" ]; then
      log "  クローン: $name"
      git clone "$url" "$HOME/my-project/$name" 2>/dev/null || log "  WARN: $name 失敗"
    fi
  done < "$CONFIG_DIR/repos.txt"
fi

# ============================================================
# 8. WSL2 向け調整
# ============================================================
if [ "$TARGET" = "wsl2" ]; then
  log "== 8. WSL2 調整 =="
  # GUI アプリは WSLg 対応のみ (必要に応じて)
  log "  WSL2 モード: GUI アプリの導入を省略しました (WSLg で必要なら個別に導入)"
fi

log "セットアップ完了!"
log "次のステップ:"
log "  1. 再ログイン (日本語入力・mise 反映)"
log "  2. Emacs を起動して設定を確認"
log "  3. 必要に応じて .thunderbird / .gemini の復元を確認"
