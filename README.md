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

### Set up your crontab.  

* Use `crontab -e` to edit cron configuration.

**Sample Crontab configuration**

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