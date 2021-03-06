describe PackageProvider::RepositoryRequest do
  let(:subject) do
    part = PackageProvider::RepositoryRequest.new(
      'package_provider', 'fake_commit', nil)

    part.add_folder_override('b', 'a')
    part.add_folder_override('.gitmodules', nil)
    part.add_folder_override('a', 'b')

    part
  end

  let(:subject2) do
    part = PackageProvider::RepositoryRequest.new(
      'fake_repo', 'fake_commit', nil)

    part.add_folder_override('b', 'b')
    part.add_folder_override('a')
    part.add_folder_override('b')
    part.add_folder_override('a', 'a')

    part
  end

  let(:subject3) do
    PackageProvider::RepositoryRequest.new(
      'fake_repo', 'fake_commit', 'fake_branch')
  end

  describe '#submodules?' do
    it 'sets git modules true when .gitmodules is present' do
      expect(subject.submodules?).to be true
    end
    it 'not sets git modules false when .gitmodules is missing' do
      expect(subject2.submodules?).to be false
    end
  end

  describe '#to_json' do
    it 'returns json formated class with folder overide' do
      expect(subject.to_json).to eql(
        MultiJson.dump(
          repository: 'package_provider',
          branch: nil,
          commit: 'fake_commit',
          folderOverride: [
            { source: 'b', destinationOverride: 'a' },
            { source: '.gitmodules', destinationOverride: nil },
            { source: 'a', destinationOverride: 'b' }]))
    end
    it 'returns json formated class without folder override' do
      expect(subject3.to_json).to eql(
        MultiJson.dump(
          repository: 'fake_repo',
          branch: 'fake_branch',
          commit: 'fake_commit',
          folderOverride: nil))
    end
  end

  describe '#normalize!' do
    it 'adds default folder override' do
      subject3.normalize!
      expect(subject3.folder_override).to eq(
        [PackageProvider::RepositoryRequest::FolderOverride.new(
          *PackageProvider.config.default_folder_override)]
      )
    end
    it 'rewrites repo alias' do
      subject.normalize!
      expect(subject.repo).to eq(
        PackageProvider::RepositoryAlias.find('package_provider').url
      )
    end
  end

  describe '#checkout_mask' do
    it 'returns checkout mask' do
      expect(subject.checkout_mask).to eq(['b', '.gitmodules', 'a'])
    end
  end
end
