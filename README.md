# ZMK Firmware Devcontainer
ZMK（ZMK Firmware）のビルド環境をDockerおよびVS CodeのDevcontainerで構築するための資材です。<br>
ローカル環境を汚すことなく、ローカルのVS Code上で簡単かつ高速にファームウェアのビルドや編集が行えます。

## 開発環境の要件 (Prerequisites)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (または任意のDocker Engine)
- [Visual Studio Code](https://code.visualstudio.com/)
- VS Code 拡張機能: [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

> [!NOTE]
> 上記要件に加え、開発スタイルや好みに合わせて**VS Codeの拡張機能を自由に追加・使用することが可能**です。
> 
> * **一時的な追加:** コンテナ起動後、拡張機能タブから任意の拡張機能を自由にインストールしてご利用いただけます。
> * **永続的な共有:** フォーク先などで常に特定の拡張機能を自動反映したい場合は、`.devcontainer/devcontainer.json` 内の `customizations.vscode.extensions` 配下に拡張機能IDを追加してください。

> [!WARNING]
> **変更内容の保存とバージョン管理について**
> 
> キーマップや設定ファイルなどの修正内容は、Docker内の**名前付きボリューム（Named Volume）内に保存**され、ローカルのファイルブラウザからは閲覧できません。
> 
> コンテナの再作成や削除によって変更内容が失われるのを防ぐため、ソースコードを修正した後は **VS CodeのGit拡張機能やターミナルでの `git` コマンドを使用し、必ずGitHubなどの外部リポジトリへコミット・プッシュ**することを推奨します。

## 使い方 (Usage)
| ステップ | 操作内容 | 詳細 |
| :--- | :--- | :--- |
| 1. リポジトリの準備 | フォーク / クローン | 本リポジトリをローカルにクローンします。フォークは任意です。<br>`git clone https://github.com/skubmdi/zmk-devcontainer`<br>フォークする場合、git-submoduleによるリポジトリ群の管理が可能です。 |
| 2. VS Codeで開く | 開く | クローンしたフォルダを VS Code で開きます。 |
| 3. コンテナの起動 | Reopen in Container | ポップアップが表示されたら「Reopen in Container」を選択します。<br>※表示されない場合はコマンドパレット（`Ctrl+Shift+P` / `Cmd+Shift+P`）から **`Dev Containers: Reopen in Container`** を実行してください。 |
| 4. ビルド対象のクローン | `just clone` コマンド実行 | コンテナ内のターミナルで `just clone <リポジトリ名>` を実行すると、コンテナ内のボリュームへリポジトリがクローンされます。 |
| 5. 設定・ビルド | `just build` コマンド実行 | コンテナ内のターミナルで `just build <クローン済みのフォルダ名>` を実行すると、初期設定 (`west config` / `west update`) からビルドまでが自動で行われます。 |

> [!NOTE]
> ビルドの設定情報には、ZMK公式の GitHub Actions ワークフローで使われる **`build.yaml`** の記述形式をそのまま使用します。<br>
> 既存の ZMK 設定リポジトリにある `build.yaml` がある場合、基本的に追加の手順は必要ありません。

> [!TIP]
> **ディレクトリ構造の前提条件**
> 
> ビルド実行時は基本的に対象の**フォルダ名**のみを指定します。<br>
> この指定フォルダの直下に、以下のファイル群が存在している前提で処理が組まれています。
>
> - `build.yaml` （ビルド対象のマトリクス定義）
> - `config/west.yml` （マニフェストファイル）
> - `zephyr/module.yml` （ZMKモジュール定義 ※モジュールとしてビルドする場合）
>
> **引数によるパスの個別カスタマイズ**
> 
> デフォルトの構成と異なる場合は、`just build` コマンドへ引数を渡すことで各設定ファイルのパスやファイル名を個別に変更可能です。
>
> ```bash
> # 構文（デフォルト値）
> just build <フォルダ名> \
>   [config="config"] [west="west.yml"] \
>   [build="build.yaml"] [zephyr="zephyr/module.yml"]
>
> # 実行例: 独自のファイル名やサブフォルダを指定する場合
> just build <フォルダ名> \
>   "custom_config" "custom_west.yml" "my_build.yaml" "custom_module"
> ```

## ビルドの動作仕様
* **クリーンビルド:** ビルドの実行ごとに過去のビルド結果やキャッシュを破棄し、常にクリーンな状態から再構築を行います。
* **並列実行:** `build.yaml` 内の `include` に定義されたすべてのターゲット構成（`board` と `shield` の組み合わせ）を並行して同時にビルドします。
```yaml
include:
  - board: ble_micro_pro
    shield: corne_left
    snippet: studio-rpc-usb-uart
  - board: ble_micro_pro
    shield: corne_right
    snippet: studio-rpc-usb-uart
  - board: ble_micro_pro
    shield: settings_reset
```

## 成果物の出力先
ビルドが完了した成果物（`.uf2` / `.bin` ファイル、ログ、Devicetree構成等）は、すべてホスト（ローカル）環境へバインドマウントされた **`output/` フォルダ配下に自動で出力**されます。

コンテナ内に入って操作することなく、ローカル側のファイルブラウザ等から直接ファームウェアを取り出してキーボードへ書き込むことが可能です。

## クローン・ビルド実行例 (Example)
```bash
root@xxxxxxxxxxxx:/zmk-devcontainer# just clone https://github.com/skubmdi/zmk-config-corne
    Cloning into 'zmk-config-corne'...
    remote: ~, done.
    Resolving ~, done.
root@688aa6923fb5:/zmk-devcontainer# ls -l zmk-config-corne
total 0
    drwxr-xr-x 1 root root xxx xxx xx xx:xx config
    -rw-r--r-- 1 root root xxx xxx xx xx:xx build.yaml
root@xxxxxxxxxxxx:/zmk-devcontainer# just build zmk-config-corne
    build start corne_left-ble_micro_pro-zmk
    build start corne_right-ble_micro_pro-zmk
    build start settings_reset-ble_micro_pro-zmk
    build success settings_reset-ble_micro_pro-zmk
    build success corne_right-ble_micro_pro-zmk
    build success corne_left-ble_micro_pro-zmk
```
