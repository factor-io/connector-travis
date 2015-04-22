require 'spec_helper'

describe TravisConnectorDefinition do
  before do
    @github_token = ENV['GITHUB_API_KEY']
    @access_token = ENV['TRAVIS_ACCESS_TOKEN']
    @runtime = Factor::Connector::Runtime.new(TravisConnectorDefinition)
  end

  describe :rebuild do
    it 'fails if github_token and access_token are passed' do
      @runtime.run([:rebuild], github_token:@github_token, access_token:@access_token)
      expect(@runtime).to fail 'Must specify :access_token or :github_token, but not both'
    end

    it 'fails if neither github_token and access_token are passed' do
      @runtime.run([:rebuild], {})
      expect(@runtime).to fail 'Must specify :access_token or :github_token'
    end

    it 'can authenticate with access_token' do
      @runtime.run([:rebuild], access_token:@access_token)
      expect(@runtime).to message info:"Connected to Travis with an access token"
    end

    it 'can authenticate with github_token' do
      @runtime.run([:rebuild], github_token:@github_token)
      expect(@runtime).to message info:"Connected to Travis with a Github token"
    end

    it 'fails if no repo is specified' do
      @runtime.run([:rebuild], github_token:@github_token)
      expect(@runtime).to fail 'Repo (:repo) is required'
    end

    it 'fails if bad repo is specified' do
      fake_repo = 'skierkowski/this-does-not-exist'
      @runtime.run([:rebuild], github_token:@github_token, repo:fake_repo)
      expect(@runtime).to fail "Failed to find the repo '#{fake_repo}'"
    end

    it 'can rebuild with build_number' do
      @runtime.run([:rebuild], github_token:@github_token, repo:'skierkowski/hello', build:1)
      expect(@runtime).to message info:"Looking up build 1"
      expect(@runtime).to respond
    end

    it 'fails on bad build number' do
      @runtime.run([:rebuild], github_token:@github_token, repo:'skierkowski/hello', build:99999)
      expect(@runtime).to message info:"Looking up build 99999"
      expect(@runtime).to fail 'No such build was found'
    end

    it 'can rebuild without build_number' do
      @runtime.run([:rebuild], github_token:@github_token, repo:'skierkowski/hello')
      expect(@runtime).to respond

      data = @runtime.logs.last[:data]

      expect(data).to be_a(Hash)
      expect(data).to include(:repository_id)
      expect(data).to include(:commit_id)
      expect(data).to include(:number)
      expect(data).to include(:pull_request)
      expect(data).to include(:pull_request_number)
      expect(data).to include(:pull_request_title)
      expect(data).to include(:config)
      expect(data).to include(:state)
      expect(data).to include(:started_at)
      expect(data).to include(:finished_at)
      expect(data).to include(:duration)
      expect(data).to include(:job_ids)
    end

  end
end
