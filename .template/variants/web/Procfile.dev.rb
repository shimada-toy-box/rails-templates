append_to_file 'Procfile.dev' do
  <<~PROCFILE
    webpack: yarn && bin/webpack-dev-server
    css: yarn build:css --watch
  PROCFILE
end
