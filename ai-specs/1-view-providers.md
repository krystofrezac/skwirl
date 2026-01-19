# View Installed Providers

## Overview
Create a simple UI to view installed providers (plugins) stored in the database. Providers store Lua code for integrations and are initially populated via database seeds. Users can view providers in a responsive card grid and click any card to see its Lua code in a modal dialog.

## Goals
- Establish the Provider data model and database schema
- Create a clean, visually appealing UI to browse installed providers
- Allow users to inspect the Lua code of any provider

## Requirements

### Functional Requirements
- [ ] Create `providers` database table with UUID v6 primary key
- [ ] Create `Skwirl.Providers` context module with `list_providers/0` function
- [ ] Create `Skwirl.Providers.Provider` Ecto schema
- [ ] Create LiveView at `/providers` displaying providers in a card grid
- [ ] Clicking a provider card opens a modal showing its Lua code
- [ ] Display a friendly empty state when no providers exist
- [ ] Seed database with a sample Google Drive provider

### Non-Functional Requirements
- [ ] Follow Phoenix 1.8 conventions (LiveView, core_components, Tailwind CSS v4)
- [ ] Use world-class UI design with proper spacing, typography, and micro-interactions

## Technical Approach

### Use Phoenix Generators
Use Phoenix generators to scaffold the initial code, then customize as needed:

1. **Generate the context and schema:**
   ```bash
   mix phx.gen.context Providers Provider providers name:string lua_code:text
   ```
   This creates the migration, schema, and context module with standard CRUD functions.

2. **Customize the generated code:**
   - Modify the migration to use UUID v6 primary key (if supported) or UUID v4
   - Keep only `list_providers/0` from the context (remove unused CRUD functions or keep for future use)
   - Manually create the LiveView (no generator needed for this simple read-only view)

3. **Generate migration manually if needed:**
   ```bash
   mix ecto.gen.migration create_providers
   ```

### Database Schema
Create migration for `providers` table:

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | `uuid` (v6) | Primary key |
| `name` | `string` | Not null |
| `lua_code` | `text` | Not null |
| `inserted_at` | `utc_datetime` | Auto-managed |
| `updated_at` | `utc_datetime` | Auto-managed |

### File Structure
```
lib/
  skwirl/
    providers/
      provider.ex          # Ecto schema
    providers.ex           # Context module
  skwirl_web/
    live/
      provider_live.ex     # LiveView for /providers
priv/
  repo/
    migrations/
      *_create_providers.exs
    seeds.exs              # Add Google Drive seed
```

### Context Module (`Skwirl.Providers`)
```elixir
def list_providers do
  Repo.all(Provider)
end
```

### Schema (`Skwirl.Providers.Provider`)
- Use `@primary_key {:id, UUIDv6.Ecto.Type, autogenerate: true}` or equivalent for UUID v6
- Note: If UUIDv6 library is not available, use standard UUID v4 with `Ecto.UUID` and document this as a simplification

### LiveView (`SkwirlWeb.ProviderLive`)
- Mount: Load all providers via `Providers.list_providers/0`
- Assigns: `@providers`, `@selected_provider` (for modal)
- Events:
  - `"show_code"` - Set `@selected_provider` to open modal
  - `"close_modal"` - Set `@selected_provider` to nil to close modal

### Router
Add to the browser scope in `router.ex`:
```elixir
live "/providers", ProviderLive
```

### Seed Data
Add to `priv/repo/seeds.exs`:
```elixir
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
```

## Constraints
- No authentication required (single-user self-hosted app assumption)
- UUID v6 preferred, but UUID v4 acceptable if v6 library adds complexity
- No syntax highlighting for Lua code (plain monospace text)

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| No providers in database | Show friendly empty state: icon + "No providers installed yet" message |
| Provider with empty Lua code | Display empty modal with provider name in header |
| Provider with very long Lua code | Modal should be scrollable |
| Provider name is very long | Truncate with ellipsis in card, show full name in modal |

## UI/UX Specifications

### Card Grid
- Responsive grid: 1 column on mobile, 2 on tablet, 3+ on desktop
- Each card displays:
  - Provider name (prominent)
  - Subtle hover effect (scale or shadow transition)
- Cards should have consistent height
- Use Tailwind CSS for all styling

### Modal
- Triggered by clicking a provider card
- Header: Provider name
- Body: Lua code in monospace font (`font-mono`), wrapped in a scrollable container
- Close button (X icon) in top-right corner
- Click outside modal or press Escape to close
- Use the `<.modal>` component from `core_components.ex` if available

### Empty State
- Centered on page
- Icon (e.g., `hero-puzzle-piece` or similar)
- Text: "No providers installed yet"
- Muted/secondary text color

### Page Layout
- Page title/header: "Providers"
- Wrap content with `<Layouts.app>` component

## Acceptance Criteria

1. Running `mix ecto.migrate` creates the `providers` table with correct schema
2. Running `mix run priv/repo/seeds.exs` inserts the Google Drive provider
3. Visiting `/providers` shows the providers page with card grid
4. Google Drive provider card is visible after seeding
5. Clicking a provider card opens a modal with the Lua code
6. Modal can be closed by clicking X, clicking outside, or pressing Escape
7. When database has no providers, empty state message is displayed
8. UI is responsive and works on mobile, tablet, and desktop
9. `mix precommit` passes (compile, format, tests)

## Out of Scope
- Adding/editing/deleting providers (read-only view)
- Provider installation from URLs
- Lua code execution
- Syntax highlighting
- Search/filter functionality
- Pagination (assume small number of providers)
