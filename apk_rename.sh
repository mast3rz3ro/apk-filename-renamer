















#!/bin/env bash

usage()
{
   echo help
}

config()
{
   mkdir -p "./tmp"
 if [ ! -d "./tmp" ]; then
   printf "An error occurred while trying to create './tmp' dir.\n"
   exit 1
 fi
}

rename() {
        printd "[v] Currently dealing with: '$1'\n"
        check_zip="$(file $1)"
    if [[ "$check_zip" != *"archive"* ]]; then
        printd "[v] Skipping since it is not zip: '$1'\n"
        return
    fi
        apk_contents="$(unzip -lq "$1" | grep -E "\.apk|resources.arsc")"
        apk_type="$(printf -- "$apk_contents" | grep -E "\.apk|resources.arsc" | grep -ivE "archive:|assets/|config\..*\.apk|split_.*\.apk")"
	if [[ "$apk_type" = *"resources.arsc"* ]]; then
	   local type="1"
	   local native_arch=""
	   suffix="apk"
	   x="$1"
	elif [[ "$apk_type" = *".apk"* ]]; then
	   local type="2"
	   base_apk="$(printf -- "$apk_type" | awk '{print $4}')"
	   printd "[v] Base APK: '$base_apk'\n"
	   native_arch="$(printf -- "$apk_contents" | grep -iE "x86|arm|mips" | awk '{print $4}' | awk -F 'config.' '{print $2}' | sort | uniq -c | awk '{print $2}' | tr -d " \n" | sed 's/\.apk//g; s/aarm/a+arm/g; s/abia/abi+a/g; s/ax86/a+x86/g; s/x86x86/x86+x86/g')"
	   printd "[v] Native Arch: '$native_arch'\n"
	   unzip -poq "$1" "$base_apk">./tmp/base.apk
	   suffix="apks"
	   x="./tmp/base.apk"
	else
		echo "[!] faild to detect APK type of: $1"
		printf "[!] faild to detect APK type of: ${1}\napk_type=\"${apk_type}\"\ncontents:\n$(unzip -l "$1" | head -n20)\n\n">>opertion.log
		return
	fi
	local manifest=$(aapt d badging "$x")
	local label=$(echo $manifest | grep -Po "(?<=application: label=')(.+?)(?=')")
	local package_name=$(echo $manifest | grep -Po "(?<=package: name=')(.+?)(?=')")
	local version_code=$(echo $manifest | grep -Po "(?<=versionCode=')(.+?)(?=')")
	local version_name=$(echo $manifest | grep -Po "(?<=versionName=')(.+?)(?=')")
	local min_sdk=$(echo $manifest | grep -Po "(?<=sdkVersion:')(.+?)(?=')")
	local max_sdk=$(echo $manifest | grep -Po "(?<=targetSdkVersion:')(.+?)(?=')")
if [ -z "$native_arch" ]; then
	local native_arch=$(echo $manifest | grep -Po "(?<=native-code: ')(.*)")
fi
if [ -z "$native_arch" ]; then
   local native_arch="NoNative"
fi

    # combine stage
	local pattern_name="${label}_(v${version_name}-${version_code}-${min_sdk}-${max_sdk})_(${package_name}_${native_arch}).$suffix"
	local final_name=$(echo $pattern_name | tr -d '\\' | tr -d '/' | sed "s/' '/+/g; s/armeabi/arm/g; s/-v/_v/g" | tr -d "'")

	echo
	mv -f "$1" "renamed/$final_name"
	echo "[!] Old name: $1"
	echo "[x] New name: $final_name"
	echo
	echo "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - "
	echo
}

sdk_version ()
{
#signtrue
min_sdk="n"
max_sdk="n"
}

printd ()
{
if [ "$verbose" = "yes" ]; then
   printf "$1"
fi
}

config
for apk in input/*
do
 if [ -s "$apk" ]; then
	rename "$apk"
 fi
done
