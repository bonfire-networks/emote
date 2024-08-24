defmodule Emote do
  @moduledoc "./README.md" |> File.stream!() |> Enum.drop(1) |> Enum.join()
  require Logger

  emojis = Path.join([__DIR__, "emojis.txt"])
  emoticons = Path.join([__DIR__, "emoticons.txt"])
  # TODO: use @external_resource ? (removed because it was causing constant recompilation)

  # load all
  # all =
  for file_path <- [
        emojis,
        emoticons
      ] do
    for line <- File.stream!(file_path, [], :line) do
      [emoji, name] =
        line
        |> String.split(" ", parts: 2)
        |> Enum.map(&String.trim/1)

      {name, emoji}
    end
  end
  |> List.flatten()
  # |> IO.inspect()
  # define substitution functions for each
  # for {name, emoji} <- all do
  |> Enum.map(fn {name, emoji} ->
    defp emoji(unquote(name)), do: unquote(emoji)
  end)

  # load the list of possible strings we can lookup
  # names_list = for {name, emoji} <- all do
  #   name
  # end

  defp emoji(_), do: nil

  @doc """
  Converts an emoticon or emoji name to emoji.

  Returns nil if no matching emoji is found. 

  If you need support for custom emoji, use `convert_word/2` instead.

      iex> lookup(":face_with_ok_gesture:")
      "🙆"

      iex> lookup("face_with_ok_gesture")
      "🙆"

      iex> lookup("unknown_emoji")
      nil
  """
  def lookup(":" <> _ = emoji), do: emoji(emoji)
  def lookup(emoji), do: emoji(":#{emoji}:")

  @doc "Converts text in a way that it replaces any mapped emojis or emoticons with the equivalent emojis characters or images, including custom emoji"
  def convert_text(text, opts \\ [])

  def convert_text(text, opts) when is_binary(text) do
    text
    # |> String.split(~r{<|>}, include_captures: true)
    # |> Enum.flat_map(&String.split/1)
    |> String.split("\n")
    |> Enum.map(&convert_line(&1, opts[:custom_fn]))
    |> Enum.join("\n")
    |> maybe_custom_emoji(opts[:custom_emoji])
  end

  # def convert_text(text, _opts) when is_binary(text) do
  #   text
  #   |> String.replace(unquote(names_list), &emoji/1)
  # end

  def convert_text(text, _opts) do
    Logger.error("Emote: expected binary, got: #{inspect(text)}")
    text
  end

  defp convert_line(text, custom_fn) when is_binary(text) do
    text
    # |> String.split(~r{<|>}, include_captures: true)
    # |> Enum.flat_map(&String.split/1)
    # by whitespace
    |> String.split()
    |> Enum.map(
      &(&1
        |> String.trim()
        |> do_convert_word(custom_fn))
    )
    |> Enum.join(" ")
  end

  @doc "Converts an emoticon or emoji name to emoji, including custom emoji. Simply returns the input when an emoji is not found."
  def convert_word(text, opts \\ [])

  def convert_word(text, opts) when is_binary(text) do
    text
    |> do_convert_word(opts[:custom_fn])
    |> maybe_custom_emoji(opts[:custom_emoji])
  end

  # NOTE: adjust the following guards based on shortest/longest emoticons / emoji names

  defp do_convert_word(word, custom_fn \\ nil)

  defp do_convert_word(word, custom_fn)
       when is_binary(word) and byte_size(word) > 1 and byte_size(word) < 9 do
    # handles emoticons (which are not wrapped with :)
    case emoji(word) do
      nil ->
        maybe_custom_fn(word, custom_fn)

      emoji ->
        emoji
    end
  end

  defp do_convert_word(":" <> _ = word, custom_fn)
       when byte_size(word) > 2 and byte_size(word) < 88 do
    # handle emojis
    case emoji(word) do
      nil ->
        maybe_custom_fn(word, custom_fn)

      emoji ->
        emoji
    end
  end

  defp do_convert_word(":" <> _ = word, custom_fn)
       when byte_size(word) > 87 do
    # handle custom fn for long words
    maybe_custom_fn(word, custom_fn)
  end

  defp do_convert_word(word, _), do: word

  defp maybe_custom_fn(word, custom_fn) when is_function(custom_fn, 1), do: custom_fn.(word)
  defp maybe_custom_fn(word, _custom_fn), do: word

  defp maybe_custom_emoji(text, custom_emoji)
       when is_list(custom_emoji) or is_map(custom_emoji) do
    Enum.reduce(custom_emoji, text, fn
      {emoji, file}, text ->
        String.replace(text, ":#{emoji}:", prepare_emoji_code(emoji, text_only(file)))
    end)
  end

  defp maybe_custom_emoji(text, _custom_emoji), do: text

  defp prepare_emoji_code(emoji, file) do
    # TODO: support SVG ones?
    "<img class='emoji #{emoji}' alt='#{emoji}' title=':#{emoji}:' src='#{file}' />"
  end

  defp text_only(content) when is_binary(content) do
    cond do
      Code.ensure_loaded?(HtmlSanitizeEx) ->
        HtmlSanitizeEx.strip_tags(content)

      Code.ensure_loaded?(Phoenix.HTML) ->
        content
        |> Phoenix.HTML.html_escape()
        |> Phoenix.HTML.safe_to_string()

      true ->
        content
    end
  end
end
