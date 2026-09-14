# devcontainer-env-template

[devcontainer-env-core](https://github.com/Diiva-Szk/devcontainer-env-core) を使って開発用の Dev Container を起動するための、ベーステンプレートです。

環境の構成・同梱ツール・注意事項は [devcontainer-env-core の README](https://github.com/Diiva-Szk/devcontainer-env-core#readme) を参照してください。

## 必要なもの

- Docker（Docker Desktop for Mac、または WSL2 上の Docker）
- Git と Bash（WSL2 の場合は WSL 内で使います）
- [VS Code](https://code.visualstudio.com/) と [Dev Containers 拡張機能](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

## 使い方

### 1. clone する

ディレクトリ名を変えて clone します。ディレクトリ名が Dev Container の環境名になります。

```sh
git clone --recursive https://github.com/Diiva-Szk/devcontainer-env-template.git my-project
```

`--recursive` を付け忘れても、起動時に submodule を取得するため問題ありません。

### 2. コンテナを開く

VS Code で clone したディレクトリを開き、コマンドパレットから **Dev Containers: Reopen in Container** を実行します。

起動時に、ホスト側で [.devcontainer/initialize.sh](.devcontainer/initialize.sh) が次を行います。

1. `.devcontainer/devcontainer-env-core`（submodule）が未取得なら取得する
2. `setup-docker-env.sh` で `.devcontainer/devcontainer-env-core/.env` を生成・更新する

`sudo` のパスワードなどの設定は、この `.env` に書きます（[設定項目](https://github.com/Diiva-Szk/devcontainer-env-core#設定項目)）。

## ディレクトリ構成

```text
my-project/
├── .devcontainer/
│   ├── devcontainer.json
│   ├── initialize.sh            # 起動時にホスト側で実行
│   └── devcontainer-env-core/   # submodule
│       ├── compose.yml
│       └── .env                 # 起動時に生成（Git の管理対象外）
└── ...
```

## カスタマイズ

- **VS Code の Feature:** [.devcontainer/devcontainer.json](.devcontainer/devcontainer.json) の `features` で、`vscode-python` / `vscode-terraform` を必要に応じて有効にします。
- **ツールの追加・バージョンの上書き:** プロジェクトルートに `mise.toml` を置きます（[詳細](https://github.com/Diiva-Szk/devcontainer-env-core#ツールの追加バージョンの上書き)）。

## devcontainer-env-core を更新する

submodule で使うバージョン（コミット）を固定しています。更新する場合は次を実行してコミットし、コンテナをリビルドします（**Dev Containers: Rebuild Container**）。

```sh
git submodule update --remote .devcontainer/devcontainer-env-core
git add .devcontainer/devcontainer-env-core
git commit -m "chore: devcontainer-env-core を更新する"
```
