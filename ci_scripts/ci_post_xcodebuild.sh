#!/bin/sh

#  ci_post_xcodebuild.sh.sh
#  Revolt
#
#  Created by Angelo on 22/08/2024.
#

set -e

if [ ! -d "$CI_ARCHIVE_PATH" ]; then
    echo "Archive does not exist, skipping Sentry upload"
    exit 0
fi

export INSTALL_DIR=$PWD

if [[ $(command -v sentry-cli) == "" ]]; then
    echo "Installing Sentry CLI"
    curl -sL https://sentry.io/get-cli/ | bash
fi

echo "Authenticate to Sentry"
./sentry-cli login --auth-token $SENTRY_AUTH_TOKEN

echo "Uploading dSYM to Sentry"
./sentry-cli debug-files upload -o revolt -p apple-ios $CI_ARCHIVE_PATH --force-foreground
