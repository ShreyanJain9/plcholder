# Plcholder

## What's With That Stupid Name?

 - It's a placeholder name, just like PLC is a placeholder service
 - It scrapes n holds PLC operations
 - The `er` at the end could mean it runs on erlang

## Installation

 - Just git clone this repository (`git clone https://github.com/ShreyanJain9/plcholder`)
 - Then make sure you have Elixir installed
 - Then `mix deps.get`
 - Then modify the config so it matches your DB
 - Then `mix ecto.create`, `mix ecto.migrate`
 - Then `./start` to start scraping or `./start_iex` to scrape with access to an IEx shell

When it's done it'll print `Done!`
