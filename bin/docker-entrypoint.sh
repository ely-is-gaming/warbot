#!/bin/bash -e
# Create the DB if it doesn't exist and run migrations
echo "Setting up the database..."
bundle exec rails db:prepare RAILS_ENV=production
bundle exec rails db:migrate RAILS_ENV=production

# Then start the app
echo "Starting the server..."
exec bin/rails server