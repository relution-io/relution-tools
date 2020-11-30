#!/bin/bash -e

timestamp=$(date +"%Y%m%d_%H%M")

################################################################################
# help function
################################################################################
showHelp() {
  echo "Renames ipafiles or apkfiles to <bundleId>_<version>_<currentTime>.[ipa|apk]"
  echo ""
  echo "Usage: $0 <filename> [move|copy]"
  echo "Optional parameter:"
  echo "  - copy (default) creates a copy of the original file with the new name"
  echo "  - move replaces the original file"
  exit 0
}

# if parameters are empty
if [[ $# -eq 0 ]]; then
  echo "No .ipa or .apk / .aab file supplied"
  showHelp
fi

file=$1

# error handling for required ipa path
if [ "${file}" == "-h" ]; then
  showHelp
elif [[ -z "${file// }" ]]; then
  echo "Invalid Path!"
  showHelp
elif [[ ! $file == *.ipa && ! $file == *.apk && ! $file == *.aab ]]; then
  errorMessage "Error: $file is not an .ipa or .apk / .aab file!"
  showHelp
elif [[ ! -f $file ]]; then
  echo "File not found!"
  exit 1
fi

if [[ $file == *.ipa ]]; then
  # unzip into tmp directory
  myTmpDir=`mktemp -d 2>/dev/null || mktemp -d -t 'myTmpDir'`
  unzip -q "$file" -d "${myTmpDir}";
  pathToFile=${myTmpDir}/Payload/*.app/Info.plist

  # get bundleid and version. make it into a filename
  CFBundleIdentifier_now=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" ${pathToFile})
  CFBundleVersion_now=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" ${pathToFile})

  filename=${CFBundleIdentifier_now}_v${CFBundleVersion_now}_${timestamp}.ipa
else
  aaptPath=$(find . $ANDROID_HOME/build-tools -name aapt -type f -print -quit)

  if [[ ! -f $aaptPath ]]; then
    echo "Error: Android Build Tools not installed."
    exit 1
  fi

  if [[ $file == *.aab ]]; then
    myTmpDir=`mktemp -d 2>/dev/null || mktemp -d -t 'myTmpDir'`

    # extract .apks file from .aab file
    bundletool build-apks --bundle=$file --output=${myTmpDir}/temp_${timestamp}.apks --mode=universal &> /dev/null

    cd ${myTmpDir}

    # change the output file name from .apks to .zip
    mv temp_${timestamp}.apks temp_${timestamp}.zip &> /dev/null

    # unzip to become the universal.apk file
    unzip -q temp_${timestamp}.zip -d "${myTmpDir}" &> /dev/null

    packageString=$($aaptPath dump badging universal.apk | grep package)

    cd - &> /dev/null
  else
    packageString=$($aaptPath dump badging ${file} | grep package)
  fi

  packageName=$(echo $packageString | awk '{print $2}' | sed s/name=//g | sed s/\'//g)
  version=$(echo $packageString | awk '{print $4}' | sed s/versionName=//g | sed s/\'//g)
  versionCode=$(echo $packageString | awk '{print $3}' | sed s/versionCode=//g | sed s/\'//g)


  if [[ -z "$packageName" ]]; then
    echo "WARNING: Package Name is not set"
    packageName="EMPTY"
  fi
  if [[ -z "$version" ]]; then
    echo "WARNING: Version is not set"
    version="EMPTY"
  fi
  if [[ -z "$versionCode" ]]; then
    echo "WARNING: Version Code is not set"
    versionCode="EMPTY"
  fi

  if [[ $file == *.aab ]]; then
    filename="${packageName}_v${version}_vc${versionCode}_${timestamp}.aab"
  else
    filename="${packageName}_v${version}_vc${versionCode}_${timestamp}.apk"
  fi
fi


# check if file already exists
if [[ -f ${filename} ]]; then
  echo "Attention: File ${filename} already exists! Skipping renaming of ${file}"
elif [[ "$2" == "move" ]]; then
  mv -v "$file" ${filename};
else
  cp -v "$file" ${filename};
fi
