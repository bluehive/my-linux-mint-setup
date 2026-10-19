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
3. Mint のみ：日本語環境（IBus / Mozc、Noto CJK フォント）
4. Mint のみ：デスクトップアプリ（Firefox、LibreOffice、Okular、Calibre、Thunderbird、Microsoft Edge）
5. Racket（Mint では DrRacket も含む）
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

Linux Mint 22.3（このスクリプトの既定バージョン）の MATE 版と Xfce 版の ISO をダウンロードし、SHA256 を確認してから、[Ventoy](https://www.ventoy.net/) で1本の USB メモリに両方入れます。起動時のメニューでどちらかを選べます。

準備（初回のみ、PowerShell で）:

```powershell
winget install jdx.mise
```

実行（`windows` フォルダで）:

```powershell
mise install          # gsudo（管理者実行用）を入れる
mise run usb-all      # ダウンロード → 確認 → USB 作成
```

### curl でワンライナー実行（クローン不要）

mise を入れた後、PowerShell に次の1行を貼り付けます（`curl.exe` は Windows 11 に最初から入っています）。`~\mint-usb` にファイルを落として、そこで実行します。

```powershell
mkdir ~\mint-usb -Force | Out-Null; cd ~\mint-usb; curl.exe -fLO https://raw.githubusercontent.com/bluehive/my-linux-mint-setup/main/windows/make-mint-usb.ps1; curl.exe -fLO https://raw.githubusercontent.com/bluehive/my-linux-mint-setup/main/windows/mise.toml; mise trust; mise install; mise run usb-all
```

mise を使わないときは、**管理者の PowerShell** で次の1行でも動きます。

```powershell
mkdir ~\mint-usb -Force | Out-Null; cd ~\mint-usb; curl.exe -fLO https://raw.githubusercontent.com/bluehive/my-linux-mint-setup/main/windows/make-mint-usb.ps1; powershell -NoProfile -ExecutionPolicy Bypass -File .\make-mint-usb.ps1 -Step all
```

- 片方だけ入れるときは、先に `$env:MINT_EDITION = "mate"`（または `"xfce"`）を設定します。
- 個別のタスクもあります: `mise run iso-download`、`mise run iso-verify`、`mise run usb-write`。
- USB の番号を選び、`ERASE` と入力したときだけ書き込みます。**その USB の中身はすべて消えます。**
- USB メモリは 8GB 以上（両方入れるなら 16GB 以上）を使ってください。

## 注意

- `config/` フォルダ（`packages.list`、`mise.toml`、`repos.txt`）は、このリポジトリに含めていません。必要なら自分で用意してください。無ければ、その手順は飛ばされます。
- `sudo` を使います。中身を確認してから実行してください。

## 確認と制約

- 一般ユーザーで実行してください。`setup.sh wsl2` ではデスクトップ用パッケージを省き、Emacs は `emacs-nox` を使います。ただし、自分で用意した `config/packages.list` や mise 設定の内容はそのまま復元します。
- IBus / Mozc は、再ログイン後に IBus の設定で「日本語 (Mozc)」を選んでください。
- 非公開の Emacs 設定を取得するには、GitHub CLI の認証または GitHub に登録した SSH 鍵が必要です。取得失敗は警告として表示します。
- `usb-write` / `-Step usb` でも、USB 消去前に ISO の SHA256 を再確認します。ISO は選択したディスクの Ventoy ボリュームにだけコピーします。
- チェックサムは ISO と同じミラーから取得します。破損検知のための確認であり、署名による真正性の検証は行いません。[Mint 公式の検証手順](https://linuxmint-installation-guide.readthedocs.io/en/latest/verify.html)も参照してください。
- 検証: `python3 -m unittest discover -s tests -v`（モックによる Linux 分岐の確認）。Windows / Mint / WSL2 実機でのインストールと USB 書き込みは別途確認が必要です。
