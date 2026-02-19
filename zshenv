# This is always loaded 
# but path helper will modify the path, so we need to duplicate the path
# setup in .zprofile

# Set brew basics
export HOMEBREW_PREFIX="/opt/homebrew";
export HOMEBREW_CELLAR="/opt/homebrew/Cellar";
export HOMEBREW_REPOSITORY="/opt/homebrew";

# General environment setup
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export EDITOR=nvim

# # Android setup
export ANDROID_HOME=/Users/thasso/Library/Android/sdk/
export ANDROID_SDK_ROOT=$ANDROID_HOME
export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/29.0.13599879

# Node
export NODE_ENV=development
export NODE_OPTIONS='--disable-warning=ExperimentalWarning'

# Ruby
export LDFLAGS="${LDFLAGS} -L${HOMEBREW_PREFIX}/opt/ruby/lib"
export CPPFLAGS="${CPPFLAGS} -I${HOMEBREW_PREFIX}/opt/ruby/include"

# Source shared PATH logic
if [[ -f $HOME/.zpath ]]; then
  source $HOME/.zpath
fi
