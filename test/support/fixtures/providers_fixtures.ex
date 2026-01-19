defmodule Skwirl.ProvidersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Skwirl.Providers` context.
  """

  @doc """
  Generate a provider.
  """
  def provider_fixture(attrs \\ %{}) do
    {:ok, provider} =
      attrs
      |> Enum.into(%{
        lua_code: "some lua_code",
        name: "some name"
      })
      |> Skwirl.Providers.create_provider()

    provider
  end
end
