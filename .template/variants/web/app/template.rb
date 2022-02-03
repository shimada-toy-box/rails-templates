# Javascript
directory 'app/javascript'

if File.exist?('app/javascript/packs/application.js')
  append_to_file 'app/javascript/packs/application.js' do
    <<~JAVASCRIPT
      import 'core-js/stable';
      import 'regenerator-runtime/runtime';

      import 'translations/translations';

      import 'initializers/';
      import 'screens/';
    JAVASCRIPT
  end
else
  @template_errors.add <<~ERROR
    Cannot import the dependencies to `app/javascript/packs/application.js`
    Content: import 'core-js/stable';
             import 'regenerator-runtime/runtime';

             import 'translations/translations';

             import 'initializers/';
             import 'screens/';
  ERROR
end

# Stylesheets
remove_file 'app/assets/stylesheets/application.css'
directory 'app/assets/stylesheets'

run 'yarn build:css'
gsub_file 'app/assets/config/manifest.js', "//= link_directory ../stylesheets .css\n", ''
append_to_file 'app/assets/config/manifest.js', '//= link_tree ../builds'

# Controllers
directory 'app/controllers/concerns'
inject_into_class 'app/controllers/application_controller.rb', 'ApplicationController' do
  <<~RUBY.indent(2)
    include Localization
  RUBY
end

# Views
if File.exist?('app/views/layouts/application.html.erb')
  gsub_file 'app/views/layouts/application.html.erb', /<html>/ do
    "<html lang='<%= I18n.locale %>'>"
  end

  insert_into_file 'app/views/layouts/application.html.erb', before: %r{</head>} do
    <<~HTML.indent(2)
      <%= javascript_pack_tag 'application' %>
    HTML
  end
else
  @template_errors.add <<~ERROR
    Cannot insert the lang attribute into html tag into `app/views/layouts/application.html.erb`
    Content: <html lang='<%= I18n.locale %>'>
             <%= javascript_pack_tag 'application' %>
  ERROR
end
