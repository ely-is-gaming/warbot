FROM ruby:3.3

# Set up system dependencies
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs libsodium-dev

# Set working directory to a simple path inside container (like /app)
WORKDIR /app

RUN echo "hello"

# Copy Gemfile first and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set without 'development test'
RUN bundle install

# Copy the entire app
COPY . /app

# Make sure tmp/cache exists and has permissions AFTER copying
RUN mkdir -p tmp/cache && chmod -R 777 tmp

# Expose port
EXPOSE 3000

# Run the server
CMD ["bin/rails", "server"]
