#!/bin/bash -e

PLISTBUDDY="/usr/libexec/PlistBuddy"
INFO_PLIST="$1"

if [ ! -f "$INFO_PLIST" ]; then
	echo "ERROR: plist file not found!"
	echo ""
	exit 1
fi

BUNDLEID=$($PLISTBUDDY -c "Print :CFBundleIdentifier" "$INFO_PLIST")
VERSION=$($PLISTBUDDY -c "Print :CFBundleVersion" "$INFO_PLIST" )

echo "Set CFBundleVersion to $VERSION.$CI_PIPELINE_ID"

$PLISTBUDDY -c "Delete :CFBundleVersion" "$INFO_PLIST"
$PLISTBUDDY -c "Add :CFBundleVersion string '$VERSION.$CI_PIPELINE_ID'" "$INFO_PLIST"

BUNDLEID_SCHEME="rla"$(echo "${BUNDLEID}"          | cksum -o3 | awk '{print $1}')
 VERSION_SCHEME="rlv"$(echo "${BUNDLEID}_$VERSION" | cksum -o3 | awk '{print $1}')

echo "Add URLTypes for '$BUNDLEID': $BUNDLEID_SCHEME + $VERSION_SCHEME"

URLTYPES=$($PLISTBUDDY -c "Print :CFBundleURLTypes" "$INFO_PLIST" 2>/dev/null)
if [ "$URLTYPES" == "" ]; then
	$PLISTBUDDY -c "Add :CFBundleURLTypes array" "$INFO_PLIST"
fi

INDEX=0;

while :
do
	BUNDLEURLNAME=$($PLISTBUDDY -c "Print :CFBundleURLTypes:$INDEX:CFBundleURLName" "$INFO_PLIST" 2>/dev/null)

	if [ "$BUNDLEURLNAME" == "" ]; then
		#echo "End found: $INDEX
		break;
	fi

	if [ "$BUNDLEURLNAME" == "RelutionUrlName" ]; then
		$PLISTBUDDY -c "Delete :CFBundleURLTypes:$INDEX" "$INFO_PLIST"
		#echo "Delete :CFBundleURLTypes:$INDEX"
	else
		let 'INDEX=INDEX+1'
	fi
done

$PLISTBUDDY \
	-c "Add :CFBundleURLTypes:0 dict" \
	-c "Add :CFBundleURLTypes:0:CFBundleURLName string 'RelutionUrlName'" \
	-c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" \
	-c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string '$BUNDLEID_SCHEME'" \
	-c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:1 string '$VERSION_SCHEME'" \
	"$INFO_PLIST"

# "$PLISTBUDDY" -c Print "$INFO_PLIST"
