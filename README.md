# APK Sorter
## Mange APK/APKs etc.. and make them more recognisable, by renaming them with their own identifiers.

### Features:

- Supports any APK format.
- Supports any language.
- Very safe on files.
- Detect category of APK.
- Detect signatrue of APK.
- Store various versions of same APK by creating a library.


### How to install:

**1. Install AAPT:**


- Linux:

```Bash
curl -L https://dl.google.com/android/repository/build-tools_r34-rc3-linux.zip -o ~/build-tools.zip
unzip -x ~/build-tools.zip aapt -d ~
rm ~/build-tools.zip
chmod +x ~/build-tools/aapt
sudo cp ~/build-tools/aapt /usr/bin/aapt
```


- macOS:

```Bash
curl -L https://dl.google.com/android/repository/build-tools_r34-rc3-macosx.zip -o ~/build-tools.zip
unzip -x ~/build-tools.zip aapt -d ~
rm ~/build-tools.zip
chmod +x ~/build-tools/aapt
sudo cp ~/build-tools/aapt /usr/bin/aapt
```

- Windows:

1. Install [MSYS2](https://www.msys2.org/wiki/MSYS2-installation/).
2. Download build-tools: `https://dl.google.com/android/repository/build-tools_r34-rc3-windows.zip`
3. Open downloaded archive and extract `aapt` into:
	`C:\msys2\usr\bin`


**2. Install depends:**

- Linux:

```Bash
apt-get update && apt install unzip
```

- macOS (brew):

```Bash
brew install unzip
```

- Windows (MSYS2):

```Bash
pacman -S unzip
```

- termux-android.

```Bash
pkg update && pkg install file unzip aapt -y
```

**3. Install APK-Sorter:**

```Bash
git clone https://github.com/mast3rz3ro/apksorter ~/apksorter/apksorter && chmod +x ~/apksorter/apksorter.sh && cp ~/apksorter/apksorter.sh "$PREFIX/bin/apksorter"
```

### How to use:

**Current parameters:**

```Bash
 Usage: apksorter [parameters]

 Parameters:   Description:
        -i      Input directory (place where to find APK).
        -o      Output directory (place to store APK after renamed).
        -a      Archive mode (store APK in more reliable way).
        -c      Clean empty dirs (only used with archive mode).
        -g      generate identifiers (used for db).
	
	# Note: by default apksorter renames apk into their own directory
	# however you can override this behaivor by using -o switch
```

**Examples:**

- Rename within any place where`input` directory exists.

```Bash
$ ls
input
$ apksorter
$ ls
input renamed
```

- Rename without creating the `input` directory:

```Bash
$ apksorter -i /some/folder
```
- Override the output directory:

```Bash
d$ apksorter -i /some/folder -o /some/other/newdir
```

- Archive APK in default directory of apk-sorter:
```Bash
$ apksorter -a -i /somedir/otherdir
  # Android: /sdcard/Android/media/APK-Library
  # Linux: ~/APK-Library
```

- Enable archive mode:

```Bash
$ apksorter -i /some/folder -o /some/other/newdir -a
```

- Enable verbosity mode:

```Bash
$ export verbose=yes

	# Note: To detect errors quickly see: "opertion.log" which is stored on ~tmp directory.
```

### Feature plans:

- Please keep note that the `apksorter` must remain efficient, lightwight and simple.
and by lightwight I mean to not use any heavy size external tools such as `apksigner` which relies on `jdk`.

- [ ] Improve signatrue detection.
- [ ] Improve category detection.
- [ ] json file for categories  
- [ ] Add workaround to identify & repack Split-APK folder.
- [ ] Add repack feature.

### Reference:

- Android SDK: https://androidsdkoffline.blogspot.com/p/android-sdk-build-tools.html
