#!/usr/bin/env sh
# vim: ft=sh ts=2 sw=2 st=2
#         _  __ _ __
#        / |/ //// /
#       / || // U / 
#      /_/|_/ \_,'  
#
# Node Virtual Environments

__nu__help() {
  cat <<-help

  Usage: nu [options] [COMMAND] [config] 

  Commands:
    nu --latest                         Output the latest node version available
    nu latest [config ...]              Install latest version node
    nu install <version> [config ...]   Install <version> node
    nu list                             Output the versions installed
    nu lns                              Output the versions of node available
    nu current                          Output the current node version
    nu downlaod <version ...>           Download node <version ...>
    nu use <version> [args ...]         Use node <version> with [args ...]
    nu run <version> [args ...]         Run node <version> with [args ...]
    nu bin <version>                    Output bin path for <version>

  Options:
    -V, --version                       Output current version of nu
    -h, --help                          Display help information

  Aliases:
    install     i       -i
    list        ls      -ls
    lns                 -lns
    download    down    -d
    current     now/curr

help
}

__nu__main() {
  __nu__get || return
  __nu__config || return

  if test $# -eq 0; then
    __nu__help
    return
  fi

  case $1 in
    -v | v | version ) __nu__version ;;
    i | install ) shift; __nu__install $@ ;;
    bin ) shift; __nu__bin $@ ;;
    run ) shift; __nu__run $@ ;;
    use ) shift; __nu__use $@ ;;
    now | curr | current ) __nu__current ;;
    -d | down | download ) shift; __nu__download $@ ;;
    -lns | lns ) __nu__list_nversions ;;
    -ls | ls | list ) __nu__list_versions ;;
    --latest ) __nu__latest ;;
    latest ) shift; __nu__install `__nu__latest` $@ ;;
    -h | help | * ) __nu__help ;;
  esac
}

__nu__version() {
  echo $NU_VERSION
}

__nu__install() {
  local version=$1; shift
  local config=$@
  __nu__check_current

  # remove "v"
  version=${version#v}
  local dir=$NU_DIR/$version

  test -d "$dir" \
    && echo "v$version is already installed."

  local t=$(__nu__match $version)
  local filename="node-v$version"
  local file="$filename.$TAR_SUFFIX"

  local tarball="node-"$(test $t -gt "1" && echo "v")$version

  # 0.0.1 <= $version <= 0.1.9
  # 0.1.100 <= $version <= 0.5.0
  # 0.5.1 <= $version
  local url=$NODE_DIST$(test $t -eq "3" && echo "v$version/")"$tarball.$TAR_SUFFIX"

  echo $url

  (cd "$NU_DIR/src" \
    && `echo $GET` $url \
    > $file \
    && tar -zxf $file > $LOGPATH 2>&1)

  # see if things are alright
  if test $? -gt 0; then
    echo "\033[31mError: installation failed\033[0m"
    return 1
  fi
  
  test "$filename" != "$tarball" \
    && (cd "$NU_DIR/src" && mv $tarball $filename > $LOGPATH 2>&1)

  (cd "$NU_DIR/src/$filename" \
    && ./configure --prefix=$NU_DIR/$version $config \
    && JOBS=4 make \
    || echo "$vversion make failed." \
    && make install)
}

__nu__bin() {
  local v=$1
  test -z $v && {__nu__check_current; v="$active";}
  v=${v#v}
  test -z $v && echo "version required." && return

  test -d "$NU_DIR/$v/bin" \
    && echo "$NU_DIR/$v/bin" \
    || echo "v$v is not installed."
}

__nu__run() {
  local v=$1
  test -z $v && {__nu__check_current; v="$active";}
  v=${v#v}
  test -z $v && echo "v required." && return

  local bin=$NU_DIR/$v/bin/node

  test $# -ne 0 && shift

  test -f $bin && {echo "Running node v$v."; $bin $@;} \
    || echo "v$v is not installed."
}

__nu__use() {
  local v=$1
  test -z $v && {__nu__check_current; v="$active";}
  v=${v#v}

  test $# -eq 0 \
    && echo "v$v is already activated." \
    && return

  ! test -d $NU_DIR/$v \
    && echo "v$v is not installed." \
    && return

  local bin=$NU_DIR/$v/bin
  local lib=$NU_DIR/$v/lib
  local man=$NU_DIR/$v/man

  if [[ $PATH == *$NU_DIR/*/bin* ]]; then
    PATH=${PATH%$NU_DIR/*/bin*}$bin${PATH#*$NU_DIR/*/bin}
  else
    PATH="$bin:$PATH"
  fi

  if [[ $MANPATH == *$NU_DIR/*/share/man* ]]; then
    MANPATH=${MANPATH%$NU_DIR/*/share/man*}$man${MANPATH#*$NU_DIR/*/share/man}
  else
    MANPATH="$man:$MANPATH"
  fi

  echo "Now using node v$v."
  export PATH
  hash -r
  export MANPATH
  npm_config_binroot="$bin"
  npm_config_root="$lib"
  npm_config_manroot="$man"
  NODE_PATH="$lib"
  #"$SHELL"
}

__nu__check_current() {
  which node &> /dev/null && active=`node -v` && active=${active#v}
}

__nu__current() {
  __nu__check_current
  test -n "$active" && echo "v$active" || echo "N/A"
}

__nu__download() {
  test $# -eq 0 && return
  local t filename file tarball url
  for v in "$@"; do
    t=$(__nu__match $v)
    filename="node-v$v"
    file="$filename.$TAR_SUFFIX"

    tarball="node-"$(test $t -gt "1" && echo "v")$v

    # 0.0.1 <= $version <= 0.1.9
    # 0.1.100 <= $version <= 0.5.0
    # 0.5.1 <= $version
    url=$NODE_DIST$(test $t -eq "3" && echo "v$v/")"$tarball.$TAR_SUFFIX"
    echo $url
    (cd "$NU_DIR/src" \
      && `echo $GET` $url \
      > $file)
  done
}

__nu__list_nversions() {
  local vers="$(`echo $GET` 2> /dev/null $NODE_DIST \
    | egrep -o '[0-9]+\.[0-9]+\.[0-9]+' \
    | sort -u -k 1,1n -k 2,2n -k 3,3n -t .)" 

  __nu__wcl $vers || return

  echo $vers | __nu__printlist
}

__nu__list_versions() {
  local vers="`ls -la -I 'src' $NU_DIR \
    | egrep -o '[0-9]+\.[0-9]+\.[0-9]+' \
    | sort -u -k 1,1n -k 2,2n -k 3,3n -t .`"

  __nu__wcl $vers || return

  echo $vers | __nu__printlist ' ' ' '
}

__nu__latest() {
  (`echo $GET` 2> /dev/null $NODE_DIST \
    | egrep -o '[0-9]+\.[0-9]+\.[0-9]+' \
    | sort -u -k 1,1n -k 2,2n -k 3,3n -t . \
    | tail -n1)
}

__nu__cut() {
  echo $(echo $1 | cut -d '.' -f $2)
}

__nu__match() {
  local v=$1 n=3 n1 n2 n3
  n1=$(__nu__cut $v 1)
  n2=$(__nu__cut $v 2)
  n3=$(__nu__cut $v 3)
    
  if test $n2 -le "1" && test $n3 -le "9"; then
    n=1
  elif test $n2 -le "4"; then
    n=2
  elif test $n2 -eq "5" && test $n3 -eq "0"; then
    n=2
  fi

  echo $n
}

__nu__wcl() {
  local c=`echo $1 | wc -m`
  test $c -eq "1" && {echo 'N/A'; return 1;}
  return 0
}

__nu__printlist() {
  __nu__check_current
  local i=0
  local v a=""
  local s=${1:-"*"} o=${2:-"o"}
  while read v; do
    if test -z $a && test "$active" = "$v"; then
      a="1"
      v="\033[32m$v $o\033[0m"
    elif test -d $NU_DIR/$v; then
      v="\033[33m$v $s\033[0m"
    fi

    if test $i -eq 4; then
      i=0
      echo "$v"
    else
      let 'i = i + 1'
      echo -ne "$v   \t"
    fi
  done
  test $i -ne 0 && echo ""
  return 0
}

__nu__ensuredir() {
  test -d $1 \
    || mkdir -p "$1/src" 2> /dev/null \
    || (echo "Failed to create ($NU_DIR) directory, \
do you have permissions to do this?" \
      && return 1) \
    || return 1 
}

__nu__get() {
  test -z "$GET" && __nu__hasget=1
  [ $__nu__hasget -eq 1 ] && echo "curl or wget required." >&2 && return 1
  __nu__hasget=0
}

__nu__config() {
  __nu__ensuredir $NU_DIR || return 1
}

__nu__init() {
  NU_VERSION="0.0.1"
  NU_DIR="${NU_DIR-/usr/local/lib/nu}"

  NODE_SITE="http://nodejs.org"
  NODE_DIST="$NODE_SITE/dist/"

  TAR_SUFFIX="tar.gz"
  LOGPATH="/tmp/nu.log"


  which wget > /dev/null && GET="wget --no-check-certificate -q -O-"
  which curl > /dev/null && GET="curl -# -L"
}

__nu__hasget=0

__nu__init

nu() {
  __nu__main $@
}
