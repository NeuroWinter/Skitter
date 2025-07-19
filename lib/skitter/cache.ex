defmodule Skitter.Cache do
  @table :seen_urls

  def mark_as_seen(url) do
    :ets.insert_new(@table, {url})
  end

  def init do
    :ets.new(@table, [:named_table, :set, :public, read_concurrency: true])
  end
end
