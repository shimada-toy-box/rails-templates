# frozen_string_literal: true

require 'shellwords'

# Variables
APP_NAME = app_name
# Transform the app name from slug to human-readable name e.g. nimble-web -> Nimble
APP_NAME_HUMANIZED = app_name.split(/[-_]/).map(&:capitalize).join(' ').gsub(/ Web$/, '')
DOCKER_REGISTRY_HOST = 'docker.io'
DOCKER_IMAGE = "nimblehq/#{APP_NAME}".freeze
RUBY_VERSION = '3.0.1'
POSTGRES_VERSION = '14.4'
REDIS_VERSION = '5.0.7'
# Variants
API_VARIANT = options[:api] || ENV['API'] == 'true'
WEB_VARIANT = !API_VARIANT
# Addons
DEFAULT_ADDONS = {
  docker: 'Docker',
  heroku: 'Heroku'
}.freeze

if WEB_VARIANT
  NODE_VERSION = '16.13.2'
  NODE_SOURCE_VERSION = '16' # Used in Dockerfile https://github.com/nodesource/distributions
end

def apply_template!(template_root)
  use_source_path template_root

  delete_test_folder

  template 'Gemfile.tt', force: true

  copy_file '.flayignore'
  copy_file 'Dangerfile'
  copy_file '.rubocop.yml'
  copy_file '.reek.yml'

  template '.ruby-gemset.tt'
  template '.ruby-version.tt', force: true
  template '.tool-versions.tt'
  copy_file '.editorconfig'
  copy_file 'Procfile'
  copy_file 'Procfile.dev'
  template 'README.md.tt', force: true

  apply 'bin/template.rb'
  apply 'config/template.rb'
  apply '.gitignore.rb'

  after_bundle do
    use_source_path template_root

    # Stop the spring before using the generators as it might hang for a long time
    # Issue: https://github.com/rails/spring/issues/486
    run 'spring stop'

    apply 'spec/template.rb'
  end

  # Add-ons - [Default]
  DEFAULT_ADDONS.each_key do |addon|
    apply ".template/addons/#{addon}/template.rb"
  end

  post_default_addons_install

  # Add-ons - [Optional]
  apply '.template/addons/hotwire/template.rb' if WEB_VARIANT && yes?(install_addon_prompt('Hotwire'))
  apply '.template/addons/github/template.rb' if yes?(install_addon_prompt('Github Action and Wiki'))
  apply '.template/addons/semaphore/template.rb' if yes?(install_addon_prompt('SemaphoreCI'))
  apply '.template/addons/nginx/template.rb' if yes?(install_addon_prompt('Nginx'))
  apply '.template/addons/phrase_app/template.rb' if yes?(install_addon_prompt('PhraseApp'))
  apply '.template/addons/devise/template.rb' if yes?(install_addon_prompt('Devise'))

  # Variants
  apply '.template/variants/api/template.rb' if API_VARIANT
  apply '.template/variants/web/template.rb' if WEB_VARIANT

  # A list necessary jobs that run before complete, ex: Fixing rubocop on Ruby files that generated by Rails
  apply '.template/hooks/before_complete/fix_rubocop.rb'
  apply '.template/hooks/before_complete/report.rb'
end

# Set Thor::Actions source path for looking up the files
def source_paths
  @source_paths
end

# Prepend the required paths to the source paths to make the template files in those paths available
def use_source_path(source_path)
  @source_paths.unshift(source_path)
end

def remote_repository
  require 'tmpdir'
  tempdir = Dir.mktmpdir('rails-templates')
  at_exit { FileUtils.remove_entry(tempdir) }

  git clone: [
    '--quiet',
    'https://github.com/nimblehq/rails-templates.git',
    tempdir
  ].map(&:shellescape).join(' ')

  if (branch = __FILE__[%r{rails-templates/(.+)/template.rb}, 1])
    Dir.chdir(tempdir) { git checkout: branch }
  end

  tempdir
end

def delete_test_folder
  FileUtils.rm_rf('test')
end

def install_addon_prompt(addon)
  "Would you like to add the #{addon} addon? [yN]"
end

def post_default_addons_install
  puts <<~INFO
    These default addons were installed:
    #{DEFAULT_ADDONS.values.map { |addon| "* #{addon}" }.join("\n")}
  INFO
end

def get_content_between(content, string_start, string_end)
  content[/#{Regexp.escape(string_start)}(.*)#{Regexp.escape(string_end)}/m, 1].strip
end

# Init the source path
@source_paths ||= []

# Setup the template root path
# If the template file is the url, clone the repo to the tmp directory
template_root = __FILE__ =~ %r{\Ahttps?://} ? remote_repository : __dir__
use_source_path template_root

# Init the template helpers
require "#{template_root}/.template/lib/template"

@template_instructions = Template::Messages.new
@template_errors = Template::Errors.new

if ENV['ADDON']
  addon_template_path = ".template/addons/#{ENV['ADDON']}/template.rb"

  abort 'This addon is not supported' unless File.exist?(File.expand_path(addon_template_path, template_root))

  apply addon_template_path
else
  apply_template!(template_root)
end
