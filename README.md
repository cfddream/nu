NU
==
> Node Virtual Environments

### Installation:

    > git clone git://github.com/cfddream/nu.git ~/nu
    > source ~/nu/nu

### Usage:

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

### ToDo：
* 提供不同版本 changelog 信息
* 提供不同版本 npm 包管理器
* ...