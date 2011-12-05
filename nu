#!/usr/bin/env sh
# vim: ft=sh ts=2 sw=2 st=2

# Node Virtual Environments

_NU_VERSION="0.0.1"
_N_="__nu__"
TAR_SUFFIX="tar.gz"

NODE_SITE="http://nodejs.org"
NODE_DIST="$NODE_SITE/dist/"

_U_() {
  local f=$1; shift
  ${_N_}$f $@
  return 1
}

__nu__main() {
  if test $# -eq 0; then
    _U_ 'help'
    return
  else
    _U_ 'get'
    _U_ 'config'
    while test $# -ne 0; do
      case $1 in
        -h|--help|help) _U_ 'help' ;;
        -V|--version) _U_ 'version' ;;
        -i|i|install) shift; _U_ 'install' $@ ;;
        -r|r|remove) shift; _U_ 'remove' $@ ;;
        --latest) _U_ 'latest' ;;
        latest) shift; _U_ 'install' `__nu__latest` $@ ;;
        -ls|ls|list) _U_ 'list_versions' ;;
        -lns|lns) _U_ 'list_nversions' ;;
        now|current) _U_ 'current' ;;
        run) shift; _U_ 'run' $@ ;;
        use) shift; _U_ 'use' $@ ;;
        bin) _U_ 'binpath' $2; return ;;
        *) _U_ 'help' ;;
      esac
      shift
    done
  fi
}

__nu__get() {
  # curl / wget support
  # wget support (Added --no-check-certificate for Github downloads)
  which wget > /dev/null && GET="wget --no-check-certificate -q -O-"

  # curl support
  which curl > /dev/null && GET="curl -# -L"

  # Ensure we have curl or wget
  test -n "$GET" && export GET || echo "curl or wget required"
}

__nu__config() {
  NU_DIR=${NU_DIR-/usr/local/lib/nu}
  __nu__ensuredir $NU_DIR "Failed to create versions directory \
    ($NU_DIR), do you have permissions to do this?"
    
  export NU_DIR
  export NU_SRC="$NU_DIR/src"
    
  __nu__ensuredir $NU_SRC "Couldn't create $NU_SRC"
}

__nu__check_current() {
  which node &> /dev/null && active=`node -v` && active=${active#v}
}

__nu__current() {
  _U_ 'check_current'
  echo "v$active"
}

__nu__bin() {
  local v=${1#v}
  (test $# -eq 0 \
    && echo `which node`) \
    || (test -d "$NU_DIR/$v/bin" \
    && echo "$NU_DIR/$v/bin") \
    || echo "N/A" && return
}

__nu__latest() {
  (`echo $GET` 2> /dev/null $NODE_DIST \
    | egrep -o '[0-9]+\.[0-9]+\.[0-9]+' \
    | sort -u -k 1,1n -k 2,2n -k 3,3n -t . \
    | tail -n1)
}

__nu__ensuredir() {
  local dir="$1" txt="$2"
  test -d "$dir" || mkdir -p "$dir" \
    || __nu__abort "$txt"
}

__nu__log() {
  echo "$@"
}

__nu__abort() {
  echo "$@" 1>&2
}

__nu__wcl() {
  local c=`echo $1 | wc -m`
  test $c -eq "1" && __nu__log 'N/A' && return 0
  return 1
}

__nu__list_nversions() {
  local vers="$(`echo $GET` 2> /dev/null $NODE_DIST \
    | egrep -o '[0-9]+\.[0-9]+\.[0-9]+' \
    | sort -u -k 1,1n -k 2,2n -k 3,3n -t .)" 

  (__nu__wcl $vers || return)

  echo $vers | _U_ 'printlist' \
    || return 1
}

__nu__list_versions() {
  _U_ 'check_current'
  local vers="`ls -la -I 'src' $NU_DIR \
    | egrep -o '[0-9]+\.[0-9]+\.[0-9]+' \
    | sort -u -k 1,1n -k 2,2n -k 3,3n -t .`"

  (__nu__wcl $vers || return)

  echo $vers | _U_ 'printlist' ' ' ' ' \
    || return 1
}

__nu__printlist() {
  _U_ 'check_current'
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

__nu__cleanup() {}

__nu__run() {
  test -z $1 && __nu__abort "version required." && return
  local version=${1#v}
  local bin=$NU_DIR/$version/bin/node

  shift

  if test -f $bin; then
    echo "Running node v$version."
    $bin $@
  else
    __nu__abort "v$version is not installed."
  fi
}

__nu__use() {
  test $# -ne 1 && nu_help
  local version=${1#v}

  ! test -d $NU_DIR/$version \
    && __nu__abort "v$version is not installed." \
    && return

  __nu__check_current

  test "$active" = "$version" \
    && __nu__abort "$version is already activated." \
    && return 0

  local bin=$NU_DIR/$version/bin
  local lib=$NU_DIR/$version/lib
  local man=$NU_DIR/$version/man

  if [[ $PATH == *$NU_DIR/*/bin* ]]; then
    PATH=${PATH%$NU_DIR/*/bin*}$bin${PATH#*$NU_DIR/*/bin}
  else
    PATH="$bin:$PATH"
  fi

  if [[ $MANPATH == *$NU_DIR/*/share/man* ]]; then
    MANPATH=${MANPATH%$NU_DIR/*/share/man*}$NU_DIR/$version/share/man${MANPATH#*$NU_DIR/*/share/man}
  else
    MANPATH="$man:$MANPATH"
  fi

  echo "Now using node v$version."
  export PATH
  hash -r
  export MANPATH
  npm_config_binroot="$bin"
  npm_config_root="$lib"
  npm_config_manroot="$man"
  NODE_PATH="$lib"
  #"$SHELL"
}

__nu__install() {
  local version=$1; shift
  local config=$@
  _U_ 'check_current'

  # remove "v"
  version=${version#v}

  local dir=$NU_DIR/$version
  test "$active" = "$version" && test -d "$dir" \
    && __nu__abort "$version is already installed."

  local t=$(__nu__match $version)

  local filename="node-v$version"
  local file="$filename.$TAR_SUFFIX"
  local logpath="/tmp/nu.log"

  local tarball="node-"$(test $t -gt "1" && echo "v")$version

  # 0.0.1 <= $version <= 0.1.9
  # 0.1.100 <= $version <= 0.5.0
  # 0.5.1 <= $version
  local url=$NODE_DIST$(test $t -eq "3" && echo "v$version/")"$tarball.$TAR_SUFFIX"

  echo $url

  (cd $NU_SRC \
    && `echo $GET` $url \
    > $file \
    && tar -zxf $file > $logpath 2>&1)

  # see if things are alright
  if test $? -gt 0; then
    echo "\033[31mError: installation failed\033[0m"
    echo "  node version $version does not exist,"
    echo "  n failed to fetch the tarball,"
    echo "  or tar failed. Try a different"
    echo "  version or view $logpath to view"
    echo "  error details."
    return 0
  fi

  test "$filename" != "$tarball" && mv $tarball $filename > $logpath 2>&1

  (cd $NU_SRC/$filename \
    && ./configure --prefix=$NU_DIR/$version $config \
    && JOBS=4 make \
    || __nu__abort "$version make failed." \
    && make install)

}

__nu__remove() {}

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
    current     curr

help
}

__nu__version() {
  echo $_NU_VERSION
}

nu() {
  __nu__main "$@"
}
