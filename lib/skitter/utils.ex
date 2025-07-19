defmodule Skitter.Util do
  def normalize_url(url) when is_binary(url) do
    url
    |> String.trim()
    |> URI.parse()
    |> then(fn
      %URI{scheme: nil} = uri -> %{uri | scheme: "https"} # assume https for relative links
      uri -> uri
    end)
    |> URI.to_string()
    |> String.trim_trailing("/")
  end

  defp parse_host(url) do
    case URI.parse(url) do
      %URI{host: nil} -> :error
      %URI{host: host} -> {:ok, host}
    end
  end

  def allow_domain?(target_url) do
    with base when is_binary(base) <- Skitter.LinkStore.get_base_domain(),
         {:ok, target} <- parse_host(target_url) do
      target == base
    else
      _ -> false
    end
  end

end
