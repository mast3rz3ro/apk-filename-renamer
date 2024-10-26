#!/bin/env bash

# Copyright (c) Ruhollah 2016
# Copyright (c) mast3rz3ro 2024
# This fork are licensed under GNU GPL-2.0-only
# USING THIS FORK WILL ENFORCE YOU TO FOLLOW THE GNU GPL-2.0-only LICENSE.


func_usage()
{ # returns: null

	echo -ne "\
 Usage: apksorter [parameters]

 Parameters:   Description:
\t-i\tInput directory (place where to find APK).
\t-o\tOutput directory (place to store APK after renamed).
\t-a\tArchive mode (store APK in more reliable way).
\t-c\tClean empty dirs (only used with archive mode).
\t-g\tgenerate identifiers (used for db).

 Examples:
  # Moves only APK files into the requested dir.
  apksorter -i /sdcard/Download -o /sdcard/Download/MyAPKs
  
  # Archives APK into: '/sdcard/Android/media/APK-Library'
  apksorter -a -i /sdcard/Download
"

	exit 0

}


func_getargs()
{ # returns: $target_dir, $output_dir, $output_mode, $clean_mode, $generate_ids

if [ "$1" = "--help" ] || [ "$1" = "--h" ]; then
	func_usage
fi

while getopts i:o:acg option
		do
	case "${option}"
		in
		i) target_dir="${OPTARG}";;
		o) output_mode="custom"; output_dir="${OPTARG}";;
		a) archive_mode="yes";;
		c) clean_mode="yes";;
		g) generate_ids="yes";;
		?) func_usage;;
	esac
done

}

func_deps()
{ # returns: null
		
		local deps
		local d
		local b
		deps="file unzip aapt"
	for d in $deps; do
			p="$(which "$d")"
		if [ ! -s "$p" ]; then
			echo -ne "[!] This utility cannot run without: $d\n"
			exit 1
		fi
	done
}


_echo()
{ # returns: null

	if [ "$verbose" = "yes" ]; then
			echo -ne "- [verbose]: $1"
	fi

	if [ "$2" = 'nolog' ]; then
			return 0
	elif [ "$2" = '0' ]; then
			echo -ne "\t\t${0}: ${1}" >>"$tmp/opertion.log"
	elif [ "$2" = '1' ]; then
			echo -ne "${0}: ${1}" >>"$tmp/opertion.log"
	elif [ "$2" = '2' ]; then
			echo -ne "\t${0}: ${1}" >>"$tmp/opertion.log"
	else
			echo -ne "\t\t${0}: warnning unknown value is used: '${2}' for message: '${1}'" >>"$tmp/opertion.log"
	fi

}


_iferr()
{ # returns: null
		
		local msg
		local cmd_err
	if [ "$?" = "0" ]; then
		return 0
	else
		msg="$1"
		cmd_err="$(sed -z 's/\n/_LF_/g' "${tmp}/err")"
		_echo "${msg} cmd_stderr: ${cmd_err}\n" 1
		return 1
	fi

}


func_mkdir()
{ # returns: null
	if [ ! -d "$1" ]; then
		echo -ne "[x] Creating directory: '$1'\n"
		mkdir -p "$1"
	fi
	if [ ! -w "$1" ]; then
		echo -ne "[!] Error can not write into: '$1'.\n"
		exit 1
	fi
}


func_config()
{ # returns: $output_mode, $target_dir, $output_dir, $tmp

		local library_dir

		# check system
	if [[ "$PREFIX" = *"com.termux"* ]]; then
		tmp="/sdcard/Android/media/tmp"
		library_dir="/sdcard/Android/media"
		_echo "func_config: operation date: $(date)\n${0}: func_config: running on host: termux-android\n" 1
	else
		tmp=~/tmp
		library_dir=~/
		_echo "func_config: operation date: $(date)\n${0}: func_config: running on host: Linux/GNU\n" 1
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
	elif [ -n "$target_dir" ] && [ "$output_mode" != "custom" ]; then
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
	if [ "$archive_mode" = "yes" ]; then
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

		_echo "func_config: target directory: '${target_dir}'\n" 1
		_echo "func_config: output directory: '${output_dir}'\n" 1
		_echo "func_config: output mode: '${output_mode}'\n" 1
		_echo "- - - - - - - - - - - - - - - - - - - -\n" nolog

}


func_stats()
{ # returns: null

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
		local total_skipped=$((total_files-total_apk))
		local total_rename_fails=$((mv_err1+mv_err2+mv_err3))
		echo -ne "[x] Total proccedd APK: ${total_apk}\n"
		echo -ne "[x] Total skipped none APK: ${total_skipped}\n"
		echo -ne "[x] Total successfully renamed (mv cmd): ${mv_err0}\n"
		echo -ne "[x] Total failed to rename (mv cmd): ${total_rename_fails}\n"
		_echo "[v] Total proccedd single-split: ${total_split}\n" nolog
		_echo "[v] Total proccedd combined-apk: ${total_combined}\n" nolog
		_echo "[v] Total failed to detect APK: ${total_unknown}\n" nolog
		_echo "[v] Total already renamed (mv cmd): ${mv_err2}\n" nolog
		_echo "[v] Total permission denied (mv cmd): ${mv_err3}\n" nolog
		_echo "[v] Total unknown error (mv cmd): ${mv_err1}\n" nolog

}


func_dup_rename()
{ # returns: null

		local label
		local suffix
		local library_dir
		local src
		local dst
		
		label="$1"
		suffix="$2"
		library_dir="$3"
		src="$4"
		dst="${library_dir}/${label}/${5}"
	if [ ! -d "$library_dir/${label}" ]; then
		func_mkdir "${library_dir}/${label}"
	fi
	

	#func_dup_rename "$label" "$suffix" "$output_dir/${category}" "$src_apk" "$final_name"
	# increasment rename (pain!)
	# the order are lost on repeat renaming with target APK-Library dir.
	local i=0
	while true; do
	local i=$((i+1))
		if [ "$i" -ge "21" ]; then
			_echo "func_dup_rename: skipping since 20 tries is reached: '${dst}.${suffix}'\n" 1
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


func_rename()
{ # returns: null

	local mv_src
	local mv_dst
	local src_file
	local dst_file
	local src_dir
	local dst_dir

	# mv error handling
	mv_src="$1"
	mv_dst="$2"
	src_file="${mv_src##*/}"
	dst_file="${mv_dst##*/}"
	src_dir="${mv_src%/*}"
	dst_dir="${mv_dst%/*}"
	
	# visual output
	echo -ne "[!] APK Location: '$src_dir'\n"
	echo -ne "[x] Output Location: '$dst_dir'\n"
	echo -ne "[!] Old name: '$src_file'\n"
	echo -ne "[x] New name: '$dst_file'\n"
	
	while read -r x; do
			_echo "func_rename: mv_cmd: ${x}\n" 2
		if [[ "$x" = "renamed "* ]]; then
			mv_err0=$((mv_err0+1))
			_echo "func_rename: mv_err0: $x\n" 2
		elif [[ "$x" = *"are the same file"* ]] || [[ "$x" = *"Skipping overwritting"* ]]; then
			mv_err2=$((mv_err2+1))
			_echo "func_rename: mv_err2: $x\n" 2
		elif [[ "$x" = *"Operation not permitted"* ]]; then
			mv_err3=$((mv_err3+1))
			_echo "func_rename: mv_err3: $x\n" 2
		else
			mv_err1=$((mv_err1+1))
			_echo "func_rename: mv_err1: $x\n" 2
		fi
	done< <( if [ -s "$mv_dst" ]; then _echo "func_rename: skipping overwritting: '$mv_dst'\n" 2; else mv -v "$mv_src" "$mv_dst" 2>&1; fi)

}


func_get_sdkver()
{ # returns: $min_sdk, $max_sdk

	local min_sdk
	local max_sdk
	min_sdk="$1"
	max_sdk="$2"

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
			min_ver="android-$(echo -n "$sdk" | sed 's/.*=//')"
		elif [[ "$sdk" = "sdk${max_sdk}"* ]]; then
			max_ver="android-$(echo -n "$sdk" | sed 's/.*=//')"
		fi
	done
			# if no ver found !
		if [ -z "$min_ver" ]; then
			min_ver="sdk${min_sdk}"
		elif [ -z "$max_ver" ]; then
			max_ver="sdk${max_sdk}"
		fi

}


func_signtrue_check()
{ # returns: signture, stamp

		local x; x="$1"
		_echo "func_process_apk: checking the signature: '$x'\n" 2
		#cert="$(unzip -lqq "$x" | grep -E "\.RSA|\.DSA")"
		signature="$(grep -Fcm1 "android@android.com" "$x")"
	if [ -n "$cert" ]; then
		signature="$(unzip -pqq "$x" "$cert" | grep -Fcm1 "android@android.com")"
	else
		signature="$(grep -Fcm1 "android@android.com" "$x")"
	fi
	if [ "$signature" = "1" ]; then
		#stamp="$(md5 "$x" | awk '{print $2}')"
		stamp="modified"
		_echo "func_process_apk: detected signature: 'Android Debug'\n" 2
	else
		stamp="vertified"
		_echo "func_process_apk: detected signature: 'Private'\n" 2
	fi

}


func_detect_category()
{ # returns: $category
		
		# determine category (need improve !)
		local x
		local src
		local list
		local f
		x="$1"
		src="$2"

	if [ "$archive_mode" = "yes" ]; then
			_echo "func_detect_category: detecting category target: '$x' source: '$src'\n" 2
			list="$(unzip -l "$x" lib/* -- *.dex AndroidManifest.xml -- *xposed_init* | sed '/Name/d; /----/d; /Archive: /d' | awk '{print $4}' | tr '\n' ' ')"
				if [ -z "$(echo -n $list | tr -d ' ')" ]; then
					list="null"
					_echo "func_detect_category: possibly invalid apk: 'null' for: '$src'\n" 2
					return 1
				fi
			_echo "func_detect_category: found files: '$list' inside: '$src'\n" 2
		for i in $list; do
				# apparently most apps unnecessary includes getObbDir, should we blame androidSDK for that?
				#result="$(unzip -pqq "$x" "$t" | grep -cao "getObbDir.[^s]")" # look for dir(X) but not dir(s), getObbDir and getObbDirs are totally different. matching libs(.so) are accurate but not for .dex !
				f="${i##*/}"
			if [ "$f" = "libunity.so" ] || [ "$f" = "libUE4.so" ]; then
				category="APK-Games"
				_echo "func_detect_category: found (libunity.so/libUE4.so) in target: '$x' of: '$src'\n" 2
				break
			elif [ "$f" = "xposed_init" ]; then
				category="Xposed-Apps"
				_echo "func_detect_category: found (xposed_init) in target: '$x' of: '$src'\n" 2
				break
			elif [ "$f" = "AndroidManifest.xml" ]; then
							# shipping axmldec binary may considered in feature
							# androidSDK provides an atttibute in manifest which can declare the app category.
							# however many apps perfers to not use this attribute and instead rely on PlayStore scheme (domains ids?).
							r="$(unzip -pqq "$x" "$f" | tr -d "\0" | grep -Eoc "category\.GAME|android\.hardware\.gamepad|com\.google\.android\.gms\.games\.APP_ID|com\.facebook\.unity\.FBUnityGameRequestActivity")"
						if [ "$r" -ge "1" ]; then
							category="APK-Games"
							_echo "func_detect_category: found (possbile game attribute) in target: '$x' of: '$src'\n" 2
							break
						fi
							r="$(unzip -pqq "$x" "$f" | tr -d "\0" | grep -Eoc "android\.permission\.WRITE_MEDIA_STORAGE|android\.permission\.WRITE_EXTERNAL_STORAGE|android\.permission\.MANAGE_EXTERNAL_STORAGE")"
						if [ "$r" -ge "1" ]; then
							category="File-Managers"
							_echo "func_detect_category: found (possible file-manager attribute) in target: '$x' of: '$src'\n" 2
							break
						fi
						category="Other-Apps"
						_echo "func_detect_category: could not detect category for target: '$x' of: '$src'\n" 2
			fi
		done
	fi
}


func_parse_arch()
{ # returns: native_arch

		native_arch="$(echo -n "$1" | grep -iE "x86|arm|mips" | awk -F 'config.' '{print $2}' | sort | uniq -c | awk '{print $2}' | tr -d " \n" | sed 's/\.apk//g')"
		#local native_arch="$(echo -ne -- "$file_content" | grep -iE "x86|arm|mips" | awk -F 'config.' '{print $2}' | sort | uniq -c | awk '{print $2}' | tr -d " \n" | sed 's/\.apk//g; s/aarm/a+arm/g; s/abia/abi+a/g; s/ax86/a+x86/g; s/x86x86/x86+x86/g')"
		if [ -z "$native_arch" ]; then
			native_arch="NoNative"
		fi
		_echo "func_parse_arch: native arch: '$native_arch'\n" 2

}


func_extract_apk()
{ # returns: null

		local mode
		local x
		local c
		
		mode="$1"
		x="$2"
		c="$3"
	if [ "$mode" = "main" ]; then
		local t="$(echo -n "$c" | grep -F ".apk")"
		_echo "func_extract_apk: extracting main APK: '$t'\n" 2
		_echo "func_extract_apk: extracting as: '${tmp}/base.apk'\n" 2
		unzip -pqq "$x" "$t">"${tmp}/base.apk" 2>"${tmp}/err"
		_iferr "func_extract_apk: failed extracting (unzip_main): ${t}" 2
		_echo "func_extract_apk: moving unneedeed file: '$x' into: '${tmp}/base_bak.apk'\n" 2
		mv --backup=t "$x" "$tmp/base_bak.apk"
	elif [ "$mode" = "base" ]; then
		_echo "func_extract_apk: extracting base APK: '$c'\n" 2
		_echo "func_extract_apk: extracting as: '${tmp}/base.apk'\n" 2
		unzip -pqq "$x" "$c">"${tmp}/base.apk" 2>"${tmp}/err"
		_iferr "func_extract_apk: failed extracting (unzip_base): ${c}"
	elif [ "$mode" = "obb" ]; then
		#local t="$(echo -ne -- "$c" | grep -vF ".obb")"
		_echo "func_extract_apk: extracting combined APK: '$c'\n" 2
		_echo "func_extract_apk: extracting as: '${tmp}/base.apk'\n" 2
		unzip -pqq "$x" "$c">"${tmp}/base.apk" 2>"${tmp}/err"
		_iferr "func_extract_apk: failed extracting (unzip_obb): ${c}"
	fi
}


func_process_apk()
{ # returns: null

		local check_zip
		local void
		local file_content
		local file_content2
		local manifest

		_echo "func_process_apk: checking file type: '${1}'\n" 1
		check_zip="$(file "${1}")"
	if [[ "$check_zip" != *"Zip archive"* ]]; then
		if [[ "$check_zip" != *"Android package"* ]]; then
			if [[ "$check_zip" != *" Java archive"* ]]; then
				_echo "func_process_apk: skipping since it is not zip nor apk or even a jar: '${1}'\n" 0
				return 1
			fi
		fi
	fi

		_echo "func_process_apk: processing possible apk: '${1}'\n" 2

		# determine apk type
		_echo "func_process_apk: getting file contents..\n" 2
		file_content="$(unzip -lqq "$1" 2>"${tmp}/err" | grep -E "\.apk|resources.arsc|\.RSA|\.DSA|\.obb" | awk '{print $4}')"
	if [ -s "${tmp}/err" ]; then
		_echo "func_process_apk: skipping possibly damaged zipfile: '${1}'\n" 2
		return 1
	fi
		void="$(echo -n "${file_content}" | tr '\n' ' ')"
		_echo "func_process_apk: file contents: '${void}'\n" 2
		
		file_content2="$(echo -n "$file_content" | grep -E "\.apk|resources.arsc" | grep -ivE "archive:|assets/|config\..*\.apk|split_.*\.apk|.*/.*\.apk")"
		_echo "func_process_apk: file contents (filtered): '${file_content2}'\n" 2
		
		# idenify if single-split
		manifest=$(aapt d badging "$1")

	if [ "$(echo -n "$manifest" | grep -ocm1 "split='.*'")" = "1" ]; then
		local multi_bundle
		local split_name
		_echo "func_process_apk: target type: Single-Split\n" 2
		multi_bundle="yes"
		split_name=$(echo "$manifest" | grep -Po "(?<=split=')(.+?)(?=')")
		func_rename "$1" "$output_dir/$split_name.apk"
		total_split=$((total_split+1))
		#func_detect_category "$1" "$src_apk"
		return 0
	elif [ "$(echo -n "$file_content" | grep -Fcm1 ".obb")" = "1" ]; then
		local multi_bundle
		local native_arch
		local suffix
		local x
		local src_apk
		_echo "func_process_apk: target type: OBB-Combined\n" 2
		multi_bundle="yes"
		native_arch=""
		suffix="apkm"
		native_arch=""
			if ! func_extract_apk "obb" "$1" "$file_content2"; then
				return
			fi
		x="${tmp}/base.apk"
		src_apk="$1"
		total_combined=$((total_combined+1))
		func_detect_category "$x" "$src_apk"
	elif [[ "$file_content2" = *"resources.arsc"* ]]; then
		local multi_bundle
		local native_arch
		local suffix
		local x
		local src_apk
		_echo "func_process_apk: target type: APK\n" 2
		multi_bundle="no"
		native_arch=""
		suffix="apk"
		x="$1"
		src_apk="$1"
		func_detect_category "$x" "$src_apk"
	elif [ "$(echo -n "$file_content" | grep -ocF ".apk")" = "1" ]; then
		local multi_bundle
		local native_arch
		local suffix
		local x
		local src_apk
		_echo "func_process_apk: target type: APK\n" 2
		multi_bundle="no"
		native_arch=""
		suffix="apk"
			if ! func_extract_apk "main" "$1" "$file_content"; then
				return
			fi
		x="${tmp}/base.apk"
		src_apk="${tmp}/base.apk"
		func_detect_category "$x" "$src_apk"
	elif [[ "$file_content2" = *".apk"* ]]; then
		local multi_bundle
		local native_arch
		local suffix
		local x
		local src_apk
		_echo "func_process_apk: target type: Multi-Bundle\n" 2
		multi_bundle="yes"
		suffix="apks"
		func_parse_arch "$file_content"
			if ! func_extract_apk "base" "$1" "$file_content2"; then
				return
			fi
		x="${tmp}/base.apk"
		src_apk="$1"
		func_detect_category "$x" "$src_apk"
	else
		_echo "func_process_apk: faild to detect APK type of: '$1'\n" 0
		total_unknown=$((total_unknown+1))
		return 1
	fi
		total_apk=$((total_apk+1))

		# parsing time
		local label
		local package_name
		local version_code
		local version_name
		local min_sdk
		local max_sdk
		
		manifest=$(aapt d badging "$x")
		label=$(echo "$manifest" | grep -Po "(?<=application: label=')(.+?)(?=')")
			if [ -z "$label" ]; then
				label=$(echo "$manifest" | grep -Po "(?<=application-label:')(.+?)(?=')")
			fi
		package_name=$(echo "$manifest" | grep -Po "(?<=package: name=')(.+?)(?=')")
			if [ "$generate_ids" = "yes" ]; then
				echo "- [x] Saving package name: '$package_name'"
				echo "$package_name">>"$tmp/ids.log"
				_echo "func_process_apk: saved package name: '$package_name' into: '$tmp/ids.log'" 0
				return 0
			fi
		version_code=$(echo "$manifest" | grep -Po "(?<=versionCode=')(.+?)(?=')")
		version_name=$(echo "$manifest" | grep -Po "(?<=versionName=')(.+?)(?=')")
		min_sdk=$(echo "$manifest" | grep -Po "(?<=sdkVersion:')(.+?)(?=')")
		max_sdk=$(echo "$manifest" | grep -Po "(?<=targetSdkVersion:')(.+?)(?=')")
		func_get_sdkver "$min_sdk" "$max_sdk"
	if [ "$multi_bundle" = "no" ]; then
				native_arch="$(echo "$manifest" | grep -Po "(?<=native-code: ')(.*)")"
			if [ -z "$native_arch" ]; then
				native_arch="NoNative"
			fi
	fi

		# signtrue check
		func_signtrue_check "$x"

	# combine stage
		local pattern_name
		local final_name
		pattern_name="${label}_(v${version_name}-${version_code}_${stamp})_(${package_name}_${min_ver}+${max_ver}_${native_arch})"
		_echo "func_process_apk: generated name: '$pattern_name'\n" 2
		pattern_name="$(echo -n "$pattern_name" | tr -d '/\\' | sed "s/alt\-native\-code: '//; s/' '/+/g; s/armeabi/arm/g; s/-v/_v/g; s/: //g; s/icon=//g; s/split=//g" | tr -d ":'" | tr " " "+")"
		_echo "func_process_apk: generated name (filtered): '$pattern_name'\n" 2
	if [ "$archive_mode" = "yes" ]; then
		final_name="${pattern_name}"
		_echo "func_process_apk: label name: '$label'\n" 2
		label="$(echo -n "$label" | sed "s/: //g; s/\./-/g; s/\&/and/g")"
		_echo "func_process_apk: label name (filtered): '$label'\n" 2
		func_dup_rename "$label" "$suffix" "$output_dir/${category}" "$src_apk" "$final_name"
	else
		final_name="${pattern_name}.${suffix}"
		func_rename "$src_apk" "$output_dir/${category}/$final_name"
	fi
	echo
	_echo "- - - - - - - - - - - - - - - - - - - -\n" nolog
	echo

}


func_find_apk()
{ # returns: $f, $total_apk, $total_files

	# index func_stats
		local total_files
		total_files="0"
		total_apk="0"

	# find apk
	while read -r f; do
		if [ -f "$f" ] && [ -s "$f" ]; then
			total_files=$((total_files+1))
			if [ "$output_mode" = "dynamic" ]; then
				output_dir="${f%/*}"
			fi
				func_process_apk "$f"
		else
			_echo "func_find_apk: skipping none/empty file: '${f}'\n" 0
		fi
	done< <( find "$target_dir" -type f )
	if [ "$total_files" != "0" ]; then
		func_stats
	else
		echo -ne "[!] The target directory is empty: '${target_dir}'\n"
		exit 0
	fi

}


		func_deps
		func_getargs "$@"
		func_config
		func_find_apk
	if [ "$archive_mode" = "yes" ] && [ "$clean_mode" = "yes" ]; then
		echo "[x] Cleaning-up Library directory: '$output_dir' "
		find "$output_dir" -mindepth 1 -type d -empty -delete
	fi
