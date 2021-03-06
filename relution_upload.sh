#!/bin/bash -e

if [[ -z "$JQ_EXECUTABLE" ]]; then
	JQ_EXECUTABLE="jq"
fi

while [[ $# > 1 ]]
do
key="$1"

case $key in
    --help)
    RU_HELP=true
    shift # past argument
    ;;
    -f|--file)
    RU_FILE="$2"
    shift # past argument
    ;;
    -e|--environment)
    RU_ENVIRONMENT_UUID="$2"
    shift # past argument
    ;;
    -r|--release_status)
    RU_RELEASE_STATUS="$2"
    shift # past argument
    ;;
    -h|--host)
    RU_HOST="$2"
    shift # past argument
    ;;
    -u|--user)
    RU_USER="$2"
    shift # past argument
    ;;
    -p|--password)
    RU_PASSWORD="$2"
    shift # past argument
    ;;
    -a|--api_key)
    RU_API_KEY="$2"
    shift # past argument
    ;;
    -n|--archive)
    RU_ARCHIVE_VERSION="$2"
    shift # past argument
    ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done

echo ${RU_HELP}

if [ $RU_HELP ] ; then
    echo "  _____      _       _   _             "
    echo " |  __ \    | |     | | (_)            "
    echo " | |__) |___| |_   _| |_ _  ___  _ __  "
    echo " |  _  // _ \ | | | | __| |/ _ \| '_ \ "
    echo " | | \ \  __/ | |_| | |_| | (_) | | | |"
    echo " |_|  \_\___|_|\__,_|\__|_|\___/|_| |_|"
    echo ""
    echo "-f --file               Path of the artifact that you want to deploy to the Relution Enterprise App Store, relative to the workspace directory. This is typically an Apple iOS (.ipa) or Google Android (.apk) binary."
    echo "-h --host               The Relution base url to which the file should be deployed."
    echo "-r --release_status     The Release status in which the file should be put. Valid arguments are release, review, development. Will set development by default."
    echo "-e --environment        The development hub environment id."
    echo "-a --api_key            Relution API Token used for the authentication."
    echo "-n --archive            Wether to archive the previous App Version. Default value is true: will always archive the former version."
fi

if [[ -n "$RU_RELEASE_STATUS" ]]; then
    curl_args="?releaseStatus=$RU_RELEASE_STATUS"
else
    curl_args="?releaseStatus=DEVELOPMENT"
fi

if [[ -n "$RU_ENVIRONMENT_UUID" ]]; then
    curl_args="${curl_args}&environmentUuid=$RU_ENVIRONMENT_UUID"
fi

if [[ -n "$RU_ARCHIVE_VERSION" ]]; then
    curl_args="${curl_args}&archiveFormerVersion=$RU_ARCHIVE_VERSION"
fi

if [[ -z "$RU_FILE" ]]; then
    echo "Use -f to pass the file path"
    exit 1
fi

if [[ -n "$RU_API_KEY" ]]; then
    curl_auth="-H X-User-Access-Token:${RU_API_KEY}"
else
    curl_auth="-u ${RU_USER}:${RU_PASSWORD}"
fi

# add optional changelog
changelog=""
if [[ -f changelog.md ]]; then
    changelog="-F changelog=@changelog.md"
fi

# check if path given was relative or absolute
if [[ "$RU_FILE" = /* ]]
then
   # Absolute path
   PATH_TO_FILE="$RU_FILE"
else
   # Relative path
   PATH_TO_FILE="$PWD/$RU_FILE"
fi

filename=$(basename -- "$RU_FILE")

echo "Uploading $filename to $RU_HOST/relution/api/v1/apps/fromFile$curl_args ..."
response=$(curl \
  -sS \
  -H "Accept:application/json" \
  $curl_auth \
  $changelog \
  -F "app=@$PATH_TO_FILE" \
  "$RU_HOST/relution/api/v1/apps$curl_args")

response_message=$(echo "$response" | "$JQ_EXECUTABLE" -r '.message')
response_code=$(echo "$response" | "$JQ_EXECUTABLE" -r '.status')
error_code=$(echo "$response" | "$JQ_EXECUTABLE" -r '.errorCode')

if [[ "$response_code" == "0" ]]; then
    echo $response_message
    appuuid=$(echo "$response" | "$JQ_EXECUTABLE" -r '.results[0].uuid')
    echo "$RU_HOST/relution/portal/#/apps/$appuuid/information"
elif [[ "$error_code" == "VERSION_ALREADY_EXISTS" ]]; then
    echo "Version already exists. Current version not uploaded again."
else
    echo "There was an error uploading the App. This is the response we got:"
    echo "$response" | "$JQ_EXECUTABLE"
    exit 1
fi
