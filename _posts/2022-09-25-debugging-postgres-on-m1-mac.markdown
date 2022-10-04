---
layout: post
title:  "Build and Debug Postgres using VS Code on a Mac"
date:   2022-09-25 10:45:01 +0530
description: This post explains how to build Postgres from Source code and debug it using VS Code.
tags: postgres how-to
excerpt_separator: <!--more-->
---
In this post, we will see how to build Postgres from the source code and debug it to trace through a simple
query execution using [Visual Studio Code](https://code.visualstudio.com/) in a M1 Mac.
<!--more-->
### Dependencies
Before starting make sure all the [dependencies](https://www.postgresql.org/docs/14/install-requirements.html) are installed.
We will need,
1. Git
2. GCC compiler
3. make
4. VS Code


### Build and Install Postgres
1. First we have to get the source code, we can clone the official Git repo,
```sh
git clone https://git.postgresql.org/git/postgresql.git
```
There is also a [mirror](https://github.com/postgres/postgres) of the repository in Github. We can use any one of these, it would be fine.

2. After cloning the repo, cd into the folder 'postgresql'. We can either build from the master branch or a release-specific branch.
For example, to build Postgres 14, we have to switch to 'REL_14_STABLE' branch.
```sh
git checkout REL_14_STABLE && git pull
```

3. To configure the build, run the following command,
```sh
./configure --prefix=$HOME/postgres/pg14 --enable-cassert \
--enable-debug  CFLAGS="-ggdb -O0 -fno-omit-frame-pointer" CPPFLAGS="-g -O0"
```
* prefix - folder where Postgres will be installed
* enable-cassert - Enable C Assert statements
* enable-debug - Enable Debug mode in build
* CFLAGS - C compiler flags
  *  -O0 - disable optimisation
  * -g - generate debug symbols
* CPPFLAGS - C++ compiler flags
I have given postgres/pg14 folder under my HOME directory as installation location for this Postgres build.

4. 'configure' script will do a few checks and configure the build, the output should end with something like
>config.status: linking src/include/port/darwin.h to src/include/pg_config_os.h
>config.status: linking src/makefiles/Makefile.darwin to src/Makefile.port

5. 'configure' would have created a 'Makefile.global' under 'src' directory, we need to check and make sure optimisations are disable, debug symbols are enabled in the build.
Open `src/Makefile.global` file and check CFLAGS and CPPFLAGS variables to see if they have `-g` and `-O0` flags.

6. Run `make && make install` to run the build and install the outputs to installation directory (`$HOME/postgres/pg14`)

7. After `make && make install` succeeds, go to installation directory and check if the build has debug symbols
```sh
cd $HOME/postgres/pg14/bin
nm -pa ./postgres | grep OSO
```
`nm` is used to list the symbol table names in a binary. For PG14, nm returned around 747 entires.
If you do not find any symbol table entries, or the entries are low, make sure you disabled optimisation in Makefile. If you missed it, add `-O0` in Makefile.global, run `make clean` and then repeat `make && make install`

8. Initialize a PGDATA folder for the database using `initdb`, I'm using `$HOME/postgres/pgdata` as my data directory,
```sh
$HOME/postgres/pg14/bin/initdb -D $HOME/postgres/pgdata
```
You should an output similar to this,
>Success. You can now start the database server using:
>
>    /Users/me/postgres/pg14/bin/pg_ctl -D /Users/me/postgres/pgdata -l logfile start

9. (Optional) You can now edit and customize the `postgresql.conf` file.
I usually change the postgres port to 5433 so that I can keep running a normal non-debug database at 5432 for other purposes.
```sh
code $HOME/postgres/pgdata/postgresql.conf
```

10. Now we can start the Database,
```sh
$HOME/postgres/pg14/bin/pg_ctl -D $HOME/postgres/pgdata -l logfile start
```
We should see this output,
> waiting for server to start.... done <br>
> server started

11. We can create a db and login run a simple query.  
```sh
$HOME/postgres/pg14/bin/createdb -p 5433 sample
$HOME/postgres/pg14/bin/psql -p 5433 sample
```
We should be logged into the psql console now, we can try to create a sample table an run some queries.
```sql
create table hello(id int, message text);
insert into hello values(1, 'Hello world!');
select * from hello;
```

### Debug Postgres in VS Code
Now that we have a running postgres server, lets start debugging it.
1. Open the Postgres source code in VS code and create a [launch.json](https://code.visualstudio.com/docs/editor/debugging#_launch-configurations) file.

2. Add launch configuration to attach to the postgres process, for example
```jsonc
{
    // Use IntelliSense to learn about possible attributes.
    // Hover to view descriptions of existing attributes.
    // For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
    "version": "0.2.0",
    "configurations": [
        {
            "name": "(lldb) Attach DB",
            "type": "cppdbg",
            "request": "attach",
            "program": "${env:HOME}/postgres/pg14/bin/postgres",
            "MIMode": "lldb",
            "targetArchitecture": "arm64"
        },
    ]
}
```
Make sure the `targetArchitecture` is set to arm64 for M1 macs. `program` must point to the `postgres` binary under `bin/` in our installation directory.

3. Now login to the database via psql in a terminal and find the postgres backend Process ID. Keep this terminal open for later use,
```sh
$HOME/postgres/pg14/bin/psql -p 5433 sample
```
```sql
select pg_backend_pid();
```
[pg_backend_pid()](https://www.postgresql.org/docs/9.4/functions-info.html) is a system function that returns the process id of the postgres backend for the current session.
> pg_backend_pid <br>
>----------------<br>
>          11340<br>
>(1 row)

4. Create a breakpoint in any function, I use `exec_simple_query` in `src/backend/tcop/postgres.c` this is where the query execution starts.

5. Now, Start Debugging (Press `F5` or `Run and Debug` -> `(lldb) Attach DB`), it will ask for a pid, paste the pg_backend_pid that we got from the psql terminal.

6. Once debugger is ready, go back to the same `psql` terminal and run a SQL query, like
```sql
select * from hello;
```
The VS code breakpoint will get triggered now, from here you can view the variables and do normal step debugging

<!-- {:refdef: style="text-align: center;"} -->
!["Debugging PG in VS Code"](/assets/vs-code-pg-debugging.webp "Debugging PG in VS Code"){:.centered}
<!-- {: refdef} -->

Thats it we can trace the flow of query execution within Postgres.
Let me know in the comments if you face any issue.

In the next post, we will see the various stages of query execution in postgres and its internal workings.

### References
1. [https://www.postgresql.org/docs/14/install-procedure.html](https://www.postgresql.org/docs/14/install-procedure.html)
1. [https://www.postgresql.org/docs/14/functions-info.html](https://www.postgresql.org/docs/14/functions-info.html#id-1.5.8.32.4.2.2.11.1.1.1)