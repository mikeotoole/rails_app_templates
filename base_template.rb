# This template contains the basic gems and configuration I like to have in all Rails apps.

# Add the current directory to the path Thor uses to look up files.
def source_paths
  Array(super) +
    [File.join(File.expand_path(File.dirname(__FILE__)), 'base_templete_files')]
end

ruby_version = '2.2.2'

use_heroku = true if yes?('Use Heroku?')
create_git_repo = true if yes?('Create git repo?')

if create_git_repo
  git :init
  git add: '.'
  git commit: "-a -m 'Initial commit with default rails app.'"
end

###
# Create new Gemfile
###

remove_file "Gemfile"
run "touch Gemfile"
add_source 'https://rubygems.org'

gem 'coffee-rails', '~> 4.1.0'
gem 'foundation-rails'
gem 'haml-rails'
gem 'jquery-rails'
gem 'pg'
gem 'rails', '4.2.3'
gem 'sass-rails', '~> 5.0'
gem 'simple_form'
gem 'turbolinks'
gem 'uglifier', '>= 1.3.0'
if use_heroku
  gem 'unicorn'
  gem 'unicorn-worker-killer'
  # gem 'newrelic_rpm'
end

if use_heroku
  # add gems for a particular group
  gem_group :production, :staging do
    gem 'rails_12factor'
  end
end

gem_group :development do
  gem 'annotate'
  gem 'better_errors'
  gem 'brakeman'
  gem 'binding_of_caller'
  if use_heroku
    gem 'foreman'
  end
  gem 'guard-rspec'
  gem 'rails_best_practices'
  gem 'rubocop', require: false
end

gem_group :development, :test do
  gem 'bullet'
  gem 'pry-rails'
  gem 'spring'
end

gem_group :test do
  gem 'database_cleaner'
  gem 'factory_girl_rails'
  gem 'rspec-rails'
  gem 'simplecov', require: false
end

# Set ruby version in Gemfile. This will work with Heroku and RVM.
insert_into_file 'Gemfile', "\nruby \'#{ruby_version}\'",
                 after: "source 'https://rubygems.org'\n"

###
# Add to .gitignore
###

insert_into_file '.gitignore',
                 "\n\n# Ignore code coverage generated by SimpleCov.\ncoverage",
                 after: '/tmp'

###
# Add configuration.
###

copy_file '.rubocop.yml'

if use_heroku
  copy_file 'Procfile'

  inside 'config' do
    copy_file 'unicorn.rb'
  end
end

inside 'config' do
  copy_file 'brakeman.yml'

  insert_into_file 'application.rb', after: /^.*directory are automatically loaded.*\n$/ do
    <<-CODE
\n    config.generators do |g|
      g.test_framework :rspec, fixture: true
      g.fixture_replacement :factory_girl, dir: 'spec/factories'
      g.view_specs false
      g.controller_specs true
      g.routing_specs false
      g.request_specs false
      g.helper_specs false
      g.javascripts false
      g.stylesheets false
      g.helper false
      g.jbuilder true
      g.template_engine false
    end
    CODE
  end

  inside 'environments' do
    insert_into_file 'development.rb', after: /^.*Settings specified here will.*\n$/ do
      <<-CODE
\n  # Bullet alerts you when to add eager loading (N+1 queries),
  # when you're using eager loading that isn't necessary and when you
  # should use counter cache.
  # See https://github.com/flyerhzm/bullet
  config.after_initialize do
    Bullet.enable = true
    Bullet.alert = true
    Bullet.bullet_logger = false
    Bullet.console = true
    Bullet.growl = false
    Bullet.xmpp = false
    Bullet.rails_logger = true
  end
      CODE
    end

    insert_into_file 'test.rb', after: /^.*Settings specified here will.*\n$/ do
      <<-CODE
\n  # Bullet alerts you when to add eager loading (N+1 queries),
  # when you're using eager loading that isn't necessary and when you
  # should use counter cache.
  # See https://github.com/flyerhzm/bullet
  config.after_initialize do
    Bullet.enable = true
    Bullet.bullet_logger = true
    Bullet.raise = true
  end
CODE
    end
  end
end

inside 'config' do
  remove_file 'database.yml'
  create_file 'database.yml' do <<-EOF
default: &default
  adapter: postgresql
  host: localhost
  pool: 5
 
development:
  <<: *default
  database: #{app_name}_development
 
# Warning: The database defined as "test" will be erased and
# re-generated from your development database when you run "rake".
# Do not set this db to the same as development or production.
test:
  <<: *default
  database: #{app_name}_test
 
production:
  <<: *default
  database: #{app_name}_production
 
EOF
  end
end

after_bundle do
  # Spring was causing rails and rake commands to hang so removing it for now.
  run 'bin/spring binstub --remove --all'
  run 'rails generate simple_form:install --foundation'
  run 'rails generate rspec:install'
  run 'guard init rspec'
  run 'rails_best_practices -g'
  run 'rails g foundation:install --force --haml'
  run 'bundle binstubs rails_best_practices brakeman rubocop'

  ###
  # Add Rake Tasks
  ###

  inside 'lib/tasks' do
    copy_file 'auto_annotate_models.rake'
    copy_file 'reports.rake'
  end

  ###
  # Remove unwanted files
  ###
  run "rm app/helpers/application_helper.rb"
  run "rm app/views/layouts/application.html.erb"
  run "rm -r test"
  run "rm db/seeds.rb"

  if create_git_repo
    git add: '.'
    git commit: "-a -m 'Base template setup.'"
  end
end

