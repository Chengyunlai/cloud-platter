#!/bin/bash

set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
vendor_dir="$project_root/Vendor/mediaremote-adapter"
adapter_build_dir="${MEDIAREMOTE_ADAPTER_BUILD_DIR:-$project_root/.build/mediaremote-adapter}"

if [[ ! -f "$vendor_dir/CMakeLists.txt" ]]; then
    echo "缺少 MediaRemote Adapter 源码，请先运行 git submodule update --init --recursive。" >&2
    exit 1
fi

if ! command -v cmake >/dev/null 2>&1; then
    echo "构建 MediaRemote Adapter 需要 CMake。" >&2
    exit 1
fi

cmake \
    -S "$vendor_dir" \
    -B "$adapter_build_dir" \
    -DCMAKE_BUILD_TYPE=Release
cmake --build "$adapter_build_dir" --config Release --parallel

framework_binary="$adapter_build_dir/MediaRemoteAdapter.framework/Versions/A/MediaRemoteAdapter"
test_client="$adapter_build_dir/MediaRemoteAdapterTestClient"

if [[ ! -f "$framework_binary" || ! -x "$test_client" ]]; then
    echo "MediaRemote Adapter 构建产物不完整。" >&2
    exit 1
fi

for architecture in arm64 x86_64; do
    if ! lipo -archs "$framework_binary" | tr ' ' '\n' | grep -qx "$architecture"; then
        echo "MediaRemoteAdapter.framework 缺少 $architecture 架构。" >&2
        exit 1
    fi
    if ! lipo -archs "$test_client" | tr ' ' '\n' | grep -qx "$architecture"; then
        echo "MediaRemoteAdapterTestClient 缺少 $architecture 架构。" >&2
        exit 1
    fi
done

echo "已构建 MediaRemote Adapter：$adapter_build_dir"
