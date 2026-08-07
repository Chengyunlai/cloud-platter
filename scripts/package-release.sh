#!/bin/bash

set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
version="${1:-0.0.0-dev}"
app_name="CloudPlatter"
dist_dir="$project_root/dist"
app_dir="$dist_dir/$app_name.app"
contents_dir="$app_dir/Contents"
resources_dir="$contents_dir/Resources"
adapter_build_dir="$project_root/.build/mediaremote-adapter"
adapter_resources_dir="$resources_dir/MediaRemoteAdapter"
jxa_resources_dir="$resources_dir/JXAFallback"
visual_resources_dir="$resources_dir/Visuals"
turntable_resources_dir="$visual_resources_dir/Turntable"
core_number='(0|[1-9][0-9]*)'
prerelease_identifier='(0|[1-9][0-9]*|[0-9A-Za-z-]*[A-Za-z-][0-9A-Za-z-]*)'
build_identifier='[0-9A-Za-z-]+'
semver_pattern="^${core_number}\.${core_number}\.${core_number}(-${prerelease_identifier}(\.${prerelease_identifier})*)?(\+${build_identifier}(\.${build_identifier})*)?$"

if [[ ! "$version" =~ $semver_pattern ]]; then
    echo "版本号必须符合 SemVer 2.0，例如 0.1.0、0.1.0-beta.1 或 0.1.0+build.1。" >&2
    exit 1
fi

bundle_short_version="${version%%[-+]*}"

rm -rf "$dist_dir"
mkdir -p \
    "$contents_dir/MacOS" \
    "$resources_dir" \
    "$adapter_resources_dir" \
    "$jxa_resources_dir" \
    "$visual_resources_dir" \
    "$turntable_resources_dir"

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
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $bundle_short_version" "$contents_dir/Info.plist"

MEDIAREMOTE_ADAPTER_BUILD_DIR="$adapter_build_dir" "$project_root/scripts/build-mediaremote-adapter.sh"
ditto \
    "$adapter_build_dir/MediaRemoteAdapter.framework" \
    "$adapter_resources_dir/MediaRemoteAdapter.framework"
cp "$adapter_build_dir/MediaRemoteAdapterTestClient" "$adapter_resources_dir/"
cp "$project_root/Vendor/mediaremote-adapter/bin/mediaremote-adapter.pl" "$adapter_resources_dir/"
cp "$project_root/scripts/mediaremote-supervisor.sh" "$adapter_resources_dir/"
cp "$project_root/Vendor/mediaremote-adapter/LICENSE" "$adapter_resources_dir/LICENSE.txt"
cp "$project_root/Vendor/yohaku-jxa/netease-now-playing.js" "$jxa_resources_dir/"
cp "$project_root/Vendor/yohaku-jxa/LICENSE" "$jxa_resources_dir/LICENSE.txt"
cp \
    "$project_root/Sources/CloudPlatterApp/Resources/walnut-desktop-4k.jpg" \
    "$visual_resources_dir/walnut-desktop-4k.jpg"
ditto \
    "$project_root/Sources/CloudPlatterApp/Resources/Turntable" \
    "$turntable_resources_dir"
cp "$project_root/THIRD_PARTY_NOTICES.md" "$resources_dir/"

/usr/bin/perl -c "$adapter_resources_dir/mediaremote-adapter.pl" >/dev/null
bash -n "$adapter_resources_dir/mediaremote-supervisor.sh"
test -s "$jxa_resources_dir/netease-now-playing.js"
test -s "$jxa_resources_dir/LICENSE.txt"
test -s "$visual_resources_dir/walnut-desktop-4k.jpg"
test -s "$turntable_resources_dir/turntable-deck.png"
test -s "$turntable_resources_dir/turntable-tonearm.png"
test -s "$turntable_resources_dir/turntable-knob.png"
test -s "$turntable_resources_dir/turntable-plaque.png"

# 开源构建使用 ad-hoc 签名；Release 页面必须保留 Gatekeeper 提示。
codesign --force --deep --sign - "$app_dir"

codesign --verify --deep --strict "$app_dir"

archive_name="$app_name-$version-universal.zip"
archive_path="$dist_dir/$archive_name"
ditto -c -k --sequesterRsrc --keepParent "$app_dir" "$archive_path"

# DMG 提供标准的拖拽安装体验；ZIP 继续作为无需挂载磁盘映像的备用包。
dmg_name="$app_name-$version-universal.dmg"
dmg_path="$dist_dir/$dmg_name"
dmg_source_dir="$dist_dir/dmg-source"
mkdir -p "$dmg_source_dir"
ditto "$app_dir" "$dmg_source_dir/$app_name.app"
ln -s /Applications "$dmg_source_dir/Applications"
hdiutil create \
    -quiet \
    -volname "$app_name $version" \
    -srcfolder "$dmg_source_dir" \
    -format UDZO \
    -ov \
    "$dmg_path"
rm -rf "$dmg_source_dir"
hdiutil verify "$dmg_path" >/dev/null

# 校验文件只记录文件名，下载到任意目录后都可以直接验证。
(
    cd "$dist_dir"
    shasum -a 256 "$archive_name" > "$archive_name.sha256"
    shasum -a 256 "$dmg_name" > "$dmg_name.sha256"
)

echo "已生成：$archive_path"
echo "已生成：$dmg_path"
