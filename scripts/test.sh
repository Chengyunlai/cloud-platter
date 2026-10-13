#!/bin/bash

set -euo pipefail

developer_dir="$(xcode-select -p)"
testing_frameworks="$developer_dir/Library/Developer/Frameworks"
testing_libraries="$developer_dir/Library/Developer/usr/lib"
test_arguments=(test)

# 部分 Command Line Tools 已附带 Testing，但 SwiftPM 未自动加入框架与运行库搜索路径。
if [[ -d "$testing_frameworks/Testing.framework" ]]; then
    test_arguments+=(
        -Xswiftc "-F$testing_frameworks"
        -Xlinker -rpath -Xlinker "$testing_frameworks"
        -Xlinker -rpath -Xlinker "$testing_libraries"
    )
fi

exec swift "${test_arguments[@]}" "$@"
