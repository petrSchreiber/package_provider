class RepoConnectionPool
  def initialize
    @repos = {}
  end

  def fetch(repo)
    repo_config = PackageProvider::RepositoryCacheList.find(req.repo)
    @repos[repo] ||= ConnectionPool.new(
      size: repo_config[:pool_size],
      timeout: repo_config[:timeout]
    ) do
      PackageProvider::CachedRepository.new(
        repo,
        RepositoryCacheList.find(repo)
      )
    end
  end
end
