defmodule Skitter.Util do
  def normalize_url(url) when is_binary(url) do
    url
    |> String.trim()
    |> URI.parse()
    |> then(fn %URI{} = uri ->
      cond do
        is_relative_uri?(uri) -> uri
        uri.scheme == nil -> %{uri | scheme: "https"}
        true -> uri
      end
    end)
    |> URI.to_string()
    |> String.trim_trailing("/")
  end

  defp is_relative_uri?(%URI{scheme: nil, host: nil} = uri) do
    has_path = is_binary(uri.path) and uri.path != ""
    has_query = is_binary(uri.query) and uri.query != ""
    has_fragment = is_binary(uri.fragment) and uri.fragment != ""
    has_path or has_query or has_fragment
  end
  defp is_relative_uri?(_), do: false

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
