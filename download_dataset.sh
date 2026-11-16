#!/usr/bin/env bash
# 下载并合并 RLinf-grasp-cube 数据集分卷
# 用法: bash download_dataset.sh [目标目录，默认 ./dataset]
set -euo pipefail

OWNER=leader203
REPO=RLinf-grasp-cube
TAG=dataset-v1
BASE="https://github.com/$OWNER/$REPO/releases/download/$TAG"
NAME="RLinf-grasp-cube-dataset.tar"
NPARTS=45
DEST="${1:-./dataset}"

mkdir -p "$DEST/parts"
cd "$DEST/parts"

echo "==> 下载 SHA256SUMS.txt"
curl -fL --retry 5 --retry-delay 3 -O "$BASE/SHA256SUMS.txt"

echo "==> 下载 $NPARTS 个分卷（断点续传）"
for i in $(seq 0 $((NPARTS - 1))); do
  P=$(printf "%s.part-%03d" "$NAME" "$i")
  if [ -f "$P" ] && grep -q "  $P\$" SHA256SUMS.txt 2>/dev/null; then
    EXPECT=$(grep "  $P\$" SHA256SUMS.txt | awk '{print $1}')
    ACTUAL=$(sha256sum "$P" | awk '{print $1}')
    if [ "$EXPECT" = "$ACTUAL" ]; then
      echo "    [skip] $P 校验通过"
      continue
    fi
  fi
  echo "    [get ] $P"
  curl -fL -C - --retry 8 --retry-delay 5 --retry-all-errors -o "$P" "$BASE/$P" \
    || echo "    [warn] $P 下载中断，可重跑本脚本续传"
done

echo "==> 校验"
sha256sum -c SHA256SUMS.txt

echo "==> 合并"
cat "$NAME".part-* > "../$NAME"
ls -lh "../$NAME"

echo "==> 解包"
tar -xf "../$NAME" -C ..
echo "==> 完成: $(cd ../ && pwd)"
du -sh ..
