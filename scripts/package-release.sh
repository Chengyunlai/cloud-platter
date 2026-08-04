#!/bin/bash

set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
version="${1:-0.0.0-dev}"
app_name="CloudPlatter"
dist_dir="$project_root/dist"
app_dir="$dist_dir/$app_name.app"
contents_dir="$app_dir/Contents"

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]]; then
    echo "版本号必须符合语义化版本格式，例如 0.1.0 或 0.1.0-beta.1。" >&2
    exit 1
fi

rm -rf "$dist_dir"
mkdir -p "$contents_dir/MacOS" "$contents_dir/Resources"

# 分别构建两种架构，再合并为一个 Universal 可执行文件。
arm64_bin_dir="$(swift build --package-path "$project_root" --configuration release --triple arm64-apple-macosx14.0 --product "$app_name" --show-bin-path)"
x86_64_bin_dir="$(swift build --package-path "$project_root" --configuration release --triple x86_64-apple-macosx14.0 --product "$app_name" --show-bin-path)"

swift build --package-path "$project_root" --configuration release --triple arm64-apple-macosx14.0 --product "$app_name"
swift build --package-path "$project_root" --configuration release --triple x86_64-apple-macosx14.0 --product "$app_name"

lipo -create \
    "$arm64_bin_dir/$app_name" \
    "$x86_64_bin_dir/$app_name" \
    -output "$contents_dir/MacOS/$app_name"

cp "$project_root/Config/Info.plist" "$contents_dir/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $version" "$contents_dir/Info.plist"

# 开源构建使用 ad-hoc 签名；Release 页面必须保留 Gatekeeper 提示。
codesign --force --deep --sign - "$app_dir"

archive_path="$dist_dir/$app_name-$version-universal.zip"
ditto -c -k --sequesterRsrc --keepParent "$app_dir" "$archive_path"
shasum -a 256 "$archive_path" > "$archive_path.sha256"

echo "已生成：$archive_path"
