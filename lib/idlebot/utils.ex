defmodule IdleBot.Utils do
  @moduledoc false

  alias Rustic.Result

  @url_regex ~r/((([A-Za-z]{3,9}:(?:\/\/)?)(?:[-;:&=\+\$,\w]+@)?[A-Za-z0-9.-]+|(?:www.|[-;:&=\+\$,\w]+@)[A-Za-z0-9.-]+)((?:\/[\+~%\/.\w-_]*)?\??(?:[-\+=&;%@.\w_]*)#?(?:[.\!\/\\w]*))?)/iu
  @ytdomains ["youtube.com", "www.youtube.com", "m.youtube.com", "youtu.be", "youtube-nocookie.com"]

  def get_links_from_message(message) do
    @url_regex
      |> Regex.scan(message)
      |> Stream.map(fn [match | _groups] -> match end)
      |> Enum.map(&get_url_title/1)
      |> Result.filter_collect()
      |> Result.unwrap!()
  end

  defp get_url_title(url) do
    if URI.parse(url).host in @ytdomains do
      oembed_url = "https://www.youtube.com/oembed?url=#{URI.encode(url)}"
      HTTPoison.get(oembed_url, [], follow_redirect: true)
        |> Result.map_err(fn reason -> {:http_request_failed, reason} end)
        |> Result.and_then(&handle_youtube_response/1)
    else
      HTTPoison.get(url, [], follow_redirect: true)
        |> Result.map_err(fn reason -> {:http_request_failed, reason} end)
        |> Result.and_then(&handle_response/1)
    end
  rescue
    err in ArgumentError -> {:error, err}
  end

  defp handle_response(resp) do
    if 200 <= resp.status_code and resp.status_code < 300 do
      get_url_from_html(resp.body)
    else
      {:error, {:invalid_response, resp.status_code}}
    end
  end

  defp handle_youtube_response(resp) do
    if 200 <= resp.status_code and resp.status_code < 300 do
      Jason.decode(resp.body)
        |> Result.map_err(fn reason -> {:invalid_json, reason} end)
        |> Result.and_then(fn doc ->
          with {:ok, title} <- Map.fetch(doc, "title"),
               {:ok, author_name} <- Map.fetch(doc, "author_name"),
               {:ok, provider_name} <- Map.fetch(doc, "provider_name")
          do
            {:ok, "#{provider_name}: #{title} | @#{author_name}"}
          else
            _ -> {:error, :missing_data}
          end
        end)
    else
      {:error, {:invalid_response, resp.status_code}}
    end
  end

  defp get_url_from_html(html) do
    Floki.parse_document(html)
      |> Result.map_err(fn reason -> {:invalid_html, reason} end)
      |> Result.and_then(fn doc ->
        data = doc
          |> Floki.find("head > title")
          |> Enum.take(1)
          |> Floki.text()
          |> Floki.HTMLParser.parse_fragment()
          |> Result.unwrap!()
          |> Floki.text()
          |> String.split([" ", "\n", "\t", "\r"])
          |> Enum.filter(fn s -> s != "" end)
          |> Enum.join(" ")

        case data do
          "" ->
            {:error, :no_title}

          title ->
            {:ok, title}
        end
      end)
  end
end
