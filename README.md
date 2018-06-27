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

### Alpine Linux

The following instructions work for Alpine Linux

```bash
apk add --no-cache ruby ruby-rake ruby-io-console ruby-bigdecimal ruby-json ruby-bundler \
                   tar gzip zlib zlib-dev dcron tzdata

cat > ~/.gemrc <<EOF
---
gem: --no-ri --no-rdoc
EOF

gem install rtbackup

```

### Ubuntu

```bash

sudo apt-get install -y ruby ruby-dev zlib1g-dev
sudo gem install rtbackup

```

### Configure Mysql Binary Logging

Make sure that binary logging is enabled on your mysql server.  The following settings
need to be enabled in mysql configuration files.  On Debian-based Linux distros this
means editing `/etc/mysql/mysql.conf.d/mysqld.cnf`, though Alpine Linux and others will
involve editing `/etc/mysql/my.cnf`.

```
[mysqld]
# ...
#  Make sure that you know how to use this setting properly if you're using replication.
server-id               = 1
log_bin                 = /var/log/mysql/mysql-bin  #  Make sure this matches the
                                                    #  bin_log setting in your backup_conf.yml file.
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

## Set up backup_conf.yml

Set up a configuration file with the following command:

```bash
rtbackup create_config
```

Now edit `~/.backup_conf.yml` and adjust it to fit your app's needs.

## Schedule backups to run.

Schedule your backups by running

```bash
rtbackup crontab
```

This will enable the recommended backup schedule:

* Hourly incremental backups from 1am to 11pm
* Daily full backups at midnight
* Weekly full backups on Sunday
* Monthly full backups on the first of the month

Full backups are all the same, but their retention periods differ.

Change the schedule by running the command:

```bash
crontab -e
```

See the [crontab manual pages](https://linux.die.net/man/5/crontab) or look online for tutorials
on how to edit cron schedules.

That's all!  Your backups are now scheduled.  You may run `rtbackup daily` in order to get your first
full backup.

# Command line parameters

#### 1) For taking backups:

some examples

```bash
# Take a full backup and store it in the monthly backups location.
rtbackup monthly

# Take a full backup as normal, but instead of backing up all databases,
# only back up `mydatabase`.
rtbackup daily -d mydatabase

rtbackup daily -f  # only back up the files, not the database(s)
rtbackup daily -b  # only back up the database(s), not the files

# Take an incremental backup, but load the given configuration file.
rtbackup incremental -c /etc/my_backup_configuration.cnf

```

#### 2) List (or search) time zones for help with configuration

```bash
rtbackup zones  # list all
rtbackup zones america  # case insensitive search for zones containing a string
```

#### 3) Restore backups

```bash
# Restore up to the latest backup data available on s3
rtbackup restore

# Restore up to two days ago at 3pm in the configured
# time zone (see config file).
rtbackup restore --up_to='two days ago at 3:00 PM'

# To make it easier to decide what time your restore point
# should be, you can write the restore point time in any time
# zone and it will be translated to the server's normal time zone.
#
# This way, if the server is in UTC and you're in Singapore, you
# don't necessarily have to do any confusing time maths in order
# to restore back to what time it was before you made a mistake
# and updated a wordpress plugin.  ;)
rtbackup restore --up_to='March 28 12:00 PM' --time_zone='Singapore'

```

```
NAME
  rtbackup

SYNOPSIS
  rtbackup (restore|zones) backup_type [options]+

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
