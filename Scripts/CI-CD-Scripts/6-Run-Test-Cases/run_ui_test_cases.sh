#!/bin/sh -e

# fastlane requires your locale to be set to UTF-8.
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8


# Check If we need to skip CI
cd ../1-Skip-CI
sh should_skip_continuous_integration.sh
if [ $? == 1 ]
  then
    exit 0
  else
    cd -
fi


# Move to project folder.
cd ../../../../unation-ios-UN_3.0.1

echo ""
echo "--------------------------------------------------"
echo "   Run TestApp UI Test-Cases "
echo "--------------------------------------------------"
echo ""

fastlane run_ui_test_cases
exit $?
