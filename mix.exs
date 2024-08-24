defmodule Emote.Mixfile do
  use Mix.Project

  def project do
    [
      app: :emote,
      version: "0.1.1",
      elixir: "~> 1.10",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: dependencies(),
      description: description(),
      package: package()
    ]
  end

  defp dependencies do
    [
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:phoenix_html, "~> 3.3 or ~> 4.0", optional: true}
    ]
  end

  defp description do
    """
      Small lib for converting emoticons and emoji names to emoji characters or images, incl. custom emoji
    """
  end

  defp package do
    [
      name: :emote,
      files: ["lib", "mix.exs", "README*"],
      maintainers: ["Bonfire"],
      licenses: ["WTFPL"],
      links: %{"GitHub" => "https://github.com/bonfire-networks/emote"}
    ]
  end
end
