#!/bin/bash

PROJECT_NAME="PrebidMobileFS"
PROJECT_DIR="../sdk"
WORKSPACE_NAME="$PROJECT_NAME.xcworkspace"
SCHEME="Universal-$PROJECT_NAME"


if [ ! hash pod 2>/dev/null ]; then
  echo "Error: Cocoapods not installed."
  exit 1  
fi

if [ ! -r $PROJECT_DIR/Podfile ] ; then
  echo "Error: Podfile does not exist."
  exit 1  
fi

if [ ! hash xcodebuild 2>/dev/null ]; then
  echo "Error: Xcode or Xcode related command line components not installed."
  exit 1  
fi

if [ ! -d "$PROJECT_DIR" ]; then
  echo "Error: $PROJECT_DIR does not exist or is not readable."
  exit 1
fi

if [ ! -d "$PROJECT_DIR/$WORKSPACE_NAME" ]; then
  echo "Error: $PROJECT_DIR/$WORKSPACE_NAME does not exist or is not readable."
  exit 1
fi

( cd $PROJECT_DIR; pod install )

( cd $PROJECT_DIR; xcodebuild -workspace $WORKSPACE_NAME -scheme $SCHEME clean archive )

exit 0
