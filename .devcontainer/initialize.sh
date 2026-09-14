#!/usr/bin/env bash
# initialize.sh
#   devcontainer.json の initializeCommand から、ホスト側でコンテナのビルド前に実行する。
#   1. devcontainer-env-core（submodule）が未取得なら取得する
#   2. 取得済みの devcontainer-env-core が、記録されたコミットより古ければ合わせる
#   3. devcontainer-env-core の setup-docker-env.sh で .env を生成・更新する
set -euo pipefail

CORE_REPO_URL="https://github.com/Diiva-Szk/devcontainer-env-core.git"
CORE_SUBMODULE_PATH=".devcontainer/devcontainer-env-core"

# 実行時のカレントディレクトリに依存させず、スクリプト自身の場所を基準にする
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CORE_DIR="${PROJECT_ROOT}/${CORE_SUBMODULE_PATH}"

warn() {
  echo "Warning: $*" >&2
}

is_submodule_checkout() {
  git -C "${PROJECT_ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    && [ -f "${PROJECT_ROOT}/.gitmodules" ]
}

# git pull は submodule の中身を更新しないため、core が古いコミットのまま使われ続けることがある。
# 記録されたコミットより古い（祖先である）場合だけ合わせ、
# 未コミットの変更がある場合や、意図して別のコミットにしている場合は警告のみにする。
sync_submodule() {
  local recorded current

  # インデックスに記録された gitlink のコミット（git submodule status と同じ基準）
  recorded="$(git -C "${PROJECT_ROOT}" ls-files --stage -- "${CORE_SUBMODULE_PATH}" | awk '$1 == "160000" { print $2 }')"
  current="$(git -C "${CORE_DIR}" rev-parse HEAD 2>/dev/null || true)"

  if [ -z "${recorded}" ] || [ -z "${current}" ] || [ "${recorded}" = "${current}" ]; then
    return 0
  fi

  if [ -n "$(git -C "${CORE_DIR}" status --porcelain --untracked-files=no)" ]; then
    warn "${CORE_SUBMODULE_PATH} has uncommitted changes and is not at the recorded commit (${recorded:0:7})."
    warn "Commit or discard the changes, then run: git submodule update -- ${CORE_SUBMODULE_PATH}"
    return 0
  fi

  # 記録されたコミットが未取得なら取得する（オフラインなどで失敗しても起動は続ける）
  if ! git -C "${CORE_DIR}" cat-file -e "${recorded}^{commit}" 2>/dev/null; then
    git -C "${CORE_DIR}" fetch --quiet origin || true
  fi

  if git -C "${CORE_DIR}" merge-base --is-ancestor "${current}" "${recorded}" 2>/dev/null; then
    echo "==> Updating submodule ${CORE_SUBMODULE_PATH} (${current:0:7} -> ${recorded:0:7})..."
    git -C "${PROJECT_ROOT}" submodule update -- "${CORE_SUBMODULE_PATH}"
  else
    # git submodule update --remote で更新してコミット前の場合など、意図して別のコミットにしている可能性がある
    warn "${CORE_SUBMODULE_PATH} is at ${current:0:7}, which differs from the recorded commit (${recorded:0:7})."
    warn "To use the recorded commit, run: git submodule update -- ${CORE_SUBMODULE_PATH}"
  fi
}

if [ ! -f "${CORE_DIR}/compose.yml" ]; then
  if is_submodule_checkout; then
    # --recursive なしで clone した場合など。submodule に記録されたコミットを取得する
    echo "==> Initializing submodule ${CORE_SUBMODULE_PATH}..."
    git -C "${PROJECT_ROOT}" submodule update --init -- "${CORE_SUBMODULE_PATH}"
  else
    # ZIP でダウンロードした場合など、Git のリポジトリでないときは main を取得する
    echo "==> Cloning ${CORE_REPO_URL} into ${CORE_SUBMODULE_PATH}..."
    git clone --depth 1 "${CORE_REPO_URL}" "${CORE_DIR}"
  fi
elif is_submodule_checkout; then
  sync_submodule
fi

# Docker ソケットのグループ ID などはホストごとに変わり得るため、起動のたびに更新する
bash "${CORE_DIR}/setup-docker-env.sh"
