#!/usr/bin/env sh
# vim: ft=sh

# Node Version Manager

VERSION="0.0.1"

NODE_SITE="http://nodejs.org"
NODE_DIST="$NODE_SITE/dist/"
TAR_SUFFIX="tar.gz"

_TABS_="    "

ensure_dir() {
    local dir="$1" txt="$2"
    test -d "$dir" || mkdir -p "$dir" \
        || abort "$txt"
}

abort() {
    echo "$@" >&2 && exit 1
}

nu_config() {
    NU_DIR=${NU_DIR-/usr/local/lib/nu}
    ensure_dir $NU_DIR "Failed to create versions directory \
        ($NU_DIR), do you have permissions to do this?"
    
    export NU_DIR
    export NU_SRC="$NU_DIR/src"
    
    ensure_dir $NU_SRC "Couldn't create $NU_SRC"
}

main () {
    nu_get
    nu_config

    if test $# -eq 0; then
        nu_help
    else
        while test $# -ne 0; do
            case $1 in
                -h|--help|help) nu_help ;;
                -V|--version) nu_version ;;
                -lns|lns) nu_list_nversions ;;
                -ls|ls|list) nu_list_versions ;;
                --latest|--stable) nu_latest ;;
                current) nu_current ;;
                install) nu_install ${@:2:$#}; exit ;;
                latest) shift; nu_install `$0 --latest` $@; exit ;;
                use) shift; nu_use $@ ;;
            esac
            shift
        done
    fi
}

# Check curl or wget.
nu_get() {
    # curl / wget support

    # wget support (Added --no-check-certificate for Github downloads)
    which wget > /dev/null && GET="wget --no-check-certificate -q -O-"

    # curl support
    which curl > /dev/null && GET="curl -# -L"

    # Ensure we have curl or wget
    test -n "$GET" && export GET || echo "curl or wget required"
}

#
nu_check_current_version() {
    which node &> /dev/null && active=`node -v` && active=${active#v}
}

nu_current() {
    nu_check_current_version
    echo "$_TABS_$active"
}

# Display the node latest
nu_latest() {
    $GET 2> /dev/null $NODE_DIST \
        | egrep -o '[0-9]+\.[0-9]+\.[0-9]+' \
        | sort -u -k 1,1n -k 2,2n -k 3,3n -t . \
        | tail -n1
}

# Display the versions of node available.
nu_list_nversions() {
    nu_check_current_version
    local versions=`$GET 2> /dev/null $NODE_DIST \
        | egrep -o '[0-9]+\.[0-9]+\.[0-9]+' \
        | sort -u -k 1,1n -k 2,2n -k 3,3n -t . \
        | awk '{ print "  " $1 }'`

    test ${#versions} -eq "0" && abort "N/A"

    for v in $versions; do
        if test "$active" = "$v"; then
            echo "  \033[32mο $v \033[0m"
        else
            if test -d $NU_DIR/$v; then
                echo "  * $v \033[0m"
            else
                echo "$_TABS_$v"
            fi
        fi
    done
}

nu_list_versions() {
    nu_check_current_version
    local versions=`ls -la -I 'src' $NU_DIR \
        | egrep -o '[0-9]+\.[0-9]+\.[0-9]+' \
        | sort -u -k 1,1n -k 2,2n -k 3,3n -t . \
        | awk '{ print "  " $1 }'`

    test ${#versions} -eq "0" && abort "N/A"

    for v in $versions; do
        if test "$active" = "$v"; then
            echo "  \033[32mο $v \033[0m"
        else
            echo "$_TABS_$v"
        fi
    done
}

nu_use() {
    test -z $1 && abort "version required."
    local version=${1#v}
    local bin=$NU_DIR/$version/bin/node

    shift

    if test -f $bin; then
        $bin $@
    else
        abort "$_TABS_$version is not installed."
    fi
}

# Display nu version.
nu_version() {
    echo $VERSION && exit 0
}

# Install node <version> [config ...]
nu_install() {
    local version=$1; shift
    local config=$@
    nu_check_current_version

    # remove "v"
    version=${version#v}
    
    local dir=$NU_DIR/$version

    test "$active" = "$version" && test -d "$dir" \
        && echo "$version is already installed." && exit 0

    local t=$(nu_match $version)

    local filename="node-v$version"
    local file="$filename.$TAR_SUFFIX"
    local logpath="/tmp/nu.log"

    local tarball="node-"$(test $t -gt "1" && echo "v")$version

    # 0.0.1 <= $version <= 0.1.9
    # 0.1.100 <= $version <= 0.5.0
    # 0.5.1 <= $version
    local url=$NODE_DIST$(test $t -eq "3" && echo "v$version/")"$tarball.$TAR_SUFFIX"

    echo $url

    cd $NU_SRC \
        && $GET $url \
        > $file \
        && tar -zxf $file > $logpath 2>&1

    # see if things are alright
    if test $? -gt 0; then
        echo "\033[31mError: installation failed\033[0m"
        echo "  node version $version does not exist,"
        echo "  n failed to fetch the tarball,"
        echo "  or tar failed. Try a different"
        echo "  version or view $logpath to view"
        echo "  error details."
        exit 1
    fi

    test $filename != $tarball && mv $tarball $filename > $logpath 2>&1

    cd $NU_SRC/$filename \
        && ./configure --prefix=$NU_DIR/$version $config \
        && JOBS=4 make install

}

nu_cut() {
    echo $(echo $1 | cut -d '.' -f $2)
}

nu_match() {
    local v=$1 n=3 n1 n2 n3
    n1=$(nu_cut $v 1)
    n2=$(nu_cut $v 2)
    n3=$(nu_cut $v 3)
    
    if test $n2 -le "1" && test $n3 -le "9"; then
        n=1
    elif test $n2 -le "4"; then
        n=2
    elif test $n2 -eq "5" && test $n3 -eq "0"; then
        n=2
    fi

    echo $n
}

# Display help.
nu_help() {
    cat <<-EOF
  Node Version Manager
  Usage: nu [options] [COMMAND] [config] 

  Commands:

    nu                           Output versions installed
    nu latest [config ...]       Install or activate the latest node release
    nu <version> [config ...]    Install and/or use node <version>
    nu use <version> [args ...]  Execute node <version> with [args ...]
    nu npm <version> [args ...]  Execute npm <version> with [args ...]
    nu bin <version>             Output bin path for <version>
    nu rm <version ...>          Remove the given version(s)
    nu --latest                  Output the latest node version available
    nu current                   Output the current node version
    nu install                   Install
    nu lns                       Output the versions of node available

  Options:

    -V, --version   Output current version of n
    -h, --help      Display help information

  Aliases:

    -       rm
    which   bin
    use     as
    list    ls
EOF
    exit 0
}

main "$@"
