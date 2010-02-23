require 'capistrano/ext/multistage'
set(:repository) { "git@github.com:camelpunch/#{application}.git" }
set :deploy_to { "/websites/#{domain}" }
set :default_stage, "production"
set :user, "ubuntu"
ssh_options[:keys] = ["#{ENV['HOME']}/.ssh/camelpunch.pem"]
default_environment['PATH'] = 
  '/var/lib/gems/1.9.1/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  
server 'camelpunch.com', :app, :web
role :db, 'camelpunch.com', :primary => true

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

task :build_gems do
  run "cd #{current_path} && rake gems:build RAILS_ENV=#{rails_env}"
end

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

after "deploy:setup", "fix_setup_permissions"
after "deploy", "touch_and_permit_log_files"
after :deploy, "build_gems"

