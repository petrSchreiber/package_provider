$LOAD_PATH << 'lib'
require 'sidekiq'
require 'package_provider'

PackageProvider.setup
ReposPool = RepoConnectionPool.new
