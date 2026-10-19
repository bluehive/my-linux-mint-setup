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

## 注意

- `config/` フォルダ（`packages.list`、`mise.toml`、`repos.txt`）は、このリポジトリに含めていません。必要なら自分で用意してください。無ければ、その手順は飛ばされます。
- `sudo` を使います。中身を確認してから実行してください。
