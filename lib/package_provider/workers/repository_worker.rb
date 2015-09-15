require 'package_provider/repo_connection_pool'

class PackageProvider::RepositoryWorker
  include Sidekiq::Worker
  sidekiq_options queue: :clone_repository, retry: false # TODO: set false, setup retry count to 3 (for case of stash issues), see retry times at wiki, first 3 under 1m

  def perform(repo, treeish, paths, use_submodules = false)
    repo_config = PackageProvider::RepositoryCacheList.find(req.repo)
    c_pool = ReposPool.fetch(repo)
    c_pool.with(timeout: repo_config[:timeout]) do
      cached_clone(treeish, paths, use_submodules)
    end
  end
end
