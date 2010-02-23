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

task :touch_and_permit_log_files do
  %w(production staging).each do |env|
    log_path = "#{deploy_to}/shared/log/#{env}.log"
    run "#{sudo} touch #{log_path}"
    run "#{sudo} chown ubuntu.ubuntu #{log_path}"
    run "#{sudo} chmod 0666 #{log_path}"
  end
end

after "deploy:setup", "fix_setup_permissions"
after "deploy", "touch_and_permit_log_files"

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

after :deploy do
  run "cd #{current_path} && rake gems:build RAILS_ENV=#{rails_env}"
end

