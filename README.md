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

## タイル型 i3 版（setup-tiling.sh）

MATE / Xfce などの既存デスクトップはそのままに、タイル型ウィンドウマネージャ [i3](https://i3wm.org/) を追加します。**既定のセッションは変えません。**

入れるもの: `i3`（`i3-wm`）、`i3status`、`i3lock`、`suckless-tools`（dmenu を含む）、`alacritty`（無ければ `xterm`）、`feh`、`rofi`、日本語環境（Xfce 版と同じ ja_JP.UTF-8 ロケール、Noto CJK と IPA フォント、IBus と Mozc）。

`/etc/i3/config` を `~/.config/i3/config` にコピーし（既にあれば上書きしません）、Mod+Enter を alacritty に設定、末尾に `exec --no-startup-id ibus-daemon -drx` を追加します（目印のコメントで二重追加を防止）。

### wget で取ってきて実行する

```sh
cd ~
wget -O setup-tiling.sh https://raw.githubusercontent.com/bluehive/my-linux-mint-setup/main/setup-tiling.sh
less setup-tiling.sh      # 中身を確認（q で閉じる）
bash setup-tiling.sh
```

途中で sudo のパスワードを聞かれます。

### i3 でログインする

1. 一度ログアウトします。
2. ログイン画面（LightDM）で、ユーザー名の横または画面右上のセッションアイコンをクリックし、「i3」を選んでからパスワードを入れます。
3. 主なキー（Mod は既定で Alt キー）:

| キー | 動作 |
| --- | --- |
| Mod+Enter | 端末（alacritty） |
| Mod+d | dmenu（アプリ起動） |
| Mod+Shift+d | rofi（アプリ一覧） |
| Mod+Shift+q | ウィンドウを閉じる |
| Mod+1〜0 | ワークスペース切り替え |
| Mod+Shift+e | i3 を終了（ログアウト） |

日本語入力は Ctrl+Space（または 半角/全角）で切り替えます。

### 元に戻す

ログアウトし、ログイン画面のセッション選択で MATE や Xfce を選び直してください。LightDM は前回選んだセッションを覚えます。i3 自体を消す場合は `sudo apt-get remove i3 i3-wm` を実行します。

## Windows 11 でインストール USB を作る（windows/）

Linux Mint 22.3（このスクリプトの既定バージョン）の MATE 版と Xfce 版の ISO をダウンロードし、SHA256 を確認してから、[Ventoy](https://www.ventoy.net/) で1本の USB メモリに両方入れます。起動時のメニューでどちらかを選べます。

### 1. 用意するもの

- Windows 11 の PC、インターネット接続、管理者権限（USB 作成時の UAC 確認に必要）。以下のコマンドは **PowerShell** に貼り付けます。
- USB メモリは片方の版なら 8GB 以上、両方なら 16GB 以上を用意してください。**選んだ USB はパーティションを含めて消去されます。必要なファイルは先にバックアップしてください。** 誤選択を避けるため、ほかの外付け HDD / SSD / USB メモリは外しておきます。
- PC 側にも ISO の保存容量が必要です。両方の版を使う場合は、作業フォルダのあるドライブに 16GB 程度の空きを確保しておくと安心です。

この手順はインストール用 USB を作ります。PC 本体への Mint のインストールは、USB から起動した後の別操作です。

### 2. mise を入れ、作業フォルダを準備する

スタートメニューで「PowerShell」を開き、初回だけ次を実行します。

```powershell
winget install --id jdx.mise --exact
```

インストール後はターミナルを閉じて開き直し、`mise --version` が表示されることを確認します。`winget` が見つからない場合は、Microsoft Store の「アプリ インストーラー」を確認してください。[mise の公式インストール手順](https://mise.jdx.dev/installing-mise.html)も参照できます。

Git を使わずに進める場合は、次を **1行ずつ** 実行します。`$HOME\mint-usb`（ユーザーフォルダ内）に必要な2ファイルを取得します。`curl.exe` は Windows 11 に付属しています。

```powershell
New-Item -ItemType Directory -Force -Path "$HOME\mint-usb" | Out-Null
Set-Location "$HOME\mint-usb"
curl.exe -fLO https://raw.githubusercontent.com/bluehive/my-linux-mint-setup/main/windows/make-mint-usb.ps1
curl.exe -fLO https://raw.githubusercontent.com/bluehive/my-linux-mint-setup/main/windows/mise.toml
```

どちらかの取得が失敗したら、そこで止めて接続を確認し、その行をやり直してください。実行前に `notepad .\make-mint-usb.ps1` と `notepad .\mise.toml` で中身を確認できます。

すでにリポジトリをクローン済みの場合は、上のダウンロードを省き、その中の `windows` フォルダを PowerShell で開いてください。以降は **`make-mint-usb.ps1` と `mise.toml` があるフォルダ** で実行します。

### 3. ISO を取得して USB に書き込む

USB メモリを接続し、同じ PowerShell で次を順に実行します。

```powershell
mise trust            # 内容を確認した、このフォルダの mise.toml を信頼する
mise install          # gsudo（管理者実行用）を入れる
mise run usb-all      # ISO 取得 → SHA256 確認 → USB 作成
```

MATE / Xfce はデスクトップ環境の違いです。既定では両方を取得します。片方だけにする場合は、`mise run usb-all` の **前** に次のどちらかを設定してください。

```powershell
$env:MINT_EDITION = "mate"
# Xfce だけなら: $env:MINT_EDITION = "xfce"
# 両方に戻すなら: Remove-Item Env:MINT_EDITION -ErrorAction SilentlyContinue
```

処理は次の順で進みます。

1. 作業フォルダの `iso` フォルダに、ISO と `sha256sum.txt` をダウンロードし、SHA256 を照合します。取得には回線に応じて時間がかかります。
2. USB 作成のために `gsudo` が管理者権限を要求します。Windows の UAC 確認が出たら内容を確認して許可します。USB 消去前にも SHA256 を再確認します。
3. USB ディスクの一覧が表示されます。**`FriendlyName`（機器名）と `SizeGB`（容量）を照合し、対象の `Number` を入力** します。これは `E:` などのドライブ文字ではありません。判断できなければ `Ctrl+C` で中止し、接続機器を確認してください。
4. 表示された対象が正しいことを確認し、大文字で `ERASE` と入力します。別の文字列なら中止します。ここから先で、その USB の中身が消えます。
5. 初回は Ventoy を `ventoy` フォルダに取得・展開し、USB に GPT 形式でインストールします。その後、選んだ ISO を USB の `Ventoy` ボリュームにコピーします。既存の `ventoy` フォルダに実行ファイルがあれば再利用します。

「完了」が表示されるまで USB を抜かないでください。エクスプローラーで USB の `Ventoy` ドライブに選択した `.iso` があることを確認し、安全な取り外しを行います。ISO は展開せず、ファイルのまま置きます（[Ventoy の公式説明](https://www.ventoy.net/en/doc_start.html)）。

### 4. 作成した USB から起動する

インストール先の PC に USB を挿して再起動し、メーカーの起動メニューから USB を選びます。起動メニューを出すキーは機種によって異なるため、PC の説明書を確認してください。Ventoy のメニューが出たら、MATE または Xfce の ISO を選んで起動します（追加の起動方式の選択が出た場合は、まず通常の起動を選びます）。

Mint のライブ環境が起動したら、画面・ネットワーク・キーボードなどを試せます。PC 本体へ入れる場合は、バックアップとインストール先を確認してからデスクトップのインストーラーを起動してください。[Mint の公式起動ガイド](https://linuxmint-installation-guide.readthedocs.io/en/latest/boot.html)も参照してください。

Secure Boot 関連の画面や起動エラーが出た場合は、表示内容を確認し、[Ventoy の Secure Boot 手順](https://www.ventoy.net/en/doc_secure.html)に沿って対応してください。

### 途中から再開する・困ったとき

| 状況 | 対応 |
| --- | --- |
| ダウンロードが中断した | 同じフォルダ・同じ版の指定で `mise run iso-download` を再実行します。ISO は続きから取得します。 |
| USB を消さずに取得・照合まで行いたい | `mise run iso-verify` を実行します。このタスクは先にダウンロードも行います。 |
| ISO を取得済みで、USB 作成だけやり直したい | `mise run usb-write` を実行します。SHA256 を再確認しますが、**USB の消去も再び行います**。版の指定も前回と合わせてください。 |
| SHA256 が不一致 | エラーに出た ISO を作業フォルダの `iso` から削除し、再ダウンロードします。検証を飛ばして書き込まないでください。 |
| USB が見つからない・番号が不明 | 接続と容量を確認し、ほかの外付けディスクを外して再実行します。 |
| Ventoy の書き込みに失敗した | エラーに表示された場所の `cli_log.txt` を確認します。 |
| Ventoy ドライブが見つからない | スクリプトの案内に従い USB を挿し直し、エクスプローラーで対象を確認して、検証済みの ISO を `iso` から USB の `Ventoy` ドライブへ手動コピーします。 |

### mise を使わずに実行する場合

上の手順2で `make-mint-usb.ps1` を取得・確認した後、スタートメニューの「PowerShell」を右クリックして「管理者として実行」を選びます。作業フォルダへ移動してから実行してください（別の管理者アカウントを使った場合は、取得先の実際のパスを指定します）。

```powershell
Set-Location "$HOME\mint-usb"
powershell -NoProfile -ExecutionPolicy Bypass -File .\make-mint-usb.ps1 -Step all
```

片方だけなら末尾に `-Edition mate` または `-Edition xfce` を付けます。`MINT_EDITION` 環境変数は mise のタスク用なので、直接実行では `-Edition` を指定してください。`-Step download` / `verify` / `usb` で段階別にも実行できます（`verify` は取得済みファイルの照合のみ、`usb` は管理者権限が必要で USB を消去します）。

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
