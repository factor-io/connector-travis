require 'factor/connector/definition'
require 'travis'

class TravisConnectorDefinition < Factor::Connector::Definition
  id :travis

  def initialize_travis(params)
    access_token = params.varify(:access_token, name:'Access Token')
    github_token = params.varify(:github_token, name:'Github Token')
    use_pro      = params.varify(:pro, one_of:[true,false], default:false)

    fail 'Must specify :access_token or :github_token' unless access_token || github_token
    fail 'Must specify :access_token or :github_token, but not both' if access_token && github_token

    travis = use_pro ? Travis::Pro : Travis
    product_name = travis.class.name == 'Pro' ? 'Travis Pro' : 'Travis'

    begin
      if access_token
        info "Connecting to #{product_name} with an access token"
        travis.access_token = access_token
        travis::User.current # forces a validation of the access_token
        info "Connected to #{product_name} with an access token"
      elsif github_token
        info "Connecting to #{product_name} with a Github token"
        travis.github_auth github_token
        info "Connected to #{product_name} with a Github token"
      end
    rescue
      fail "Authentication failed, check your tokens"
    end

    travis
  end


  action :rebuild do |params|
    travis       = initialize_travis(params)
    build_number = params.varify(:build)
    repo_slug    = params.varify(:repo, required:true)
    build        = nil

    info "Looking up repo `#{repo_slug}`"
    begin
      repo = travis::Repository.find(repo_slug)
    rescue
      fail "Failed to find the repo '#{repo_slug}'"
    end

    begin
      build = if build_number
        info "Looking up build #{build_number}"
        repo.build(build_number)
      else
        info 'Looking up last build'
        build = repo.last_build
      end
    rescue
    end

    fail "No such build was found" unless build

    info "Restarting build ##{build.number}"
    begin
      build.restart
    rescue
      fail 'Failed to restart the build'
    end

    build_info = {
      repository_id:       build.repository_id,
      commit_id:           build.commit_id,
      number:              build.number,
      pull_request:        build.pull_request,
      pull_request_number: build.pull_request_number,
      pull_request_title:  build.pull_request_title,
      config:              build.config,
      state:               build.state,
      started_at:          build.started_at,
      finished_at:         build.finished_at,
      duration:            build.duration,
      job_ids:             build.job_ids
    }

    respond build_info
  end
end