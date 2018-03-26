require 'active_support'
require 'active_support/core_ext'
require 'fog/aws'
require 'server_backups/version'
require 'server_backups/config'
require 'server_backups/s3'
require 'server_backups/backup_base'
require 'server_backups/website_backup'

Time.zone = 'UTC'

module ServerBackups
end
