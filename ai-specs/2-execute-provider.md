# Execute Provider Lua Code

## Overview
Add the ability to execute a provider's Lua code when the user clicks an "Execute" button on the provider card. This implements the core backup workflow: listing files, fetching metadata, and downloading files from cloud services (using Google Drive as the example).

## Goals
- Execute Lua provider code from Elixir
- Implement the backup workflow orchestration
- Establish the Lua-to-Elixir function interface

## Requirements

### Functional Requirements
- [ ] Add "Execute" button to each provider card
- [ ] Integrate a Lua runtime library into the Elixir project
- [ ] Expose `http.get(url, options)` function to Lua
- [ ] Expose `skwirl.emit_file_id(id)` function to Lua
- [ ] Expose `skwirl.download_url(url, options)` function to Lua
- [ ] Orchestrate the backup flow: list IDs → get metadata → download files
- [ ] Process files sequentially (one at a time)
- [ ] Log errors without displaying to user
- [ ] Discard downloaded file content (no storage for now)

### Non-Functional Requirements
- [ ] Lua code execution must be sandboxed for security
- [ ] Errors in Lua should not crash the Elixir process

## Technical Approach

### Lua Runtime Library
Use an Elixir Lua library such as `luerl` to execute Lua code. Add to `mix.exs`:

```elixir
{:luerl, "~> 1.0"}
```

### Lua Provider API

Providers must implement these three functions:

#### 1. `list_file_ids()`
Lists all file IDs from the cloud service. Calls `skwirl.emit_file_id(id)` for each file discovered.

```lua
function list_file_ids()
  local access_token = "hardcoded_token_for_now"
  local page_token = nil
  
  repeat
    local response = http.get("https://www.googleapis.com/drive/v3/files", {
      headers = {
        Authorization = "Bearer " .. access_token
      },
      params = {
        pageSize = 1000,
        pageToken = page_token,
        fields = "nextPageToken, files(id)",
        q = "trashed=false"
      }
    })
    
    if response.error then
      error("Failed to list files: " .. response.error.message)
    end
    
    for _, file in ipairs(response.files or {}) do
      skwirl.emit_file_id(file.id)
    end
    
    page_token = response.nextPageToken
  until not page_token
end
```

#### 2. `get_file_metadata(file_id)`
Returns metadata for a specific file including name, path, checksum, size, and modified time.

```lua
function get_file_metadata(file_id)
  local access_token = "hardcoded_token_for_now"
  
  local response = http.get(
    "https://www.googleapis.com/drive/v3/files/" .. file_id,
    {
      headers = {
        Authorization = "Bearer " .. access_token
      },
      params = {
        fields = "id, name, size, modifiedTime, md5Checksum, mimeType"
      }
    }
  )
  
  if response.error then
    error("Failed to get file metadata: " .. response.error.message)
  end
  
  if not response.md5Checksum then
    error("No checksum available for file: " .. response.name)
  end
  
  return {
    name = response.name,
    path = response.name,
    checksum = response.md5Checksum,
    size = tonumber(response.size) or 0,
    modified_time = response.modifiedTime
  }
end
```

#### 3. `download_file(file_id)`
Initiates file download via Elixir. Elixir handles the actual HTTP streaming.

```lua
function download_file(file_id)
  local access_token = "hardcoded_token_for_now"
  
  skwirl.download_url(
    "https://www.googleapis.com/drive/v3/files/" .. file_id .. "?alt=media",
    {
      headers = {
        Authorization = "Bearer " .. access_token
      }
    }
  )
end
```

### Elixir Functions Exposed to Lua

#### `http.get(url, options)`
Makes an HTTP GET request using the Req library.

**Parameters:**
- `url` (string): The URL to request
- `options` (table):
  - `headers` (table): Key-value pairs of HTTP headers
  - `params` (table): Query parameters

**Returns:** Response body parsed as table (if JSON) or string

**Errors:** Throws Lua error on HTTP failure

#### `skwirl.emit_file_id(id)`
Sends a discovered file ID back to Elixir for collection.

**Parameters:**
- `id` (string): The file ID

**Returns:** Nothing

#### `skwirl.download_url(url, options)`
Tells Elixir to download a file from the given URL.

**Parameters:**
- `url` (string): The download URL
- `options` (table):
  - `headers` (table): Key-value pairs of HTTP headers

**Returns:** Nothing (file content is discarded for now)

**Errors:** Throws Lua error on download failure

### Execution Orchestration

Create a new module `Skwirl.Providers.Executor` that:

1. Loads and compiles the provider's Lua code
2. Sets up the Lua sandbox with exposed functions
3. Executes the backup workflow:

```elixir
defmodule Skwirl.Providers.Executor do
  def execute(provider) do
    # 1. Initialize Lua state with exposed functions
    lua_state = init_lua_state()
    
    # 2. Load provider's Lua code
    lua_state = load_lua_code(lua_state, provider.lua_code)
    
    # 3. Call list_file_ids() and collect emitted IDs
    file_ids = call_list_file_ids(lua_state)
    
    # 4. For each file ID, get metadata and download
    Enum.each(file_ids, fn file_id ->
      metadata = call_get_file_metadata(lua_state, file_id)
      call_download_file(lua_state, file_id)
      # Log metadata, discard downloaded content
    end)
  end
end
```

### File Structure
```
lib/
  skwirl/
    providers/
      executor.ex          # Lua execution and orchestration
      lua_sandbox.ex       # Lua state setup and exposed functions
```

### LiveView Changes

Add "Execute" button to provider card in `ProviderLive`:

```elixir
<div
  :for={provider <- @providers}
  class="card bg-base-100 border border-base-300 hover:border-primary hover:shadow-lg transition-all duration-200 group h-32"
>
  <div class="card-body flex flex-col items-center justify-center p-6">
    <h2
      phx-click="show_code"
      phx-value-id={provider.id}
      class="card-title text-xl text-center group-hover:text-primary transition-colors cursor-pointer"
    >
      {provider.name}
    </h2>
    <button
      type="button"
      phx-click="execute"
      phx-value-id={provider.id}
      class="btn btn-primary btn-sm mt-2"
    >
      Execute
    </button>
  </div>
</div>
```

Add event handler:

```elixir
def handle_event("execute", %{"id" => id}, socket) do
  provider = Enum.find(socket.assigns.providers, &(&1.id == id))
  
  # Run execution in background to not block LiveView
  Task.start(fn ->
    case Skwirl.Providers.Executor.execute(provider) do
      :ok -> :ok
      {:error, reason} -> Logger.error("Provider execution failed: #{inspect(reason)}")
    end
  end)
  
  {:noreply, socket}
end
```

### Update Seed Data

Update `priv/repo/seeds.exs` with the complete Google Drive provider Lua code:

```elixir
Repo.insert!(%Provider{
  name: "Google Drive",
  lua_code: """
  function list_file_ids()
    local access_token = "hardcoded_token_for_now"
    local page_token = nil
    
    repeat
      local response = http.get("https://www.googleapis.com/drive/v3/files", {
        headers = {
          Authorization = "Bearer " .. access_token
        },
        params = {
          pageSize = 1000,
          pageToken = page_token,
          fields = "nextPageToken, files(id)",
          q = "trashed=false"
        }
      })
      
      if response.error then
        error("Failed to list files: " .. response.error.message)
      end
      
      for _, file in ipairs(response.files or {}) do
        skwirl.emit_file_id(file.id)
      end
      
      page_token = response.nextPageToken
    until not page_token
  end

  function get_file_metadata(file_id)
    local access_token = "hardcoded_token_for_now"
    
    local response = http.get(
      "https://www.googleapis.com/drive/v3/files/" .. file_id,
      {
        headers = {
          Authorization = "Bearer " .. access_token
        },
        params = {
          fields = "id, name, size, modifiedTime, md5Checksum, mimeType"
        }
      }
    )
    
    if response.error then
      error("Failed to get file metadata: " .. response.error.message)
    end
    
    if not response.md5Checksum then
      error("No checksum available for file: " .. response.name)
    end
    
    return {
      name = response.name,
      path = response.name,
      checksum = response.md5Checksum,
      size = tonumber(response.size) or 0,
      modified_time = response.modifiedTime
    }
  end

  function download_file(file_id)
    local access_token = "hardcoded_token_for_now"
    
    skwirl.download_url(
      "https://www.googleapis.com/drive/v3/files/" .. file_id .. "?alt=media",
      {
        headers = {
          Authorization = "Bearer " .. access_token
        }
      }
    )
  end
  """
})
```

## Constraints
- Access token is hardcoded (OAuth flow will be added later)
- Files are processed sequentially (parallel processing will come later)
- Downloaded content is discarded (storage destination will be added later)
- No UI feedback during execution (progress indicators will be added later)

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Lua syntax error in provider code | Log error, don't crash Elixir process |
| HTTP request fails | Lua throws error, Elixir logs and continues |
| File has no checksum (Google Docs) | Lua throws error, Elixir logs and skips file |
| Download fails mid-stream | Log error, continue with next file |
| Provider has no `list_file_ids` function | Log error, abort execution |
| Empty file list returned | Complete successfully with no downloads |
| User clicks Execute multiple times | Each click starts a new execution (no debouncing for now) |

## Acceptance Criteria

1. "Execute" button visible on each provider card
2. Clicking "Execute" triggers Lua code execution
3. `http.get()` successfully makes HTTP requests from Lua
4. `skwirl.emit_file_id()` collects file IDs in Elixir
5. `skwirl.download_url()` downloads files via Elixir
6. Files are processed sequentially (list → metadata → download for each)
7. Errors are logged but don't crash the application
8. `mix precommit` passes

## Out of Scope
- OAuth authentication flow
- Storing downloaded files
- Progress indicators / UI feedback
- Parallel file processing
- Retry logic for failed downloads
- Rate limiting
- Cancellation of running execution
