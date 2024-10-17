#!/bin/env bash

# Copyright (c) Ruhollah 2016
# Copyright (c) mast3rz3ro 2024
# This fork are licensed under GNU GPL-2.0-only
# USING THIS FORK WILL ENFORCE YOU TO FOLLOW THE GNU GPL-2.0-only LICENSE.


func_usage()
{
	printf "help\n"
	exit 0
}

func_deps()
{
		deps="file unzip aapt"
	for dep in $deps; do
			b="$(which "$dep")"
		if [ ! -s "$b" ]; then
			printf "[!] This utility cannot run without $dep\n"
			exit 1
		fi
	done
}

printd()
{
	if [ "$verbose" = "yes" ]; then
		if [ -z "$2" ]; then
			printf -- "$1"
		elif [ ! -z "$2" ]; then
			printf -- "$1" >>"$tmp/opertion.log"
		fi
	fi
}

func_mkdir()
{
		if [ ! -d "$1" ]; then
			printf "[x] Creating directory: '$1'\n"
			mkdir -p "$1"
		fi
		if [ ! -w "$1" ]; then
			printf "[!] Error can not write into: '$1'.\n"
			exit 1
		fi
}

func_config()
{
		# check system
	if [[ "$PREFIX" = *"com.termux"* ]]; then
		tmp="/sdcard/Android/media/tmp"
		local library_dir="/sdcard/Android/media"
		printd "[v] Running on host: termux-android\n"
	else
		tmp=~/tmp
		local library_dir=~/
		printd "[v] Running on host: Linux/GNU\n"
	fi
			# make tmp dir
			func_mkdir "$tmp"

		# target/input dir
	if [ -z "$target_dir" ]; then
		if [ -d "./input" ]; then
			target_dir="./input"
		else
			exit 0
		fi
	fi
	if [ "$target_dir" = "./input" ] || [ "$target_dir" = "input" ]; then
		output_mode="normal"
	elif [ ! -z "$target_dir" ] && [ "$output_mode" != "custom" ]; then
		output_mode="dynamic"
	fi
		# output dir
	if [ "$output_mode" = "normal" ]; then
		output_dir="./renamed"
		func_mkdir "$output_dir"
	elif [ "$output_mode" = "dynamic" ]; then
		output_dir=""
	elif [ "$output_mode" = "custom" ]; then
		func_mkdir "$output_dir"
	fi
		# overwrite with library dir
	if [ "$library_mode" = "yes" ]; then
		if [ "$output_mode" = "dynamic" ]; then
			output_dir="$library_dir/APK-Library"
			func_mkdir "$output_dir"
			output_mode="library"
		elif [ "$output_mode" = "custom" ]; then
			output_dir="$output_dir/APK-Library"
			func_mkdir "$output_dir"
			output_mode="library"
		fi
	fi

		printd "[v] Target directory: '${target_dir}'\n"
		printd "[v] Output directory: '${output_dir}'\n"
		printd "[v] Output mode: '${output_mode}'\n"
		printf "${0}: func_config: $(date)\n">>"$tmp/opertion.log"
		printf -- "- - - - - - - - - - - - - - - - - - - -\n"

}

func_rename()
{
	# mv error handling
	local mv_src="$1"
	local mv_dst="$2"
	local src_file="${mv_src##*/}"
	local dst_file="${mv_dst##*/}"
	local src_dir="${mv_src%/*}"
	local dst_dir="${mv_dst%/*}"
	
	printf "[!] APK Location: '$src_dir'\n"
	printf "[x] Output Location: '$dst_dir'\n"
	printf "[!] Old name: '$src_file'\n"
	printf "[x] New name: '$dst_file'\n"
	
	while read x; do
			printd "func_rename: mv_cmd: ${x}\n"
		if [[ "$x" = "renamed "* ]]; then
			mv_err0=$((mv_err0+1))
		elif [[ "$x" = *"are the same file"* ]] || [[ "$x" = *"Skipping overwritting"* ]]; then
			mv_err2=$((mv_err2+1))
		elif [[ "$x" = *"Operation not permitted"* ]]; then
			mv_err3=$((mv_err3+1))
			printf "${0}: func_rename: mv_err3: $x\n">>"$tmp/opertion.log"
		else
			mv_err1=$((mv_err1+1))
			printf "${0}: func_rename: mv_err1: $x\n">>"$tmp/opertion.log"
		fi
	done< <( if [ -s "$mv_dst" ]; then printf "[!] Skipping overwritting: '$mv_dst'\n"; else mv -v "$mv_src" "$mv_dst"  2>&1; fi)
}

func_dup_rename()
{
		local label="$1"
		local suffix="$2"
		local library_dir="$3"
		local src="$4"
		local dst="${library_dir}/${label}/${5}"
	if [ ! -d "$library_dir/${label}" ]; then
		func_mkdir "${library_dir}/${label}"
	fi
	
	# increasment rename (pain!)
	local i=0
	while true; do
	local i=$((i+1))
		if [ "$i" -ge "21"  ]; then
			printd "[!] Skipping since 20 tries is reached: '${dst}.${suffix}'\n"
			printf "${0}: func_dup_rename: max tries is reached(${i}): $x\n">>"$tmp/opertion.log"
			break
		elif [ ! -e "${dst}.${suffix}" ]; then
			func_rename "$src" "${dst}.${suffix}"
			break
		elif [ ! -e "${dst}_${i}.${suffix}" ]; then
			func_rename "$src" "${dst}_${i}.${suffix}"
			break
		fi
	done
}

func_stats ()
{
	if [ -z "$mv_err0" ]; then
		mv_err0="0"
	fi
	if [ -z "$mv_err1" ]; then
		mv_err1="0"
	fi
	if [ -z "$mv_err2" ]; then
		mv_err2="0"
	fi
	if [ -z "$mv_err3" ]; then
		mv_err3="0"
	fi
	if [ -z "$total_split" ]; then
		total_split="0"
	fi
	if [ -z "$total_unknown" ]; then
		total_unknown="0"
	fi
	if [ -z "$total_combined" ]; then
		total_combined="0"
	fi
		local total_skipped="$(expr "$total_files" - "$total_apk")"
		local total_rename_fails="$(expr "$mv_err1" + "$mv_err2" + "$mv_err3" )"
		printf "[x] Total proccedd APK: ${total_apk}\n"
		printf "[x] Total skipped none APK: ${total_skipped}\n"
		printf "[x] Total successfully renamed (mv cmd): ${mv_err0}\n"
		printf "[x] Total failed to rename (mv cmd): ${total_rename_fails}\n"
		printd "[v] Total proccedd single-split: ${total_split}\n"
		printd "[v] Total proccedd combined-apk: ${total_combined}\n"
		printd "[v] Total failed to detect APK: ${total_unknown}\n"
		printd "[v] Total already renamed (mv cmd): ${mv_err2}\n"
		printd "[v] Total permission denied (mv cmd): ${mv_err3}\n"
		printd "[v] Total unknown error (mv cmd): ${mv_err1}\n"
}

func_find_apk()
{
	# index func_stats
		local total_files="0"
		total_apk="0"
	# find apk
	while read f; do
		if [ -s "$f" ]; then
			local total_files=$((total_files+1))
			old_name="${f##*/}"
			target_dir="${f%/*}"
			if [ "$output_mode" = "dynamic" ]; then
				output_dir="${f%/*}"
			fi
				func_process_apk "$f"
		else
			printd "[v] Skipping none/empty file: '${f}'\n"
		fi
	done< <( find "$target_dir" -type f )
	if [ "$total_files" != "0" ]; then
		func_stats
	else
		printf "[!] The target directory is empty: '${target_dir}'\n"
		exit 0
	fi
}

iserr0()
{
	if [ "$?" = "0" ]; then
		return 0
	else
		local func="$1"
		local msg="$2"
		local cmd="$3"
		local cmd_err="$(cat "${tmp}/err" | sed -z 's/\n/_newline_/g')"
		printd "[v] ${msg}\n"
		printf "${0}: ${func}: ${msg} $cmd: $cmd_err\n">>"$tmp/opertion.log"
		return 1
	fi
}

func_extract_apk()
{
		local mode="$1"
		local x="$2"
		local c="$3"
	if [ "$mode" = "main" ]; then
		local t="$(printf -- "$c" | grep -F ".apk")"
		printd "[v] Extracting main APK: '$t'\n"
		printd "[v] Extracting as: '${tmp}/base.apk'\n"
		unzip -pqq "$x" "$t">"${tmp}/base.apk" 2>"${tmp}/err"
		iserr0 "func_extract_apk" "failed extracting: ${t}" "unzip_main"
		printd "[v] Moving unneedeed file into: '${tmp}/base_bak.apk'\n"
		printf "${0}: func_process_apk: removing file: '$x' into: '${tmp}/base_bak.apk'\n">>"$tmp/opertion.log"
		mv --backup=t "$x" "$tmp/base_bak.apk"
	elif [ "$mode" = "base" ]; then
		printd "[v] Extracting base APK: '$c'\n"
		printd "[v] Extracting as: '${tmp}/base.apk'\n"
		unzip -pqq "$x" "$c">"${tmp}/base.apk" 2>"${tmp}/err"
		iserr0 "func_extract_apk" "failed extracting: ${c}" "unzip_base"
	elif [ "$mode" = "obb" ]; then
		#local t="$(printf -- "$c" | grep -vF ".obb")"
		printd "[v] Extracting combined APK: '$c'\n"
		printd "[v] Extracting as: '${tmp}/base.apk'\n"
		unzip -pqq "$x" "$c">"${tmp}/base.apk" 2>"${tmp}/err"
		iserr0 "func_extract_apk" "failed extracting: ${c}" "unzip_obb"
	fi
}

func_parse_arch()
{
		native_arch="$(printf -- "$1" | grep -iE "x86|arm|mips" | awk -F 'config.' '{print $2}' | sort | uniq -c | awk '{print $2}' | tr -d " \n" | sed 's/\.apk//g')"
		#local native_arch="$(printf -- "$file_content" | grep -iE "x86|arm|mips" | awk -F 'config.' '{print $2}' | sort | uniq -c | awk '{print $2}' | tr -d " \n" | sed 's/\.apk//g; s/aarm/a+arm/g; s/abia/abi+a/g; s/ax86/a+x86/g; s/x86x86/x86+x86/g')"
		if [ -z "$native_arch" ]; then
			native_arch="NoNative"
		fi
		printd "[v] Native Arch: '$native_arch'\n"
}

func_detect_category()
{

		# determine category (need improve !)
		local x="$1"
		local src="$2"
	if [ "$library_mode" = "yes" ]; then
			printd "[v] Detecting APK category: '$x'\n"
			local list="$(unzip -l "$x" lib* *.dex AndroidManifest.xml *xposed_init | awk '{print $4}' | sed '/Name/d; /----/d' | tr '\n' ' ')"
			echo "${0}: func_detect_category: found files: '$list' inside: '$src'\n">>"$tmp/opertion.log"
		for i in $list; do
				# apparently most apps unnecessary includes getObbDir, should we blame androidSDK for that?
				#result="$(unzip -pqq "$x" "$t" | grep -cao "getObbDir.[^s]")" # look for dir(X) but not dir(s), getObbDir and getObbDirs are totally different. matching libs(.so) are accurate but not for .dex !
				#printd "${0}: verbose: func_detect_category: getObbDir result (all): '${result}' from: '$t' inside: '$src'\n" write_into_log
				local f="${i##*/}"
			if [ "$f" = "libunity.so" ] || [ "$f" = "libUE4.so" ]; then
				category="APK-Games"
				break
			elif [ "$f" = "xposed_init" ]; then
				category="Xposed-Apps"
				break
			elif [ "$f" = "AndroidManifest.xml" ]; then
							# shipping axmldec binary may considered in feature
							# androidSDK provides an atttibute in manifest which can declare the app category.
							# however many apps perfers to not use this attribute and instead rely on PlayStore scheme (domains ids?).
							r="$(unzip -pqq "$x" "$f" | tr -d "\0" | grep -Eoc "category\.GAME|android\.hardware\.gamepad|com\.google\.android\.gms\.games\.APP_ID|com\.facebook\.unity\.FBUnityGameRequestActivity")"
						if [ "$r" -ge "1" ]; then
							category="APK-Games"
							break
						fi
							r="$(unzip -pqq "$x" "$f" | tr -d "\0" | grep -Eoc "android\.permission\.WRITE_MEDIA_STORAGE|android\.permission\.WRITE_EXTERNAL_STORAGE|android\.permission\.MANAGE_EXTERNAL_STORAGE")"
						if [ "$r" -ge "1" ]; then
							category="File-Managers"
							break
						fi
			fi
				category="Other-Apps"
		done
	fi
}

func_process_apk()
{
		printf "[x] Processing file: '${1}'\n"
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
		local file_content="$(unzip -lqq "$1" 2>"${tmp}/err" | grep -E "\.apk|resources.arsc|\.RSA|\.DSA|\.obb" | awk '{print $4}')"
	if [ -s "${tmp}/err" ]; then
		printd "[v] Skipping damaged zipfile: '${1}'\n"
		printf "${0}: func_process_apk: skipping possibly damaged zipfile: '$1'\n">>"$tmp/opertion.log"
		return
	fi
		local void="$(printf "${file_content}" | tr '\n' ' ')"
		printd "[v] File contents: '${void}'\n"
		
		local file_content2="$(printf -- "$file_content" | grep -E "\.apk|resources.arsc" | grep -ivE "archive:|assets/|config\..*\.apk|split_.*\.apk|.*/.*\.apk")"
		printd "[v] File contents (filtered): '${file_content2}'\n"
		
		# idenify if single-split
		local manifest=$(aapt d badging "$1")

	if [ "$(printf -- "$manifest" | grep -ocm1 "split='.*'")" = "1" ]; then
		printd "[v] Target type: Single-Split\n"
		local multi_bundle="yes"
		local local split_name=$(echo $manifest | grep -Po "(?<=split=')(.+?)(?=')")
		func_rename "$1" "$output_dir/$split_name.apk"
		total_split=$((total_split+1))
		#func_detect_category "$x" "$src_apk"
		return
	elif [ "$(printf -- "$file_content" | grep -Fcm1 ".obb")" = "1" ]; then
		printd "[v] Target type: OBB-Combined\n"
		local multi_bundle="yes"
		local native_arch=""
		local suffix="apkm"
		local native_arch=""
			func_extract_apk "obb" "$1" "$file_content2"
		if [ "$?" != "0" ]; then
			return
		fi
		local x="${tmp}/base.apk"
		local src_apk="$1"
		total_combined=$((total_combined+1))
		func_detect_category "$x" "$src_apk"
	elif [[ "$file_content2" = *"resources.arsc"* ]]; then
		printd "[v] Target type: APK\n"
		local multi_bundle="no"
		local native_arch=""
		local suffix="apk"
		local x="$1"
		local src_apk="$1"
		func_detect_category "$x" "$src_apk"
	elif [ "$(printf "$file_content" | grep -ocF ".apk")" = "1" ]; then
		printd "[v] Target type: APK\n"
		local multi_bundle="no"
		local native_arch=""
		local suffix="apk"
			func_extract_apk "main" "$1" "$file_content"
		if [ "$?" != "0" ]; then
			return
		fi
		local x="${tmp}/base.apk"
		local src_apk="${tmp}/base.apk"
		func_detect_category "$x" "$src_apk"
	elif [[ "$file_content2" = *".apk"* ]]; then
		printd "[v] Target type: Multi-Bundle\n"
		local multi_bundle="yes"
		local suffix="apks"
		func_parse_arch "$file_content"
			func_extract_apk "base" "$1" "$file_content2"
		if [ "$?" != "0" ]; then
			return
		fi
		local x="${tmp}/base.apk"
		local src_apk="$1"
		func_detect_category "$x" "$src_apk"
	else
		printd "[!] faild to detect APK type of: '$1'\n"
		printf "${0}: func_process_apk: faild to detect APK type of: '$1'\n">>"$tmp/opertion.log"
		total_unknown=$((total_unknown+1))
		return
	fi
		total_apk=$((total_apk+1))

		# parsing time
		local manifest=$(aapt d badging "$x")
		local label=$(echo $manifest | grep -Po "(?<=application: label=')(.+?)(?=')")
	if [ -z "$label" ]; then
		local label=$(echo $manifest | grep -Po "(?<=application-label:')(.+?)(?=')")
	fi
		#local split_name=$(echo $manifest | grep -Po "(?<=split=')(.+?)(?=')")
		local package_name=$(echo $manifest | grep -Po "(?<=package: name=')(.+?)(?=')")
		local version_code=$(echo $manifest | grep -Po "(?<=versionCode=')(.+?)(?=')")
		local version_name=$(echo $manifest | grep -Po "(?<=versionName=')(.+?)(?=')")
		local min_sdk=$(echo $manifest | grep -Po "(?<=sdkVersion:')(.+?)(?=')")
		local max_sdk=$(echo $manifest | grep -Po "(?<=targetSdkVersion:')(.+?)(?=')")
		sdk_ver $min_sdk $max_sdk
	if [ "$multi_bundle" = "no" ]; then
		local native_arch="$(echo $manifest | grep -Po "(?<=native-code: ')(.*)")"
			if [ -z "$native_arch" ]; then
				local native_arch="NoNative"
			fi
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
	if [ "$library_mode" = "yes" ]; then
		local pattern_name2="${label}_(v${version_name}-${version_code}_${stamp})_(${package_name}_${min_ver}+${max_ver}_${native_arch})"
		local final_name2=$(echo $pattern_name2 | tr -d '\\' | tr -d '/' | sed "s/alt\-native\-code: '//; s/' '/+/g; s/armeabi/arm/g; s/-v/_v/g; s/: //g; s/icon=//g; s/split=//g" | tr -d ":'" | tr " " "+")
	fi
		local pattern_name="${label}_(v${version_name}-${version_code}_${stamp})_(${package_name}_${min_ver}+${max_ver}_${native_arch}).$suffix"
		local final_name=$(echo $pattern_name | tr -d '\\' | tr -d '/' | sed "s/alt\-native\-code: '//; s/' '/+/g; s/armeabi/arm/g; s/-v/_v/g; s/: //g; s/icon=//g; s/split=//g" | tr -d "'" | tr " " "+")

	echo
	if [ "$library_mode" = "yes" ]; then
		local label="$(printf -- "$label" | sed "s/: //g; s/./-/g")"
		func_dup_rename "$label" "$suffix" "$output_dir/${category}" "$src_apk" "$final_name2"
	else
		func_rename "$src_apk" "$output_dir/${category}/$final_name"
	fi
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

while getopts i:o:lc option
		do
				case "${option}"
		in
				i) target_dir="${OPTARG}";;
				o) output_mode="custom"; output_dir="${OPTARG}";;
				l) library_mode="yes";;
				c) clean_mode="yes";;
				?) func_usage;;
			esac
done

		func_deps
		func_config $@
		func_find_apk
	if [ "$library_mode" = "yes" ] && [ "$clean_mode" = "yes" ]; then
		echo "[x] Cleaning-up Library directory: '$output_dir' "
		find "$output_dir" -mindepth 1 -type d -empty -delete
	fi
