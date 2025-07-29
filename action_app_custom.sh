#!/bin/sh
# 模块化自定义脚本：用于构建 阅读.A 共存版 APK

source $GITHUB_WORKSPACE/action_util.sh

# 签名配置
function app_sign() {
    debug "🔏 注入签名配置"
    cp $GITHUB_WORKSPACE/.github/legado/legado.jks $APP_WORKSPACE/app/legado.jks
    sed '$r '"$GITHUB_WORKSPACE/.github/legado/legado.sign"'' $APP_WORKSPACE/gradle.properties -i
}

# 清除 18+ 限制
function app_clear_18plus() {
    debug "🧼 清除 18PlusList.txt"
    echo "" > $APP_WORKSPACE/app/src/main/assets/18PlusList.txt
}

# 修改名称为 阅读.A
function app_rename() {
    if [ "$SECRETS_RENAME" = "true" ]; then
        debug "✏️ 修改 app_name 为 $APP_LAUNCH_NAME"
        sed -i "s/<string name=\"app_name\">阅读<\/string>/<string name=\"app_name\">$APP_LAUNCH_NAME<\/string>/"             $APP_WORKSPACE/app/src/main/res/values-zh/strings.xml || true
        sed -i "s/<string name=\"app_name\">阅读<\/string>/<string name=\"app_name\">$APP_LAUNCH_NAME<\/string>/"             $APP_WORKSPACE/app/src/main/res/values/strings.xml || true
    fi
}

# 设置共存包名后缀（applicationIdSuffix）
function app_enable_coexist() {
    debug "📦 设置共存 applicationIdSuffix → .$APP_SUFFIX"
    sed -i "s/applicationIdSuffix \".*\"/applicationIdSuffix \".$APP_SUFFIX\"/" $APP_WORKSPACE/app/build.gradle || true
    if ! grep -q "applicationIdSuffix" $APP_WORKSPACE/app/build.gradle; then
        sed -i "/defaultConfig {/a\
        applicationIdSuffix \".$APP_SUFFIX\" 
        " $APP_WORKSPACE/app/build.gradle
    fi
}

# Room schema → assets (避免构建失败)
function app_patch_room_assets() {
    debug "📚 添加 Room schema 到 assets"
    sed -i "/sourceSets {/,/main {/s|main {|main {\n            assets.srcDirs += files(\"\\$projectDir/schemas\")|" "$APP_WORKSPACE/app/build.gradle"
}

# 缩小 APK 大小
function app_minify() {
    if [ "$SECRETS_MINIFY" = "true" ]; then
        debug "📦 启用 minify 和 shrinkResources"
        sed -e '/minifyEnabled/i\
            shrinkResources true'             -e 's/minifyEnabled false/minifyEnabled true/'             $APP_WORKSPACE/app/build.gradle -i
    fi
}

# 移除 Firebase 等插件（防止构建失败）
function app_disable_plugins() {
    debug "🚫 移除 firebase/google 插件"
    sed -e '/com.google.gms.google-services/d'         -e '/com.google.firebase/d'         -e '/io.fabric/d'         $APP_WORKSPACE/app/build.gradle -i || true
}

# 删除多余资源
function app_remove_unused() {
    debug "🗑️ 删除无用资源 bg/"
    rm -rf $APP_WORKSPACE/app/src/main/assets/bg
}

# === 调用所有步骤 ===
app_sign
app_clear_18plus
app_rename
app_enable_coexist
app_patch_room_assets
app_minify
app_disable_plugins
app_remove_unused
