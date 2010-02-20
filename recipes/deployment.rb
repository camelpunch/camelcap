require 'capistrano/ext/multistage'
set(:repository) { "git@github.com:camelpunch/#{application}.git" }
set :default_stage, "production"
set :domain, "camelpunch.com"
set :user, "ubuntu"
ssh_options[:keys] = ["#{ENV['HOME']}/.ssh/camelpunch.pem"]
default_environment['PATH'] = 
  '/var/lib/gems/1.9.1/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  
server domain, :app, :web
role :db, domain, :primary => true

set :scm, :git

task :fix_setup_permissions do
  run "#{sudo} chown ubuntu.ubuntu #{deploy_to} #{deploy_to}/*"
end

after "deploy:setup", "fix_setup_permissions"

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

