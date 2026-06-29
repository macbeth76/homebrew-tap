# macbeth76/homebrew-tap

Homebrew tap for personal MCP servers.

## Install

```bash
brew tap macbeth76/tap
brew install gmail-mcp
```

## Formulae

| Formula | Description |
|---|---|
| `gmail-mcp` | Gmail MCP server (stdio + Streamable HTTP transports) |

## gmail-mcp

After install:

```bash
# 1. Configure the HTTP transport
cp "$(brew --prefix)/etc/gmail-mcp/gmail-mcp-http.env.sample" \
   "$(brew --prefix)/etc/gmail-mcp/gmail-mcp-http.env"
#    edit host/port; set GMAIL_MCP_HTTP_AUTH_TOKEN for non-loopback binds

# 2. Authorize Google (browser OAuth; needs ~/.gmail-mcp/credentials.json)
gmail-mcp-auth

# 3. Run as a managed service
brew services start gmail-mcp
```

The HTTP server refuses to bind to a non-loopback address unless
`GMAIL_MCP_HTTP_AUTH_TOKEN` is set.

## Releases / formula bumps

The formula's `url`, `sha256`, and `version` are bumped automatically by the
`Release (Homebrew artifact)` workflow in
[`macbeth76/google-mcp`](https://github.com/macbeth76/google-mcp). To enable the
auto-bump PR, set in that repo:

- Repository **variable** `HOMEBREW_TAP_REPO` = `macbeth76/homebrew-tap`
- Repository **secret** `HOMEBREW_TAP_TOKEN` = a PAT with `contents:write` +
  `pull_requests:write` on this tap repo

Without the token the release asset is still published; bump the formula by hand.
