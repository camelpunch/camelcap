require 'capistrano/ext/multistage'
set(:repository) { "git@github.com:camelpunch/#{application}.git" }
set(:deploy_to) { "/websites/#{domain}" }
set :default_stage, "production"
set :user, "ubuntu"
ssh_options[:keys] = ["#{ENV['HOME']}/.ssh/camelpunch.pem"]
  
server 'camelpunch.com', :app, :web
role :db, 'camelpunch.com', :primary => true

set :scm, :git

task :build_gems do
  run "cd #{release_path} && rake gems:build RAILS_ENV=#{rails_env}"
end

namespace :deploy do
  namespace :apache do
    task :reload do
      run "#{sudo} service apache2 reload"
    end
  end

  namespace :web do
    task :disable do
      run "#{sudo} a2dissite #{domain}"
    end

    task :enable do
      run "#{sudo} a2ensite #{domain}"
    end
  end

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

  task :copy_sites_available do
    run "#{sudo} cp #{current_path}/config/apache/* /etc/apache2/sites-available/"
  end

  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

after "deploy:web:enable", "deploy:apache:reload"
after "deploy:web:disable", "deploy:apache:reload"

after "deploy:setup", "deploy:fix_setup_permissions"
after "deploy", "deploy:copy_sites_available"
after "deploy", "deploy:touch_and_permit_log_files"

