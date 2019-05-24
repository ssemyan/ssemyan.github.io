rm -rf _site/
bundle install
bundle exec jekyll serve --watch --host=0.0.0.0 --port 80 --force_polling