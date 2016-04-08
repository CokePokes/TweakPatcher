#!/bin/bash

COMMAND=$1
TWEAK=$2
IPA=$3
MOBILEPROVISION=$4
PATCHO="./bin/patcho"
IOSDEPLOY="./bin/ios-deploy"
OPTOOL="./bin/optool"
WORK_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TMP_DIR=".temp"
BIGBOSS_REPO="http://files11.thebigboss.org/repofiles/cydia/debs2.0/"
LIBROCKETBOOTSTRAP_DEB="com.rpetrich.rocketbootstrap_1.0.4_iphoneos-arm.deb"
UASHAREDTOOLS_DEB="uasharedtools_2.0r-46.deb"
SNAPPLUS_DEB="appplusforsnapchat_1.5r-86.deb"
DEV_CERT_NAME="iPhone Developer"
CODESIGN_NAME=`security dump-keychain login.keychain|grep "$DEV_CERT_NAME"|head -n1|cut -f4 -d \"|cut -f1 -d\"`
SUFFIX="-"$(uuidgen)
LOGFILE=tweakpatcher.log

echo "[👻 ] Tweak Patcher for jailed iOS devices v0.1"
echo "[🔌 ] by Defying / @dvfying"
echo "[💻 ] GitHub: https://github.com/Defying/TweakPatcher"
echo ""

rm -rf $TMP_DIR/
mkdir -p $TMP_DIR/
rm $LOGFILE >& /dev/null

function usage {
	if [ "$2" == "" -o "$1" == "" ]; then
		cat <<USAGE
Syntax: $0 patch snapplus /path/to/decrypted.ipa <BUNDLE_ID>

SnapPlus for Snapchat is currently the only supported tweak.
More tweaks may be added in the future.
USAGE
	fi
}

function getDependencies {
	echo "[💯 ] Checking for required dependencies..."
  mkdir -p bin/

	if [ ! -f $OPTOOL ] || [ ! -f $IOSDEPLOY ] || [ ! -f $PATCHO ]; then
		if [ ! -f $IOSDEPLOY ]; then
	      echo "[📥 ] ios-deploy not found, downloading..."
	      cd $TMP_DIR
	  		curl -L https://github.com/phonegap/ios-deploy/archive/1.8.5.zip -o ios-deploy.zip >> $LOGFILE 2>&1
	      echo "[📦 ] extract: ios-deploy"
	  		unzip ios-deploy.zip >> $LOGFILE 2>&1
	  		rm ios-deploy.zip
	  		cd ios-deploy-*
	      echo "[🔨 ] build: ios-deploy"
	  		xcodebuild >> $LOGFILE 2>&1
				if [ "$?" != "0" ]; then
					echo ""
					echo "[⚠️ ] Failed to build ios-deploy"
					exit 1
				fi
	  		cd $WORK_DIR
	  		mv $TMP_DIR/ios-deploy-*/build/Release/ios-deploy $IOSDEPLOY
	      echo "[👍 ] done: ios-deploy"
	  fi
		if [ ! -f $OPTOOL ]; then
	      echo "[📥 ] optool not found, downloading..."
	      cd $TMP_DIR
	  		curl -L https://github.com/alexzielenski/optool/releases/download/0.1/optool.zip -o optool.zip >> $LOGFILE 2>&1
	  		echo "[📦 ] extract: optool"
	  		unzip optool.zip >> $LOGFILE 2>&1
	      cd $WORK_DIR
	      mv $TMP_DIR/optool $OPTOOL
	      echo "[👍 ] done: optool"
		fi
		if [ ! -f $PATCHO ]; then
	      echo "[📥 ] patcho not found, downloading..."
	      cd $TMP_DIR
	      curl https://ghostbin.com/paste/ejjej/raw -o main.c >> $LOGFILE 2>&1 # original: http://www.tonymacx86.com/general-help/86205-patcho-simple-hex-binary-patcher.html
	      echo "[🔨 ] build: patcho"
	      gcc main.c -o patcho
				if [ "$?" != "0" ]; then
					echo ""
					echo "[⚠️ ] Failed to build patcho"
					exit 1
				fi
	      cd $WORK_DIR
	      mv $TMP_DIR/patcho $PATCHO
	      echo "[👍 ] done: patcho"
	  fi
		echo "[👍 ] All missing dependencies obtained."
		echo ""
	else
		echo "[👍 ] All dependencies found."
		echo ""
	fi
  rm -rf $TMP_DIR/*
}

function detectDevice {
	# detect attached iOS device
	echo "[📱 ] Waiting up to 5 seconds to detect an iOS device.."
	$IOSDEPLOY -c >> $LOGFILE 2>&1
	if [ "$?" != "0" ]; then
		echo "[❌ ] No iOS devices detected. Are you sure your device is plugged in?"
		exit 1
	else
		echo "[👍 ] Detected an iOS device!"
		echo ""
	fi
}

function downloadSnapPlus {
  echo "[💯 ] Downloading dependencies for SnapPlus..."
  rm patch/lib* >> $LOGFILE 2>&1
  rm -rf patch/AppPlus*
  echo "[📥 ] Downloading librocketbootstrap"
  rm -rf $TMP_DIR/* >> $LOGFILE 2>&1
  cd $TMP_DIR/
  curl $BIGBOSS_REPO$LIBROCKETBOOTSTRAP_DEB -o $LIBROCKETBOOTSTRAP_DEB >> $LOGFILE 2>&1
  echo "[📦 ] Extracting librocketbootstrap"
  ar -x $LIBROCKETBOOTSTRAP_DEB data.tar.gz >> $LOGFILE 2>&1
  tar -xvf data.tar.gz usr/lib/librocketbootstrap.dylib >> $LOGFILE 2>&1
  mv usr/lib/librocketbootstrap.dylib $WORK_DIR/patch/librocketb.dylib
  rm -r * >> $LOGFILE 2>&1
  echo "[📥 ] Downloading libuasharedtools"
  curl $BIGBOSS_REPO$UASHAREDTOOLS_DEB -o $UASHAREDTOOLS_DEB >> $LOGFILE 2>&1
  echo "[📦 ] Extracting libuasharedtools"
  ar -x $UASHAREDTOOLS_DEB data.tar.lzma >> $LOGFILE 2>&1
  tar -xvf data.tar.lzma usr/lib/* >> $LOGFILE 2>&1
  mv usr/lib/libuasharedtools.dylib usr/lib/libuasht.dylib
  mv usr/lib/* $WORK_DIR/patch/
  rm -r * >> $LOGFILE 2>&1
  echo "[📥 ] Downloading SnapPlus"
  curl $BIGBOSS_REPO$SNAPPLUS_DEB -o $SNAPPLUS_DEB >> $LOGFILE 2>&1
  echo "[📦 ] Extracting SnapPlus"
  ar -x $SNAPPLUS_DEB data.tar.lzma
  tar -xvf data.tar.lzma Library/MobileSubstrate/DynamicLibraries/AppPlus.dylib Library/Application\ Support/* >> $LOGFILE 2>&1
  mv Library/MobileSubstrate/DynamicLibraries/AppPlus.dylib $WORK_DIR/patch/
  mv Library/Application\ Support/AppPlusSC $WORK_DIR/patch
  rm -r * >> $LOGFILE 2>&1
  cd $WORK_DIR
	rm -rf $TMP_DIR/*
  echo "[👍 ] Done."
  echo ""
}

function patchSnapPlusDylibs {
	echo "[💯 ] Begin patching..."
  echo "[💉 ] Patching librocketbootstrap"
  DYLIB=librocketb.dylib
  # /usr/lib/libsubstrate.dylibb -> @executable_path/cydiasubst
  $PATCHO 2F7573722F6C69622F6C69627375627374726174652E64796C6962 4065786563757461626C655F706174682F63796469617375627374 patch/$DYLIB >> $LOGFILE 2>&1
  echo "[💉 ] Patching libuasharedtools"
  DYLIB=libuasht.dylib
  # /Library/Frameworks/CydiaSub -> @executable_path/cydiasubst 
  $PATCHO 2F4C6962726172792F4672616D65776F726B732F4379646961537562 4065786563757461626C655F706174682F6379646961737562737400 patch/$DYLIB >> $LOGFILE 2>&1
  echo "[💉 ] Patching SnapPlus"
  DYLIB=AppPlus.dylib
  # /usr/lib/librocketbootstrap.dylib -> @executable_path/librocketb.dylib
  $PATCHO 2F7573722F6C69622F6C6962726F636B6574626F6F7473747261702E64796C6962 4065786563757461626C655F706174682F6C6962726F636B6574622E64796C6962 patch/$DYLIB >> $LOGFILE 2>&1
  # /usr/lib/libuasharedtools.dylib -> @executable_path/libuasht.dylib
  $PATCHO 2F7573722F6C69622F6C69627561736861726564746F6F6C732E64796C6962 4065786563757461626C655F706174682F6C696275617368742E64796C6962 patch/$DYLIB >> $LOGFILE 2>&1
  # /Library/Frameworks/CydiaSub -> @executable_path/cydiasubst 
  $PATCHO 2F4C6962726172792F4672616D65776F726B732F4379646961537562 4065786563757461626C655F706174682F6379646961737562737400 patch/$DYLIB >> $LOGFILE 2>&1
  # %s: WARNING: |-addAssetsGroupAlbumWithName:resultBlock:failureBlock:|               only avai -> /var/mobile/Containers/Data/Application/YOURUDID-HERE-YOUR-UDID-HEREYOURUDID/Documents/%@/%@ 
  $PATCHO 25733A205741524E494E473A207C2D61646441737365747347726F7570416C62756D576974684E616D653A726573756C74426C6F636B3A6661696C757265426C6F636B3A7C2020202020202020202020202020206F6E6C792061766169 2F7661722F6D6F62696C652F436F6E7461696E6572732F446174612F4170706C69636174696F6E2F594F5552554449442D484552452D594F55522D554449442D48455245594F5552554449442F446F63756D656E74732F25402F254000 patch/$DYLIB >> $LOGFILE 2>&1
  # change reference to APResources.bundle path string / ARMv7 specific (32-bit)
  $PATCHO 3DA11C0022 87021D005C patch/$DYLIB >> $LOGFILE 2>&1
  # change reference to APResources.bundle path string / ARM64 specific (64-bit)
  $PATCHO FD9D1E000000000022 6BFF1E00000000005C patch/$DYLIB >> $LOGFILE 2>&1
  echo "[👍 ] Done."
	echo ""
}

function getProvisioningProfile {
	if [ "$MOBILEPROVISION" != "" ]; then
		echo "[ℹ️ ] Skipping Xcode project creation prompt, $MOBILEPROVISION will be used instead."
	else
		MOBILEPROVISION="com.toyopagroup.picaboo$SUFFIX"
		cat <<XCODEPROFILE
[💯 ] Create a new project in Xcode with these details:

Product Name: picaboo$SUFFIX
Organization Identifier: com.toyopagroup

Once the project has been created, select your iOS device in the top left, then select "Fix Issue". This will generate the provisioning profile.

XCODEPROFILE
	fi
  echo "[💯 ] Waiting on $MOBILEPROVISION provisioning profile to be created..."
	while true; do
		grep -rn ~/Library/MobileDevice/Provisioning\ Profiles -e "$MOBILEPROVISION" | grep "matches" >> $LOGFILE 2>&1
		if [ $? -eq 0 ]; then
			echo "[💯 ] Found a matching provisioning profile for $MOBILEPROVISION!"
			break
		fi
		sleep 1
	done
}

function patchAndInstallIPA {
	# credits to https://github.com/andugu/ScreenChat for this patching code

	if [ ! -r "$IPA" ]; then
		echo "[❌ ] $IPA not found or not readable"
		exit 1
	fi

	# setup
	rm -rf "$TMP_DIR" >/dev/null 2>&1
	mkdir "$TMP_DIR"

	# uncompress the IPA into TMP_DIR
	echo ""
	echo '[📦 ] Unpacking the .ipa file ('"$IPA"')'
	unzip -o -d "$TMP_DIR" "$IPA" >> $LOGFILE 2>&1
	if [ "$?" != "0" ]; then
		echo "[❌ ] Couldn't unzip the IPA file. Check $LOGFILE for more information."
		exit 1
	fi
	cd "$TMP_DIR"
	cd Payload/*.app
	if [ "$?" != "0" ]; then
		echo "[❌ ] Couldn't change into Payload folder. Wat."
    echo ""
		exit 1
	fi

	APP=`pwd`
	APP=${APP##*/}
	APPDIR=$TMP_DIR/Payload/$APP
	cd "$WORK_DIR"
	BUNDLE_ID=`plutil -convert xml1 -o - $APPDIR/Info.plist|grep -A1 CFBundleIdentifier|tail -n1|cut -f2 -d\>|cut -f1 -d\<`$SUFFIX
	APP_BINARY=`plutil -convert xml1 -o - $APPDIR/Info.plist|grep -A1 Exec|tail -n1|cut -f2 -d\>|cut -f1 -d\<`

	file "$APPDIR/$APP_BINARY" | grep "universal binary" 2>/dev/null 1>&2
	if [ "$?" == "0" ]; then
		lipo "$APPDIR/$APP_BINARY" -thin armv7 -output "$APPDIR/$APP_BINARY".new
		cp "$APPDIR/$APP_BINARY".new "$APPDIR/$APP_BINARY"
		rm -f "$APPDIR/$APP_BINARY".new
	fi
	if [ "$MOBILEPROVISION" == "" ]; then
		usage
		exit 1
	fi

	# File can't be read (try making it)
	if [ ! -r "$MOBILEPROVISION" ]; then
		# found one
		if (( `grep -rn ~/Library/MobileDevice/Provisioning\ Profiles -e "$MOBILEPROVISION" | wc -l` > 0)); then
			echo '[➡️ ] Copying provision from provided Bundle ID'
			cp "`grep -rn ~/Library/MobileDevice/Provisioning\ Profiles -e "$MOBILEPROVISION" | sed -e "s|Binary file \(.*\) matches|\1|"`" ".provision.mobileprovision"
			PATCH_MOBILEPROVISION=`pwd`"/.provision.mobileprovision"

			if [ ! -r "$PATCH_MOBILEPROVISION" ]; then
				echo "[❌ ] Can't read $MOBILEPROVISION"
				exit 1
			fi
		else # didn't find one
			echo "[❌ ] Can't read $MOBILEPROVISION"
			exit 1
		fi
	fi

	# copy the files into the .app folder (theos-jailed dependencies)
	echo '[➡️ ] Copying .dylib dependencies into "'$TMP_DIR/Payload/$APP'"'
	cp -r patch/*.dylib $TMP_DIR/Payload/$APP/
	cp patch/cydiasubst $TMP_DIR/Payload/$APP/

	cp "$PATCH_MOBILEPROVISION" "$TMP_DIR/Payload/$APP/embedded.mobileprovision"

	echo '[✒️ ] Codesigning .dylib dependencies with certificate "'$CODESIGN_NAME'"'
	find -d $TMP_DIR/Payload/$APP  \( -name "*.app" -o -name "*.appex" -o -name "*.framework" -o -name "*.dylib" -o -name "*cydiasubst" -o -name "$DYLIB" \) > .directories.txt
	security cms -D -i "$TMP_DIR/Payload/$APP/embedded.mobileprovision" > .t_entitlements_full.plist
	/usr/libexec/PlistBuddy -x -c 'Print:Entitlements' .t_entitlements_full.plist > .t_entitlements.plist
	while IFS='' read -r line || [[ -n "$line" ]]; do
	  /usr/bin/codesign --continue -f -s "$CODESIGN_NAME" --entitlements ".t_entitlements.plist"  "$line" >> $LOGFILE 2>&1
	done < .directories.txt

	# patch the app to load the new .dylib (sames a _backup file)
	echo '[💉 ] Patching "'$APPDIR/$APP_BINARY'" to load dependencies...'
	if [ "$?" != "0" ]; then
		echo "[❌ ] Failed to grab executable name from Info.plist. Debugging required."
		exit 1
	fi

	$OPTOOL install -c load -p "@executable_path/"librocketb.dylib -t $APPDIR/$APP_BINARY >> $LOGFILE 2>&1
	$OPTOOL install -c load -p "@executable_path/"libuasharedanaltyics.dylib -t $APPDIR/$APP_BINARY >> $LOGFILE 2>&1
	$OPTOOL install -c load -p "@executable_path/"libuasht.dylib -t $APPDIR/$APP_BINARY >> $LOGFILE 2>&1
	$OPTOOL install -c load -p "@executable_path/"libuasharedcrashreport.dylib -t $APPDIR/$APP_BINARY >> $LOGFILE 2>&1
	$OPTOOL install -c load -p "@executable_path/"DocsDylibLoader.dylib -t $APPDIR/$APP_BINARY >> $LOGFILE 2>&1

	if [ "$?" != "0" ]; then
		echo "[❌ ] Failed to inject dylibs into $APPDIR/${APP_BINARY}. Check $LOGFILE for more information."
		exit 1
	fi

	chmod +x "$APPDIR/$APP_BINARY"

	# Make sure to sign any Plugins in the app. Do NOT attempt to optimize this, the order is important!
	echo '[✒️ ] Codesigning Plugins and Frameworks with certificate "'$CODESIGN_NAME'"'
	for file in `ls -1 $APPDIR/PlugIns/com.*/com.*  >> $LOGFILE 2>&1`; do
		echo -n '     '
		codesign -fs "$CODESIGN_NAME" --deep --entitlements .t_entitlements.plist $file
	done
	for file in `ls -d1 $APPDIR/PlugIns/com.* >> $LOGFILE 2>&1`; do
		echo -n '     '
		codesign -fs "$CODESIGN_NAME" --deep --entitlements .t_entitlements.plist $file
	done

	# re-sign Frameworks, too
	for file in `ls -1 $APPDIR/Frameworks/* >> $LOGFILE 2>&1`; do
		echo -n '     '
		codesign -fs "$CODESIGN_NAME" --entitlements .t_entitlements.plist $file
	done

	# re-sign the app
	echo '[✒️ ] Codesigning the patched .app bundle with certificate "'$CODESIGN_NAME'"'
	cd $TMP_DIR/Payload

	codesign -fs "$CODESIGN_NAME" --deep --entitlements ../../.t_entitlements.plist $APP >> $LOGFILE 2>&1
	if [ "$?" != "0" ]; then
		cd ..
		echo "[❌ ] Failed to sign $APP with entitlements.xml. Check $LOGFILE for more information."
		exit 1
	fi
	cd ..

	rm ../.directories.txt
	rm ../.t_entitlements.plist
	rm ../.t_entitlements_full.plist

	# re-pack the .ipa
	echo '[📦 ] Repacking the .ipa'
	rm -f "$TWEAK-patched.ipa" >> $LOGFILE 2>&1
	zip -qry "$TWEAK-patched.ipa" Payload/ >> $LOGFILE 2>&1
	if [ "$?" != "0" ]; then
		echo "[❌ ] Failed to compress the app into an .ipa file."
		exit 1
	fi

	mv "$TWEAK-patched.ipa" ..
	echo "[👍 ] Successfully packed \"$TWEAK-patched.ipa\""
	echo ""
	cd ..
	rm .provision.mobileprovision
	rm -rf $TMP_DIR/*

	echo "[📲 ] Installing $TWEAK-patched.ipa to iOS device"
  $IOSDEPLOY -b $TWEAK-patched.ipa >> $LOGFILE 2>&1
	if [ "$?" != "0" ]; then
		echo ""
		echo "[❌ ] Failed to install $IPA to iOS device. Check $LOGFILE for more information."
		exit 1
	fi
}

function snapPlusFinalSteps {
	echo ""
	echo "[📱 ] Open Snapchat on your iOS device!"
	echo "You may need to "Trust" your Apple ID in Settings/General/Device Management."
  read -p "Once Snapchat is open, press Enter."
	echo ""
  echo "[🔎 ] Finding Container UUID"
	$IOSDEPLOY --download=/Documents/container-uuid -1 'com.toyopagroup.picaboo' -2 ./ >> $LOGFILE 2>&1
	if [ "$?" != "0" ]; then
		echo "[❌ ] Failed to download Container UUID from device. Check $LOGFILE for more information."
		exit 1
	fi
  SNAPCHAT_UUID=$(cat Documents/container-uuid)
	SNAPCHAT_UUID_HEX=$(xxd -pu Documents/container-uuid | tr -d '\n')
	echo "[🔎 ] Found Container UUID: $SNAPCHAT_UUID"
  echo "[💉 ] Patching AppPlus.dylib with new Container UUID"
	$PATCHO 594F5552554449442D484552452D594F55522D554449442D48455245594F555255444944 $SNAPCHAT_UUID_HEX patch/AppPlus.dylib >> $LOGFILE 2>&1
	if [ "$?" != "0" ]; then
		echo "[❌ ] Failed to patch AppPlus.dylib. Check $LOGFILE for more information."
		exit 1
	fi
	rm -r Documents/

  echo '[✒️ ] Codesigning AppPlus.dylib with "'$CODESIGN_NAME'"'
  codesign -f -v -s "$CODESIGN_NAME" patch/AppPlus.dylib >> $LOGFILE 2>&1
  if [ "$?" != "0" ]; then
		echo "[❌ ] Failed to sign AppPlus.dylib. Check $LOGFILE for more information."
		exit 1
	fi

  echo "[📲 ] Copying AppPlus.dylib to com.toyopagroup.picaboo/Documents"
	$IOSDEPLOY -1 'com.toyopagroup.picaboo' -o patch/AppPlus.dylib -2 Documents/AppPlus.dylib >> $LOGFILE 2>&1
	if [ "$?" != "0" ]; then
		echo "[❌ ] Failed to upload AppPlus.dylib. Check $LOGFILE for more information."
		exit 1
	fi

  echo "[📲 ] Copying AppPlusSC/APResources.bundle to com.toyopagroup.picaboo/Documents"
	$IOSDEPLOY -1 'com.toyopagroup.picaboo' -o patch/AppPlusSC/APResources.bundle -2 Documents/AppPlusSC/APResources.bundle >> $LOGFILE 2>&1
	if [ "$?" != "0" ]; then
		echo "[❌ ] Failed to upload AppPlusSC/APResources.bundle. Check $LOGFILE for more information."
		exit 1
	fi

  echo ""
  echo "[🎉 ] SnapPlus installed! Please force close and reopen Snapchat."
	echo
	echo "[♻️ ] If you ever want to run this patcher again for the same app/tweak,"
	echo "you can reuse the same provisioning profile to keep things clean."
	echo ""
	echo "Open ProvisioningProfile.txt for more information."
	echo "$MOBILEPROVISION" > ProvisioningProfile.txt
	echo "" >> ProvisioningProfile.txt
	echo "Example: ./tweakpatcher.sh $COMMAND $TWEAK $IPA $MOBILEPROVISION" >> ProvisioningProfile.txt
}

case $1 in
	patch)
	  getDependencies
		case $2 in
			snapplus)
				detectDevice
				downloadSnapPlus
				patchSnapPlusDylibs
				getProvisioningProfile
				patchAndInstallIPA
				snapPlusFinalSteps
				;;
			*)
				usage
				exit 1
				;;
		esac
		;;
	*)
		usage
		exit 1
		;;
esac
