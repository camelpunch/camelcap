require 'capistrano/ext/multistage'
set(:repository) { "git@ab.jandaweb.com:#{application}.git" }
set :default_stage, "production"
set :domain, "ab.jandaweb.com"
server domain, :app, :web
role :db, domain, :primary => true

set :scm, :git

namespace :deploy do
  desc 'Display the names of the servers for this task'
  task :display_servers do
    servers = roles[:web].servers.map { |server| server.host }.join(', ')
    logger.trace "\nDeploying to #{servers}\n\n"
  end
end

namespace :passenger do
  desc "Restart Application"
  task :restart do
    run "touch #{current_path}/tmp/restart.txt"
  end
end

namespace :deploy do
  %w(start restart).each do |name|
    task name, :roles => :app do
      passenger.restart end
  end
end

before :deploy, "deploy:display_servers"
