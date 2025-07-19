# Skitter

The goal of this projec is to use async tasks to crawl a website, and extract
all the uniqie links. This includes links to all subdomains of the passed in
site. These paths and subdomains will be exported in the form of json, or a
word list that can then be used in ffuf.


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `skitter` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:skitter, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/skitter>.

