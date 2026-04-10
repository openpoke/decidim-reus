# frozen_string_literal: true

lock "3.20"

set :application, "decidim"
set :repo_url, "https://github.com/openpoke/decidim-reus.git"
set :linked_files, fetch(:linked_files, []).push(*%w(
                                                   config/database.yml
                                                   .rbenv-vars
                                                 ))
set :linked_dirs, fetch(:linked_dirs, []).push(*%w(
                                                 log
                                                 tmp/pids
                                                 tmp/cache
                                                 tmp/sockets
                                                 vendor/bundle
                                                 public/system
                                                 public/cache
                                                 node_modules
                                                 public/packs
                                                 public/decidim-packs
                                                 public/uploads
                                                 storage
                                               ))
set :rbenv_type, :fullstaq
set :passenger_restart_with_touch, true

# TODO
# set :sidekiq_role, :app
# set :sidekiq_service_unit_name, 'sidekiq-decidim'
set :nvm_type, :system
set :nvm_node_path, "/var/lib/nvm/versions/node/"
set :nvm_path, "/var/lib/nvm/"
set :nvm_node, "v22.14.0" # tls
set :keep_releases, 10

set :ssh_options, { keys: %w(~/.ssh/id_rsa), forward_agent: true, auth_methods: %w(publickey) }

Rake::Task["deploy:compile_assets"].clear

namespace :deploy do
  desc "Compile assets"
  task :compile_assets => [:set_rails_env] do
    invoke "deploy:install_dependencies"
    invoke "deploy:assets_precompile"
  end

  desc "Install dependencies"
  task :install_dependencies do
    on roles(:app) do
      within release_path do
        execute :npm, "ci"
      end
    end
  end

  desc "Assets precompile"
  task :assets_precompile do
    on roles(:all) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rails, "assets:precompile"
        end
      end
    end
  end
end
