# zdmck - zmk firmware devcontainer
ZMK（ZMK Firmware）のビルド環境をDockerおよびVS CodeのDevcontainerで構築するための資材です。<br>
ローカル環境を汚すことなく、ローカルのVS Code上で簡単かつ高速にファームウェアのビルドや編集が行えます。

## 開発環境の要件 (Prerequisites)
- [Visual Studio Code](https://code.visualstudio.com/)
- [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)（VS Code 拡張機能）
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) （または任意のDocker Engine）

> [!NOTE]
> 上記要件に加え、開発スタイルや好みに合わせて**VS Codeの拡張機能を自由に追加・使用することが可能**です。
> 
> * **一時的な追加:** コンテナ起動後、拡張機能タブから任意の拡張機能を自由にインストールしてご利用いただけます。
> * **永続的な共有:** フォーク先などで常に特定の拡張機能を自動反映したい場合は、`.devcontainer.json` 内の `customizations.vscode.extensions` 配下に拡張機能IDを追加してください。

> [!WARNING]
> **変更内容の保存とバージョン管理について**
> 
> キーマップや設定ファイルなどの修正内容は、ビルド時のオーバヘッド軽減を目的に、<br>
> Docker内の**名前付きボリューム（Named Volume）内に保存**され、ローカルのファイルブラウザからは閲覧できません。<br>
> ボリュームの再作成や削除によって変更内容が失われるのを防ぐため、ソースコードを修正した後は<br>
> **VS CodeのGit拡張機能やターミナルでの `git` コマンドを使用し、必ずGitHubなどの外部リポジトリへコミット・プッシュ**することを推奨します。

## 使い方 (Usage)

1. **リポジトリの準備**
   - 本リポジトリをローカルにクローンします。フォークは任意です。
     ```bash
     git clone https://github.com/skubmdi/zdmck
     ```

2. **VS Codeで開く**
   - クローンしたフォルダを VS Code で開きます。

3. **コンテナの起動**
   - ポップアップが表示されたら「Reopen in Container」を選択します。
   - 表示されない場合はコマンドパレット（`Ctrl+Shift+P` / `Cmd+Shift+P`）から **`Dev Containers: Reopen in Container`** を実行してください。

4. **ビルド対象のクローン**
   - コンテナ内のターミナルで `git clone <リポジトリ名>` 等で、コンテナ内のボリュームへリポジトリをクローンします。

5. **設定・ビルド**
   - コンテナ内のターミナルで `zdmck build <フォルダ名>` を実行すると、初期設定からビルドまでが自動で行われます。

6. **キーマップ描写**
   - コンテナ内のターミナルで `zdmck draw <フォルダ名>` を実行すると [caksoylar/keymap-drawer](https://github.com/caksoylar/keymap-drawer) によるkeymapコマンドが実行され、キーマップの画像ファイルを生成します。

> [!NOTE]
> ビルドの設定情報には、ZMK公式の GitHub Actions ワークフローで使われる **`build.yaml`** の記述形式をそのまま使用します。<br>
> 既存の ZMK 設定リポジトリに動作済みの `build.yaml` がある場合、手順は不要です。

### ビルドの動作仕様
* **並列実行:** `build.yaml` 内の `include` に定義されたすべてのターゲット構成を並行して同時にビルドします。
* **クリーンビルド:** ビルドの実行ごとに過去のビルド結果やキャッシュを破棄し、常にクリーンな状態から再構築を行います。
* **成果物の出力:** ビルドが完了した成果物（`.uf2` / `.bin` ファイル、ログ、Devicetree構成等）は、すべてローカル側の **`output/` フォルダ配下に自動で出力**されます。

> [!TIP]
> **ビルド時のファイル構成**
> 
> ビルド実行時は基本的に対象の**フォルダ名**のみを指定します。<br>
> 以下のファイル群が存在している前提で処理が組まれています。
>
> - `./<フォルダ名>/build.yaml` （ビルド対象のマトリクス定義）
> - `./<フォルダ名>/config/west.yml` （マニフェストファイル）
> - `./<フォルダ名>/zephyr/module.yml` （ZMKモジュール定義 ※モジュールとしてビルドする場合）
>
> デフォルトの構成と異なる場合は、`zdmck build` コマンドへ引数を渡すことで各設定ファイルのパスやファイル名を個別に変更可能です。
> ```bash
> zdmck build <フォルダ名> \
>   [config="config"] [west="west.yml"] \
>   [build="build.yaml"] [zephyr="zephyr/module.yml"]
> ```

### キーマップ描画の動作仕様
* **設定ファイルの自動検知:** フォルダ内に `info.json` や `keymap.keymap` の名称で存在しない場合でも、<br>
  `config/` フォルダ配下にある最初の `*.json` / `*.keymap` ファイルを自動検出して処理します。
* **成果物の出力:** `keymap.yaml` および `keymap.svg` が `output/<target>/` 配下に出力されます。

> [!TIP]
> **キーマップ描画時のファイル構成**
> 
> キーマップ描画実行時も基本的に対象の**フォルダ名**のみを指定します。<br>
> この指定フォルダの直下に、以下のファイル群が存在している前提で処理が組まれています。<br>
> *keymap-drawerの描画設定ファイル仕様については[公式ドキュメント](https://github.com/caksoylar/keymap-drawer/blob/main/CONFIGURATION.md)を参照ください。*
>
> - `./draw.yaml` （keymap-drawerの描画設定ファイル、任意）
> - `./<フォルダ名>/config/info.json` （レイアウト情報ファイル）
> - `./<フォルダ名>/config/keymap.keymap` （キーマップ設定ファイル）
>
> デフォルトの構成と異なる場合は、`zdmck draw` コマンドへ引数を渡すことで各設定ファイルのパスやファイル名を個別に変更可能です。
> ```bash
> zdmck draw <target> [draw="draw.yaml"] \
>   [config="config"] [info="info.json"] [keymap="keymap.keymap"]
> ```

## 実行例 (Example)
```bash
root@xxxxxxxxxxxx:/zmk-devcontainer# git clone https://github.com/skubmdi/zmk-config-corne
    Cloning into 'zmk-config-corne'...
    remote: ~, done.
    Resolving ~, done.
root@688aa6923fb5:/zmk-devcontainer# ls -l zmk-config-corne
total 0
    drwxr-xr-x 1 root root xxx xxx xx xx:xx config
    -rw-r--r-- 1 root root xxx xxx xx xx:xx build.yaml
root@xxxxxxxxxxxx:/zmk-devcontainer# zdmck build zmk-config-corne
    build start corne_left-ble_micro_pro-zmk
    build start corne_right-ble_micro_pro-zmk
    build start settings_reset-ble_micro_pro-zmk
    build success settings_reset-ble_micro_pro-zmk
    build success corne_right-ble_micro_pro-zmk
    build success corne_left-ble_micro_pro-zmk
root@xxxxxxxxxxxx:/zmk-devcontainer# zdmck draw zmk-config-corne
    ~
root@688aa6923fb5:/zmk-devcontainer# ls -l output/zmk-config-corne
    -rw-r--r-- 1 root root xxxxxxx xxx xx xx:xx keymap.svg
    -rw-r--r-- 1 root root xxxxxxx xxx xx xx:xx keymap.yaml
    -rwxr-xr-x 1 root root xxxxxxx xxx xx xx:xx corne_left-ble_micro_pro-zmk.bin
    -rw-r--r-- 1 root root xxxxxxx xxx xx xx:xx corne_left-ble_micro_pro-zmk.config
    -rw-r--r-- 1 root root xxxxxxx xxx xx xx:xx corne_left-ble_micro_pro-zmk.dts
    -rw-r--r-- 1 root root xxxxxxx xxx xx xx:xx corne_left-ble_micro_pro-zmk.dts.pre
    -rwxr-xr-x 1 root root xxxxxxx xxx xx xx:xx corne_left-ble_micro_pro-zmk.elf
    -rw-r--r-- 1 root root xxxxxxx xxx xx xx:xx corne_left-ble_micro_pro-zmk.hex
    -rw-r--r-- 1 root root xxxxxxx xxx xx xx:xx corne_left-ble_micro_pro-zmk.log
    -rw-r--r-- 1 root root xxxxxxx xxx xx xx:xx corne_left-ble_micro_pro-zmk.map
    -rw-r--r-- 1 root root xxxxxxx xxx xx xx:xx corne_left-ble_micro_pro-zmk.stat
    -rw-r--r-- 1 root root xxxxxxx xxx xx xx:xx corne_left-ble_micro_pro-zmk.uf2
    -rwxr-xr-x 1 root root xxxxxxx xxx xx xx:xx corne_right-ble_micro_pro-zmk.bin
    -rw-r--r-- 1 root root xxxxxxx xxx xx xx:xx corne_right-ble_micro_pro-zmk.config
    -rw-r--r-- 1 root root xxxxxxx xxx xx xx:xx corne_right-ble_micro_pro-zmk.dts
    -rw-r--r-- 1 root root xxxxxxx xxx xx xx:xx corne_right-ble_micro_pro-zmk.dts.pre
    -rwxr-xr-x 1 root root xxxxxxx xxx xx xx:xx corne_right-ble_micro_pro-zmk.elf
    -rw-r--r-- 1 root root xxxxxxx xxx xx xx:xx corne_right-ble_micro_pro-zmk.hex
    -rw-r--r-- 1 root root xxxxxxx xxx xx xx:xx corne_right-ble_micro_pro-zmk.log
    -rw-r--r-- 1 root root xxxxxxx xxx xx xx:xx corne_right-ble_micro_pro-zmk.map
    -rw-r--r-- 1 root root xxxxxxx xxx xx xx:xx corne_right-ble_micro_pro-zmk.stat
    -rw-r--r-- 1 root root xxxxxxx xxx xx xx:xx corne_right-ble_micro_pro-zmk.uf2
    -rwxr-xr-x 1 root root xxxxxxx xxx xx xx:xx settings_reset-ble_micro_pro-zmk.bin
    -rw-r--r-- 1 root root xxxxxxx xxx xx xx:xx settings_reset-ble_micro_pro-zmk.config
    -rw-r--r-- 1 root root xxxxxxx xxx xx xx:xx settings_reset-ble_micro_pro-zmk.dts
    -rw-r--r-- 1 root root xxxxxxx xxx xx xx:xx settings_reset-ble_micro_pro-zmk.dts.pre
    -rwxr-xr-x 1 root root xxxxxxx xxx xx xx:xx settings_reset-ble_micro_pro-zmk.elf
    -rw-r--r-- 1 root root xxxxxxx xxx xx xx:xx settings_reset-ble_micro_pro-zmk.hex
    -rw-r--r-- 1 root root xxxxxxx xxx xx xx:xx settings_reset-ble_micro_pro-zmk.log
    -rw-r--r-- 1 root root xxxxxxx xxx xx xx:xx settings_reset-ble_micro_pro-zmk.map
    -rw-r--r-- 1 root root xxxxxxx xxx xx xx:xx settings_reset-ble_micro_pro-zmk.stat
    -rw-r--r-- 1 root root xxxxxxx xxx xx xx:xx settings_reset-ble_micro_pro-zmk.uf2
```
