# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

Tile commands are disabled by default. Set `TILE_MODE=true` to enable:

```sh
TILE_MODE=true
```

When disabled, `/roll`, `/current_tile`, `/roll_history`, `/roll_leaderboard`, and
`/set_tile`, are unavailable.

For Docker Compose, leave `TILE_MODE` unset or set it to `false`:

```sh
TILE_MODE=false docker compose up -d --build
```

To enable tile commands later:

```sh
TILE_MODE=true docker compose up -d
```

* Database creation

1. bin/rails db:create
2. bin/rails db:migrate
3. bin/rails db:seed

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

The slash command queue uses a Redis-compatible server. For local containers,
`compose.yaml` starts Valkey as the `redis` service and sets:

```sh
REDIS_URL=redis://redis:6379/0
RAILS_MASTER_KEY=<contents of the Rails credentials key for RAILS_ENV>
```

If you run Rails directly on your machine, start a Redis-compatible server and
set `REDIS_URL=redis://localhost:6379/0` yourself, or rely on the development
default. Without a reachable Redis server, slash commands cannot be persisted.
Rails console does not auto-start the Discord bot; run with
`START_DISCORD_BOT=true` only when you want the bot worker in that process.

Drops are stored in the Rails SQLite database under `db/data`. In Docker
Compose, `app-db-data` is mounted at `/app/db/data` so drops survive app
container rebuilds/recreates.

On TrueNAS SCALE, persist both the app database and Redis queue:

1. Create a dataset for the app database, for example
   `/mnt/<pool>/apps/war-bot/db-data`.
2. Mount that dataset into the app container at `/app/db/data`.
3. Create a dataset for Redis/Valkey, for example
   `/mnt/<pool>/apps/war-bot/redis-data`.
4. Mount that dataset into the Redis/Valkey container at `/data`.
5. Set app environment variables:

```sh
RAILS_ENV=production
TILE_MODE=false
REDIS_URL=redis://<redis-service-name>:6379/0
RAILS_MASTER_KEY=<your Rails master key>
START_DISCORD_BOT=true
```

If your Redis/Valkey app is named `war-bot-redis`, the app `REDIS_URL` would be:

```sh
REDIS_URL=redis://war-bot-redis:6379/0
```

Do not use `docker compose down -v` or delete the TrueNAS datasets unless you
intend to delete the persisted drops database and command queue.

* Deployment instructions

* ...
