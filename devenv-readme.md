# Relution Managed Development Environment

This repository was set up by Relution (https://www.relution.io) as a managed development environment. 
It enables developers, which are member of a specific Relution account, to use it via SSH and create apps which will be uploaded to Relution.

# Building and uploading apps

A `gitlab-ci.yml` file has been added to this repository containing a template CI setup to create and upload apps. 
It needs some small adaptations to work with the app(s) to be built.

## iOS

It is recommended to build unsigned apps in managed development environments as Relution can handle signing automatically without the need to handle the signing process and distribute signing credentials.

### How to build unsigned iOS apps
The following build script can be used to build unsigned apps. Some Xcode project properties have to be set or provided as environment variables (${VARIABLE}) to make it work with the repository.
```yml
  ...
  script:
    - xcodebuild -scheme '${SCHEME_NAME}' -workspace '${PROJECT_NAME}.xcodeproj/project.xcworkspace' -configuration Release clean archive -archivePath build/${PROJECT_NAME}.xcarchive CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO 
    - mkdir Payload && mv build/${PROJECT_NAME}.xcarchive/Products/Applications/${SCHEME_NAME}.app/ Payload/ && zip -r build/${APP_NAME}.ipa Payload/ && rm -rf Payload/
  artifacts:
    paths:
    - build/*.ipa
  ...
```

## Uploading apps to Relution
The following build step uploads apps to Relution via the `relution_upload_app.sh` script that has been automatically added to the repository root in a folder called `relution`.
```yml
...
relution:
  stage: publish
  script:
    - bash relution/relution_upload_app.sh -f build/${APP_NAME}.ipa 
  allow_failure: true
  only:
    - master # when this should be run
  variables:
...
```
The only parameter to be set in the script or provided as an environment variable is the name of the app.
