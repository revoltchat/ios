#!/bin/sh



# allow using macros
defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES

# resolve packages
cd ..
xcodebuild -resolvePackageDependencies
cd ci_scripts