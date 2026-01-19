# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Skwirl.Repo.insert!(%Skwirl.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Skwirl.Repo
alias Skwirl.Providers.Provider

Repo.insert!(%Provider{
  name: "Google Drive",
  lua_code: """
  -- Google Drive Provider
  -- This is placeholder Lua code for the Google Drive integration

  function authenticate(config)
    -- OAuth2 authentication logic
    return { success = true }
  end

  function list_files(path)
    -- List files in the specified path
    return {}
  end

  function download_file(file_id)
    -- Download a file by ID
    return nil
  end
  """
})
