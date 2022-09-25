---
layout: post
title:  "PostgreSQL Storage Internals"
date:   2022-08-15 16:37:41 +0530
tags: postgres 
---

In this post let's see how data is stored internally in Postgres, the database's physical storage, file layout etc. And also how understanding this can help you writer better and efficient SQL Queries.

### Where is the data stored?
Postgres stores the data files under a folder, this folder is specified by the $PGDATA environment variable.
To find this folder we can run,  
``` bash
$ echo $PGDATA
# In my system this prints => /Users/<my-user-name>/Library/Application Support/Postgres/var-14
# I have installed PG using homebrew on macOS
```

Under this PGDATA folder, the data files are stored under `base` folder.
It also contains other folders like 
- `global` which contains global metadata like pg_database
- `pg_wal` which contains the Write-ahead log

But let's focus on the `base` folder for now.

!["PG Data folder"](/assets/postgres-internals-01.webp "PG Data folder")

Here each database gets one subfolder, so from the above image `14020` is a data folder for one particular database. All the tables for that particular database are stored within that folder as files.

So what does this number mean? How do we correspond this number to o