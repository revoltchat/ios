//  ci_post_clone.sh
//  Revolt
//
//  Created by Angelo on 22/08/2024.
//

// allow using macros
defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES


// install sentry-cli

export INSTALL_DIR=$PWD

if [[ $(command -v sentry-cli) == "" ]]; then
    echo "Installing Sentry CLI"
    curl -sL https://sentry.io/get-cli/ | bash
fi
