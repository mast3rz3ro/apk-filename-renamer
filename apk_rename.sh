#!/bin/env bash

rename() {
	if [[ "$(file "$1")" != *"Android package"* ]]; then
		echo "[!] faild to rename this file: $1"
		return
	fi
	local manifest=$(aapt d badging "$1")
	local label=$(echo $manifest | grep -Po "(?<=application: label=')(.+?)(?=')")
	local package_name=$(echo $manifest | grep -Po "(?<=package: name=')(.+?)(?=')")
	local version_code=$(echo $manifest | grep -Po "(?<=versionCode=')(.+?)(?=')")
	local version_name=$(echo $manifest | grep -Po "(?<=versionName=')(.+?)(?=')")
	local min_sdk=$(echo $manifest | grep -Po "(?<=sdkVersion:')(.+?)(?=')")
	local max_sdk=$(echo $manifest | grep -Po "(?<=targetSdkVersion:')(.+?)(?=')")
	local native_arch=$(echo $manifest | grep -Po "(?<=native-code: ')(.*)")
if [ -z "$native_arch" ]; then
   local native_arch="NoNative"
fi

    # combine stage
	local pattern_name="${label}_(v${version_name}-${version_code}-${min_sdk}-${max_sdk})_(${package_name}_${native_arch}).apk"
	local final_name=$(echo $pattern_name | tr -d '\\' | tr -d '/' | sed "s/' '/+/g; s/armeabi/arm/g" | tr -d "'")

	echo
	echo mv -f "$1" "renamed/$final_name"
	echo "[!] Old name: $1"
	echo "[x] New name: $final_name"
	echo
	echo "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - "
	echo
}

sdk_version (){
min_sdk="n"
max_sdk="n"
}

for apk in input/*.apk
do
	rename "$apk"
done
