#!/bin/bash -e

timestamp=$(date +"%Y%m%d_%H%M")

################################################################################
# help function
################################################################################
showHelp() {
  echo "Renames ipafiles or apkfiles to <bundleId>_<version>_<currentTime>.ipa"
  echo "Supports multiple arguments."
  echo ""
  echo "Usage: $0 <filename>"
  echo ""
  exit 0
}

# if parameters are empty
if [[ $# -eq 0 ]]; then
  echo "No ipa file supplied"
  showHelp
fi

for file in "$@"; do
  # error handling for required ipa path
  if [ "${file}" == "-h" ]; then
    showHelp
  elif [[ -z "${file// }" ]]; then
    echo "Invalid Path!"
    showHelp
  elif [[ ! $file == *.ipa && ! $file == *.apk ]]; then
    errorMessage "Error: $file is not an .ipa or .apk file!"
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
    # fix path for gitlab runner
    echo hostname
    if [[ $(hostname) = runner-* ]]; then
      s=$($ANDROID_HOME/build-tools/*/aapt dump badging ${file} | grep package:\ name)
    else
      s=$(/usr/local/bin/aapt dump badging ${file} | grep package:\ name)
    fi

    # extract the information from the file name to use them for the new file name
    declare -a infos=( ${s//\'/ } )
    packageName="${infos[2]}"
    version="v${infos[6]}"
    versionCode="vc${infos[4]}"
    filename="${packageName}_${version}_${versionCode}_${timestamp}-appstore.apk"
  fi


  # check if file already exists
  if [[ -f ${filename} ]]; then
    echo "Attention: File ${filename} already exists! Skipping renaming of ${file}"
  else
    cp -v "$file" ${filename};
  fi

done
