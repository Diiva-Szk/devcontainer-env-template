#!/usr/bin/env bash
# initialize.sh
#   devcontainer.json の initializeCommand から、ホスト側でコンテナのビルド前に実行する。
#   1. devcontainer-env-core（submodule）が未取得なら取得する
#   2. devcontainer-env-core の setup-docker-env.sh で .env を生成・更新する
set -euo pipefail

CORE_REPO_URL="https://github.com/Diiva-Szk/devcontainer-env-core.git"
CORE_SUBMODULE_PATH=".devcontainer/devcontainer-env-core"

# 実行時のカレントディレクトリに依存させず、スクリプト自身の場所を基準にする
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CORE_DIR="${PROJECT_ROOT}/${CORE_SUBMODULE_PATH}"

if [ ! -f "${CORE_DIR}/compose.yml" ]; then
  if git -C "${PROJECT_ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    && [ -f "${PROJECT_ROOT}/.gitmodules" ]; then
    # --recursive なしで clone した場合など。submodule に記録されたコミットを取得する
    echo "==> Initializing submodule ${CORE_SUBMODULE_PATH}..."
    git -C "${PROJECT_ROOT}" submodule update --init -- "${CORE_SUBMODULE_PATH}"
  else
    # ZIP でダウンロードした場合など、Git のリポジトリでないときは main を取得する
    echo "==> Cloning ${CORE_REPO_URL} into ${CORE_SUBMODULE_PATH}..."
    git clone --depth 1 "${CORE_REPO_URL}" "${CORE_DIR}"
  fi
fi

# Docker ソケットのグループ ID などはホストごとに変わり得るため、起動のたびに更新する
bash "${CORE_DIR}/setup-docker-env.sh"
