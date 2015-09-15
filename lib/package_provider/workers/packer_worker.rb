class PackageProvider::PackerWorker
  include Sidekiq::Worker
  sidekiq_options queue: :repository_management, retry: false

end
