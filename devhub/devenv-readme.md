# Relution Managed Development Environment

This repository was set up by Relution as a managed development environment. This enabled developers registered in Relution to use it via SSH and create apps which will be uploaded to Relution.

# Building and Uploading Apps

A `gitlab-ci.yml` file has been added containing a template CI setup to create and upload apps. It needs some small adaptations to work with the app(s) to be built.

## iOS

It is recommended to build unsigned apps in managed development environments as Relution can handle signing automatically without the need to distribute signing credentials.

### Build Unsigned iOS Apps
The following build script can be used to build unsigned apps. Some Xcode project properties have to be set or provided as environment variables to make it work with the repository.
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

## Uploading Apps To Relution
The following build step uploads apps back to relution via the `relution_upload_app.sh` script that has been automatically added to the repository root in a folder called `relution`.
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
