#!/bin/bash

# needs a GitHub branch or tag name -and- a org/project

# exmaple:   bash build_all_the_things.sh v7.0.0 rupaya-project/rupaya
# this will build:

#     - Mac, Linux, Windows binaries, 32 and 64 bit as well as ARM
green="\033[38;5;40m"
magenta="\033[38;5;200m"
cyan="\033[38;5;87m"
reset="\033[0m"
THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
masterApiEndpoint="https://api.github.com"
repo="https://github.com/rupaya-project/rupaya"

get_latest_tag () {
  local url="curl ${masterApiEndpoint}/repos/rupaya-project/rupaya/tags"
  response=(`${url} 2>/dev/null | sed -n 's/"name": "\(.*\)",$/\1/p'`)
  echo ${response[0]}
}

check_mac () {
  if [[ "${1}" == "osx" ]] && [[ ! -f "$THISDIR/cache/Xcode-11.3.1-11C505-extracted-SDK-with-libcxx-headers.tar.gz" ]]; then
    echo -e "${magenta}Xcode-11.3.1-11C505-extracted-SDK-with-libcxx-headers.tar.gz does not exist in cache therefore OSX build not available.${reset}"
    exit -1
  fi
}

fall_back_branch_or_tag="5980"
branch_or_tag=
if [ -z "${1}" ]; then
  branch_or_tag=`get_latest_tag`
  if [ -z "${branch_or_tag}" ]; then
    echo -e  "${magenta}Could not get the latest remote tag from: ${masterRepo}, therefore defaulting to building: ${fall_back_branch_or_tag}${reset}"
    branch_or_tag="${1}"
  fi
else
  branch_or_tag="${1}"
fi

if [ -n "${2}" ]; then
  repo="${2}"
fi

$THISDIR/build_builder.sh

platforms=("osx" "win" "linux")

for platform in "${platforms[@]}"; do
  check_mac "${platform}"
  sdate=`date +%s`
  echo -e "${cyan}starting $platform build of tag: ${branch_or_tag} at: `date`${reset}"
  time docker run -h builder --name builder-$sdate \
  -v $THISDIR/cache:/shared/cache:Z \
  -v $THISDIR/result:/shared/result:Z \
  builder \
  "${branch_or_tag}" \
  "${repo}" \
  "../rupaya/contrib/gitian-descriptors/gitian-${platform}.yml"
done
