require 'timeout'
require 'package_provider/cached_repository'
require 'package_provider/package_packer'
require 'package_provider/repository_config'

module PackageProvider
  # Class representing cached repository to avoid multiple cloninng
  class CachedPackage
    class PackingInProgress < StandardError
    end

    class << self
      def from_cache(package_hash)
        path_to_package(package_hash) if package_ready?(package_hash)
      end

      def package_ready?(package_hash)
        path = package_path(package_hash)

        Dir.exist?(path) && File.exist?("#{path}.package_ready") &&
          File.exist?(File.join(path, 'package.zip')) &&
          !File.exist?("#{path}.package_clone_lock")
      end

      def package_path(package_hash)
        File.join(PackageProvider.config.package_cache_root, package_hash)
      end

      private

      def path_to_package(package_hash)
        File.join(package_path(package_hash), 'package.zip')
      end
    end

    attr_reader :package_request

    def initialize(package_request)
      @package_request = package_request
      @path = CachedPackage.package_path(@package_request.request_hash)
      @locked_package_file = nil
    end

    def repos_ready?
      @package_request.all? do |req|
        PackageProvider::CachedRepository.cached?(
          req.commit_hash, req.checkout_mask, req.submodules?
        )
      end
    end

    def cache_package
      lock_package
      begin
        FileUtils.mkdir_p(@path)
        pack
        package_ready!
      rescue => err
        PackageProvider.logger.error("Create package failed: #{err}")
        FileUtils.rm_rf(@path)
      end
    ensure
      unlock_package
    end

    private

    def pack
      packer = PackageProvider::PackagePacker.new(@path)
      @package_request.each do |req|
        checkout_dir = PackageProvider::CachedRepository.cache_dir(
          req.commit_hash, req.checkout_mask, req.submodules?)

        req.folder_override.each do |fo|
          packer.add_folder(checkout_dir, fo)
        end
      end
      packer.flush
    end

    def package_ready!
      FileUtils.touch("#{@path}.package_ready")
    end

    def lock_package
      Timeout.timeout(2) do
        file = "#{@path}.package_clone_lock"
        locked_file = File.open(file, File::RDWR | File::CREAT, 0644)
        locked_file.flock(File::LOCK_EX)
        @locked_package_file = locked_file
      end
    rescue Timeout::Error
      raise PackingInProgress
    end

    def unlock_package
      return unless @locked_package_file
      @locked_package_file.flock(File::LOCK_UN)
      File.delete(@locked_package_file.path)
    end
  end
end