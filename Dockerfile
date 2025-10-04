FROM ruby:3.4-slim

# Install dependencies
RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  nodejs \
  sqlite3 \
  libsqlite3-dev \
  libyaml-dev \
  dos2unix \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN gem install bundler

# Copy Gemfile trước để cache bundle install
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy toàn bộ source
COPY . .

# Fix line endings (convert CRLF -> LF) cho toàn bộ script
RUN find /app -type f \( -name "*.sh" -o -path "*/bin/*" \) -exec dos2unix {} \; \
    && chmod +x /app/bin/*

# Copy entrypoint script vào PATH
COPY entrypoint.sh /usr/bin/entrypoint.sh
RUN dos2unix /usr/bin/entrypoint.sh && chmod +x /usr/bin/entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["entrypoint.sh"]

CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
