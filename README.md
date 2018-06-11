# Backup Website and Mysql databases to S3

Automated backup and recovery solution capable of restoring files and databases
to a given point in time.

* Incremental backups of files using [GNU Tar](https://www.gnu.org/software/tar/)
* Incremental backups of databases using binary logging
* Files are stored in a structured manner within an Amazon S3 bucket using
[AWS S3 SDK gem](https://github.com/aws/aws-sdk-ruby)

**Key assumptions made:**

* All databases except system databases will be backed up.
* Mysql database only.
* Mysql binary logging is turned on.
* The **GNU** (not BSD) version of _tar_.  The GNU version includes --listed-incremental, which is needed for incremental backups.

## Installation

Download the installation package from https://gitlab.com/zigzagau/server_backups/tags
Find the latest tag and download server_backups-0.x.x.gem from there.
Copy that file to your server.

### Ubuntu

```bash

sudo apt install ruby ruby-dev zlib1g-dev
sudo gem install server_backups-0.x.x.gem

```

### Configure Mysql Bin Logging

Add the following to your `my.cnf`, or on Ubuntu you might want to add it to `/etc/mysql/mysql.conf.d/mysqld.conf`
```
[mysqld]
...
server-id               = 1     # Set it nicely if using replication
log_bin                 = /var/log/mysql/mysql-bin.log   #  Or your favorite location

```

Then restart mysql:

```
sudo service mysql restart
```

### Grant user read access to mysql binary logs and also to your web root

```bash
# Make sure you know what the group ownership is, for your web root.
sudo usermod -a -G www-data ubuntu
sudo usermod -a -G mysql ubuntu
```

###

## Usage

### Set up a configuration file

Copy `backup_conf.sample.yml` to `~/.backup_conf.yml` and edit the settings.
Alternatively you can put the file anywhere, and then specify the path to the file
using the `-c` parameter, or even pipe a config file in through stdin.

The latter option is useful if you'd like to keep passwords and keys in variables,
rather than saving them to the filesystem.

```bash
envsubst < back_conf.yml.tmpl | server_backup daily -c -
```

### Set up your crontab.

* Use `crontab -e` to edit cron configuration.

**Sample Crontab configuration**

```

# Once per month:
3 0 1 * * /usr/local/bin/server_backup monthly
# Once per week:
5 0 * * 0 /usr/local/bin/server_backup weekly
# Once per day:
5 0 *  * 1-6 /usr/local/bin/server_backup daily
# And incremental backups once per hour
5 1-23 * * * /usr/local/bin/server_backup incremental

```

### Command line parameters

#### 1) For taking backups:

some examples

```bash
# Take a full backup and store it in the monthly backups location.
server_backup monthly

# Take a full backup as normal, but instead of backing up all databases,
# only back up `mydatabase`.
server_backup daily -d mydatabase

server_backup daily -f  # only back up the files, not the database(s)
server_backup daily -b  # only back up the database(s), not the files

# Take an incremental backup, but load the given configuration file.
server_backup incremental -c /etc/my_backup_configuration.cnf

```

#### 2) List (or search) time zones for help with configuration

```bash
server_backup zones  # list all
server_backup zones america  # case insensitive search for zones containing a string
```

#### 3) Restore backups

```bash
# Restore up to the latest backup data available on s3
server_backup restore

# Restore up to two days ago at 3pm in the configured
# time zone (see config file).
server_backup restore --up_to='two days ago at 3:00 PM'

# To make it easier to decide what time your restore point
# should be, you can write the restore point time in any time
# zone and it will be translated to the server's normal time zone.
#
# This way, if the server is in UTC and you're in Singapore, you
# don't necessarily have to do any confusing time maths in order
# to restore back to what time it was before you made a mistake
# and updated a wordpress plugin.  ;)
server_backup restore --up_to='March 28 12:00 PM' --time_zone='Singapore'

```

```
NAME
  server_backup

SYNOPSIS
  server_backup (restore|zones) backup_type [options]+

PARAMETERS
  backup_type (1 -> symbol(backup_type))
      specifies the backup type to perform [incremental | daily | weekly |
      monthly]
  --config=config, -c (0 ~> config=~/.backup_conf.yml)
      load configuration from YAML file
  --database=database, -d (default ~> database=all)
      Which database to back up, defaults to all non-system databases.
  --db_only, -b (default ~> false)
      If specified
  --files_only=[files_only], -f (de ~> files_only)
      Only work with files.
  --help, -h
```

### Restore your application

```bash
website_backup restore app_name
```


* Everything in /var/www
