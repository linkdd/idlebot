defmodule IdleBot.Utils do
  @moduledoc false

  alias Rustic.Result

  @url_regex ~r/((([A-Za-z]{3,9}:(?:\/\/)?)(?:[-;:&=\+\$,\w]+@)?[A-Za-z0-9.-]+|(?:www.|[-;:&=\+\$,\w]+@)[A-Za-z0-9.-]+)((?:\/[\+~%\/.\w-_]*)?\??(?:[-\+=&;%@.\w_]*)#?(?:[.\!\/\\w]*))?)/iu

  def get_links_from_message(message) do
    @url_regex
      |> Regex.scan(message)
      |> Stream.map(fn [match | _groups] -> match end)
      |> Enum.map(&get_url_title/1)
      |> Result.filter_collect()
      |> Result.unwrap!()
  end

  defp get_url_title(url) do
    HTTPoison.get(url, [], follow_redirect: true)
      |> Result.map_err(fn reason -> {:http_request_failed, reason} end)
      |> Result.and_then(&handle_response/1)
  end

  defp handle_response(resp) do
    if 200 <= resp.status_code and resp.status_code < 300 do
      get_url_from_html(resp.body)
    else
      {:error, {:invalid_response, resp.status_code}}
    end
  end

  defp get_url_from_html(html) do
    Floki.parse_document(html)
      |> Result.map_err(fn reason -> {:invalid_html, reason} end)
      |> Result.and_then(fn doc ->
        case doc |> Floki.find("title") |> Floki.text() do
          "" ->
            {:error, :no_title}

          title ->
            {:ok, title}
        end
      end)
  end
end