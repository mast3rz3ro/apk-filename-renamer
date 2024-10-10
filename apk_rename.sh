#!/bin/env bash

# Copyright (c) Ruhollah 2016 
# Copyright (c) mast3rz3ro 2024

usage()
{
   echo help
}

printd ()
{
	if [ "$verbose" = "yes" ]; then
		printf "$1"
	fi
}

func_config()
{
		# check system
	if [[ "$(printf "$PREFIX")" = *"com.termux"* ]]; then
		tmp="/sdcard/Android/media/tmp"
		printd "[v] Running on host: termux=android\n"
	else
		printd "[v] Running on host: Linux/GNU\n"
		tmp=~/tmp
	fi
			# tmp directory
			mkdir -p "$tmp"
		if [ ! -d "$tmp" ] || [ ! -w "$tmp" ]; then
			printf "Error can not write into: '$tmp'.\n"
			exit 1
		fi
		# output dir
	if [ -z "$1" ]; then
		target_dir="./input"
		output_mode="normal"
		output_dir="./renamed"
	else
		target_dir=$@
		output_mode="dynamic"
		output_dir="none"
	fi
		printd "[v] Target directory: '${target_dir}'\n"
		printf -- "- - - - - - - - - - - - - - - - - - - -\n"
}

func_find_apk()
{
	# find apk
		index="0"
	find "$target_dir" -type f | while read f; do
		if [ -s "$f" ]; then
				old_name="${f##*/}"
			if [ "$output_mode" = "dynamic" ]; then
				output_dir="${f%/*}"
			fi
				rename "$f"
				index=$((index+1))
		else
				printd "[v] Skipping none file: '${f}'\n"
		fi
	done
			printf "[x] Total procesedd APKS: $index\n"
}

rename() {
		printd "[v] Processing file: '${1}'\n"
		local check_zip="$(file "${1}")"
	if [[ "$check_zip" != *"Zip archive"* ]]; then
		if [[ "$check_zip" != *"Android package"* ]]; then
			if [[ "$check_zip" != *" Java archive"* ]]; then
				printd "[v] Skipping since it is not zip nor apk or even a jar: '${1}'\n"
				return
			fi
		fi
	fi

		# determine apk type
		printd "[v] Getting file contents..\n"
		local file_content="$(unzip -lqq "$1" | grep -E "\.apk|resources.arsc|\.RSA|\.DSA" | awk '{print $4}')"
		local void="$(printf "${file_content}" | tr '\n' ' ')"
		printd "[v] File contents: '${void}'\n"
		
		local file_content2="$(printf -- "$file_content" | grep -E "\.apk|resources.arsc" | grep -ivE "archive:|assets/|config\..*\.apk|split_.*\.apk|.*/.*\.apk")"
		printd "[v] File contents (filtered): '${file_content2}'\n"

	if [[ "$file_content2" = *"resources.arsc"* ]]; then
		printd "[v] Target type: APK\n"
		local multi_bundle="no"
		local native_arch=""
		local suffix="apk"
		local x="$1"
	elif [[ "$file_content2" = *".apk"* ]]; then
		printd "[v] Target type: Multi-Bundle\n"
		local multi_bundle="yes"
		local native_arch="$(printf -- "$file_content" | grep -iE "x86|arm|mips" | awk '{print $4}' | awk -F 'config.' '{print $2}' | sort | uniq -c | awk '{print $2}' | tr -d " \n" | sed 's/\.apk//g; s/aarm/a+arm/g; s/abia/abi+a/g; s/ax86/a+x86/g; s/x86x86/x86+x86/g')"
		if [ -z "$native_arch" ]; then
			local native_arch="NoNative"
		fi
		printd "[v] Native Arch: '$native_arch'\n"
		printd "[v] Extracting base APK: '$file_content2'\n"
		printd "[v] Extracting as: '${tmp}/base.apk'\n"
		unzip -pqq "$1" "$file_content2">"${tmp}/base.apk"
		local suffix="apks"
		local x="${tmp}/base.apk"
	else
		printd "[!] faild to detect APK type of: '$1'\n"
		return
	fi
		
		# parsing time
		local manifest=$(aapt d badging "$x")
		local label=$(echo $manifest | grep -Po "(?<=application: label=')(.+?)(?=')")
		local package_name=$(echo $manifest | grep -Po "(?<=package: name=')(.+?)(?=')")
		local version_code=$(echo $manifest | grep -Po "(?<=versionCode=')(.+?)(?=')")
		local version_name=$(echo $manifest | grep -Po "(?<=versionName=')(.+?)(?=')")
		local min_sdk=$(echo $manifest | grep -Po "(?<=sdkVersion:')(.+?)(?=')")
		local max_sdk=$(echo $manifest | grep -Po "(?<=targetSdkVersion:')(.+?)(?=')")
		sdk_ver $min_sdk $max_sdk
	if [ "$multi_bundle" = "no" ]; then
		local native_arch=$(echo $manifest | grep -Po "(?<=native-code: ')(.*)")
	fi

		# signtrue check
		printd "[v] Checking the signature..\n"
		#cert="$(unzip -lqq "$x" | grep -E "\.RSA|\.DSA")"
		signature="$(grep -Fcm1 "android@android.com" "$x")"
	if [ ! -z "$cert" ]; then
		signature="$(unzip -pqq "$x" "$cert" | grep -Fcm1 "android@android.com")"
	else
		signature="$(grep -Fcm1 "android@android.com" "$x")"
	fi
	if [ "$signature" = "1" ]; then
		#stamp="$(md5 "$x" | awk '{print $2}')"
		stamp="modified"
		printd "[v] Detected signature: 'Android Debug'\n"
	else
		stamp="vertified"
		printd "[v] Detected signature: 'Private'\n"
	fi

    # combine stage
	local pattern_name="${label}_(v${version_name}-${version_code}_${stamp})_(${package_name}_${min_ver}+${max_ver}_${native_arch}).$suffix"
	local final_name=$(echo $pattern_name | tr -d '\\' | tr -d '/' | sed "s/' '/+/g; s/armeabi/arm/g; s/-v/_v/g" | tr -d "'" | tr " " "+")

	echo
	mv -f "$1" "$output_dir/$final_name"
	echo "[!] APK Location: $output_dir"
	echo "[!] Old name: $old_name"
	echo "[x] New name: $final_name"
	echo
	printf -- "- - - - - - - - - - - - - - - - - - - -\n"
	echo
}

sdk_ver()
{

	local min_sdk="$1"
	local max_sdk="$2"
	# SDK reversion to Android reversion
sdk_list="\
	sdk35=15 \
	sdk34=14 \
	sdk33=13 \
	sdk32=12.1L \
	sdk31=12 \
	sdk30=11 \
	sdk29=10 \
	sdk28=9 \
	sdk27=8.1 \
	sdk26=8.0 \
	sdk25=7.1 \
	sdk24=7.0 \
	sdk23=6.0 \
	sdk22=5.1.1 \
	sdk21=5.0 \
	sdk20=4.4W \
	sdk19=4.4 \
	sdk18=4.3 \
	sdk17=4.2 \
	sdk16=4.1 \
	sdk15=4.0.3 \
	sdk14=4.0 \
	sdk13=3.2 \
	sdk12=3.1.x \
	sdk11=3.0.x \
	sdk10=2.3.3 \
	sdk9=2.3 \
	sdk8=2.2.2 \
	sdk7=2.1.x \
	sdk6=2.0.1 \
	sdk5=2.0
"

		# find version
	for sdk in $sdk_list; do
		if [[ "$sdk" = "sdk${min_sdk}"* ]]; then
			min_ver="android-$(printf "$sdk" | sed 's/.*=//')"
		elif [[ "$sdk" = "sdk${max_sdk}"* ]]; then
			max_ver="android-$(printf "$sdk" | sed 's/.*=//')"
		fi
	done
			# if no ver found !
		if [ -z "$min_ver" ]; then
			min_ver="sdk${min_sdk}"
		elif [ -z "$max_ver" ]; then
			max_ver="sdk${max_sdk}"
		fi
}

	func_config $@
	func_find_apk
