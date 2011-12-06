NU
==
> Node Virtual Environments
<pre>
         _  __ _ __
        / |/ //// /
       / || // U / 
      /_/|_/ \_,'
</pre>

### Installation:

    > git clone git://github.com/cfddream/nu.git ~/nu
    > source ~/nu/nu

### Usage `nu help`:

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

### Thanks to:
* [isaacs](https://github.com/isaacs) - [nave](https://github.com/isaacs/nave)
* [creationix](https://github.com/creationix) - [nvm](https://github.com/creationix/nvm)
* [visionmedia](https://github.com/visionmedia) - [n](https://github.com/visionmedia/n)

### ToDo：
* 提供不同版本 changelog 信息
* 提供不同版本 npm 包管理器
* ...
