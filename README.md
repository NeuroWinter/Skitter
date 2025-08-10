# Skitter


The goal of this project was to learn a bit about OTP and create my own site crawler for use in bug bounties.
I know this may not be the fastest crawler on the plannet, but it is a learning process!


## How to Use

### 1. Clone the repo

```sh
git clone https://github.com/NeuroWinter/skitter.git
cd skitter
```

### 2. Install deps

```sh
mix deps.get
```

### start an iex session

```sh
iex -S mix
```

### Run a crawl

```sh
Skitter.set_seed("https://example.com")
```

Skitter will:

* Crawl the site starting from the seed URL
* Automatically follow and enqueue internal links
* Stop when there are no more unvisited URLs
* Print discovered links as it goes
* Export links to `ffuf_urls.txt`

To detect when a crawl completes programmatically, subscribe to a telemetry event:

```elixir
:telemetry.attach(
  "skitter-crawl-done",
  [:skitter, :crawl, :done],
  fn _event, measurements, _metadata, _config ->
    IO.puts("Crawl finished: visited=#{measurements.visited} unvisited=#{measurements.unvisited} inflight=#{measurements.inflight}")
  end,
  nil
)
```

### Tests

- Run the whole suite:
  ```sh
  mix test
  ```
- Run a single file:
  ```sh
  mix test test/link_store_test.exs
  ```
- Run a single test by line number:
  ```sh
  mix test test/link_store_test.exs:37
  ```
- Show basic coverage in the shell:
  ```sh
  mix test --cover
  ```

Notes:
- Tests manage ETS tables and start required processes automatically via `test/test_helper.exs`.
- The suite focuses on unit tests for `Skitter.Util`, `Skitter.LinkStore`, scheduler lifecycle/telemetry, redirects, content-type gating, and export behavior.

## Notes

This project is still in VERY early development. There will be changes, also it is not really ready to be used as part of an ffuf workflow just yet. It is still in the idea stages.

