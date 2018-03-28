# Backup Website and MySQL to S3

A simple wrapper for the [mys3ql](https://github.com/airblade/mys3ql) Rubygem for incremental mysql
backups, and [GNU Tar](https://www.gnu.org/software/tar/).

Key assumptions made:

* All pertinent files are in /var/www.
* All databases except system databases will be backed up.
* Mysql database only.
* All databases should have binlogs turned on.
* A restore will trigger an entire restore of all databases and files.
* The **GNU** (not BSD) version of _tar_.  The GNU version includes --listed-incremental, which is needed for incremental backups.

## Installation

### Ubuntu

```bash

sudo apt install ruby ruby-dev zlib1g-dev
sudo gem install main activesupport

```

### Configure Mysql Bin Logging

Add the following to your `my.cnf`, or on Ubuntu you might want to add it to `/etc/mysql/mysql.conf.d/mysqld.conf`
```
[mysqld]
...
server-id               = 1     # Set it nicely if using replication
log_bin                 = /var/log/mysql/mysql-bin.log   #  Or your favorite location

```

### Grant user read access to mysql binary logs and also to your web root

```bash
# Make sure you know what the group ownership is, for your web root.
sudo usermod -a -G www-data ubuntu
sudo usermod -a -G mysql ubuntu
```


## Usage

### Take your backups.

```bash

# Once per day:
website_backup backup app_name daily
# Once per week:
website_backup backup app_name weekly
# Once per month:
website_backup backup app_name monthly
# Every so often:
website_backup backup app_name incremental
```

### Restore your application

```bash
website_backup restore app_name
```


* Everything in /var/www 