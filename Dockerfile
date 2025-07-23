FROM ruby:3.3

# Install dependencies
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs libsodium-dev

# Create a non-root user to run the app
RUN useradd -ms /bin/bash warbot

# Set working dir
WORKDIR /app

# Copy Gemfiles and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set without 'development test'
RUN bundle install

# Copy app code
COPY . .

# Fix permissions on db and tmp folders
RUN mkdir -p tmp/cache db
RUN chown -R warbot:warbot tmp db log
RUN chmod -R 755 tmp db log

# make /tmp/sockets
RUN mkdir -p tmp/pids tmp/sockets
RUN chmod -R 755 tmp

# Ensure the entrypoint is executable
RUN chmod +x ./bin/docker-entrypoint.sh

# Expose app port
EXPOSE 3000

# At the end of Dockerfile
RUN chown -R warbot:warbot /app

# Run the entrypoint
ENTRYPOINT ["./bin/docker-entrypoint.sh"]
