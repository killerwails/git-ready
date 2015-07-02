require 'contracts'
require 'rugged'

module Workspace
  include Contracts

  Contract String => Bool
  def self.git_repository?(path)
    true if Rugged::Repository.new path
  rescue Rugged::OSError, Rugged::RepositoryError
    false
  end

  Contract String, String, String => Any
  def self.configure_remotes(path, origin_url, upstream_url)
    repository = Rugged::Repository.new path
    repository.remotes.set_url 'origin', origin_url
    repository.remotes.set_url 'upstream', upstream_url
  end

  Contract String, String => Any
  def self.clone(url, path)
    credentials = Rugged::Credentials::SshKeyFromAgent.new username: 'git'
    Rugged::Repository.clone_at(url, path, credentials: credentials) unless git_repository? path
  end

  Contract ArrayOf[Hash] => Any
  def self.setup(repositories)
    progress = ProgressBar.new repositories.length
    repositories.each do |repo|
      # binding.pry
      path = "#{Settings.workspace}/#{repo[:origin][:name]}"
      clone repo[:origin][:ssh_url], path
      configure_remotes path, repo[:origin][:ssh_url], repo[:upstream][:ssh_url]
      progress.increment!
    end
  end
end
