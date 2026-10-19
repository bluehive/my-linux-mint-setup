# my-linux-mint-setup

新しい PC で、Linux Mint（または WSL2）の開発環境を作り直すための個人用スクリプトです。

## 使い方

```sh
bash setup.sh mint   # Linux Mint（既定）
bash setup.sh wsl2   # WSL2（GUI アプリは入れない）
```

## やること

1. 基本ツール（git、curl、build-essential など）
2. `config/packages.list` があれば、apt パッケージを復元
3. 日本語環境（ibus-mozc、Noto CJK フォント）
4. デスクトップアプリ（Firefox、LibreOffice、Okular、Calibre、Thunderbird、Microsoft Edge）
5. Racket / DrRacket
6. Emacs 設定のクローンと配置
7. mise（ランタイム管理）
8. `config/repos.txt` があれば、`~/my-project` へリポジトリをクローン

## Xfce 版（setup-xfce.sh）

Linux Mint Xfce 版を入れた直後に使う、軽めのセットアップです。

```sh
bash setup-xfce.sh
```

### wget で取ってきて実行する

クローンしなくても、Mint の端末で次を順に実行すれば動きます（Mint には wget が最初から入っています）。

```sh
cd ~
wget -O setup-xfce.sh https://raw.githubusercontent.com/bluehive/my-linux-mint-setup/main/setup-xfce.sh
less setup-xfce.sh        # 中身を確認（q で閉じる）
bash setup-xfce.sh
```

途中で sudo のパスワードを聞かれます。終わったら一度ログアウトしてください。

日本語環境（ja_JP.UTF-8 ロケール、Noto CJK と IPA フォント、IBus と Mozc）、ブラウザ2つ（Firefox と Google Chrome）、LibreOffice（日本語化）を入れます。終わったら一度ログアウトしてください。

## Windows 11 でインストール USB を作る（windows/）

Linux Mint 安定版（22.3）の MATE 版と Xfce 版の ISO をダウンロードし、SHA256 を確認してから、[Ventoy](https://www.ventoy.net/) で1本の USB メモリに両方入れます。起動時のメニューでどちらかを選べます。

準備（初回のみ、PowerShell で）:

```powershell
winget install jdx.mise
```

実行（`windows` フォルダで）:

```powershell
mise install          # gsudo（管理者実行用）を入れる
mise run usb-all      # ダウンロード → 確認 → USB 作成
```

- 片方だけ入れるときは、先に `$env:MINT_EDITION = "mate"`（または `"xfce"`）を設定します。
- 個別のタスクもあります: `mise run iso-download`、`mise run iso-verify`、`mise run usb-write`。
- USB の番号を選び、`ERASE` と入力したときだけ書き込みます。**その USB の中身はすべて消えます。**
- USB メモリは 8GB 以上（両方入れるなら 16GB 以上）を使ってください。

## 注意

- `config/` フォルダ（`packages.list`、`mise.toml`、`repos.txt`）は、このリポジトリに含めていません。必要なら自分で用意してください。無ければ、その手順は飛ばされます。
- `sudo` を使います。中身を確認してから実行してください。
