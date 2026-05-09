# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

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
set `REDIS_URL=redis://localhost:6379/0` yourself. Without it, slash commands
cannot be persisted.

On TrueNAS SCALE, run Valkey/Redis as a separate app/container with persistent
storage mounted at `/data`, then set the bot container's `REDIS_URL` to that
container's DNS name, for example:

```sh
REDIS_URL=redis://war-bot-redis:6379/0
```

* Deployment instructions

* ...
