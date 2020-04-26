#!/bin/sh -e


# Check If we need to skip CI
cd ../1-Skip-CI
sh should_skip_continuous_integration.sh
if [ $? == 1 ]
  then
    exit 0
  else
    cd -
fi


# fastlane requires your locale to be set to UTF-8.
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8


# Move to project folder.
cd ../../../../unation-ios-UN_3.0.1

echo ""
echo "--------------------------------------------------------------------"
echo "   Create .ipa for Development Environment"
echo "--------------------------------------------------------------------"
echo ""

echo $pwd

fastlane create_build_for_development
exit $?
