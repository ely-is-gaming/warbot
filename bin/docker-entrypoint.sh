#!/bin/bash -e
RAILS_ENV="${RAILS_ENV:-production}"

# Create the DB if it doesn't exist and run migrations
echo "Setting up the ${RAILS_ENV} database..."
START_DISCORD_BOT=false bundle exec rails db:prepare RAILS_ENV="${RAILS_ENV}"
START_DISCORD_BOT=false bundle exec rails db:migrate RAILS_ENV="${RAILS_ENV}"

# Then start the app
echo "Starting the server..."
exec bin/rails server
