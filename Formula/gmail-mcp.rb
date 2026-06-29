class GmailMcp < Formula
  desc "Gmail MCP server (stdio + Streamable HTTP transports)"
  homepage "https://github.com/macbeth76/google-mcp"
  # NOTE: url/sha256/version are kept in sync automatically by the
  # google-mcp "Release (Homebrew artifact)" workflow. For the very first
  # release, cut a tag in google-mcp (e.g. `git tag v1.0.0 && git push --tags`);
  # the workflow publishes the asset below and opens a PR to fill the sha256.
  url "https://github.com/macbeth76/google-mcp/releases/download/v1.0.0/gmail-mcp-1.0.0.tgz"
  sha256 "b3c31277a20b25a50dda7c734c3328e39a52be6999546e907dc1c30ac91b863e"
  version "1.0.0"
  license "MIT"

  depends_on "node"

  # Optional runtime tools used only by specific tool groups:
  #   ffmpeg / whisper-cpp -> video analysis tools
  #   ollama (cask)        -> AI auto-labeling + local LLM video summaries
  # They are intentionally NOT hard dependencies so the core Gmail tools
  # install with a minimal footprint.

  def install
    # The release tarball already contains dist/ + production node_modules.
    libexec.install Dir["*"]

    node = Formula["node"].opt_bin/"node"
    env_file = etc/"gmail-mcp/gmail-mcp-http.env"

    (bin/"gmail-mcp").write <<~SH
      #!/bin/bash
      exec "#{node}" "#{libexec}/dist/index.js" "$@"
    SH

    (bin/"gmail-mcp-auth").write <<~SH
      #!/bin/bash
      exec "#{node}" "#{libexec}/dist/auth.js" "$@"
    SH

    # The HTTP wrapper sources an operator-managed env file (token, bind host,
    # port) so configuration can change without reinstalling the formula.
    (bin/"gmail-mcp-http").write <<~SH
      #!/bin/bash
      set -euo pipefail
      ENV_FILE="${GMAIL_MCP_HTTP_ENV_FILE:-#{env_file}}"
      if [ -f "$ENV_FILE" ]; then
        set -a
        . "$ENV_FILE"
        set +a
      fi
      exec "#{node}" "#{libexec}/dist/http.js" "$@"
    SH

    chmod 0755, bin/"gmail-mcp"
    chmod 0755, bin/"gmail-mcp-auth"
    chmod 0755, bin/"gmail-mcp-http"

    # Seed a sample env file without clobbering an existing operator config.
    (buildpath/"gmail-mcp-http.env.sample").write <<~ENVFILE
      # Gmail MCP HTTP transport configuration.
      # Copy to gmail-mcp-http.env and fill in. Keep the token secret.
      GMAIL_MCP_HTTP_HOST=127.0.0.1
      GMAIL_MCP_HTTP_PORT=9395
      # Required when binding to any non-loopback (e.g. Tailscale) address:
      # GMAIL_MCP_HTTP_AUTH_TOKEN=replace-with-a-long-random-token
    ENVFILE
    (etc/"gmail-mcp").install "gmail-mcp-http.env.sample"
  end

  service do
    run [opt_bin/"gmail-mcp-http"]
    keep_alive true
    log_path var/"log/gmail-mcp-http.log"
    error_log_path var/"log/gmail-mcp-http.log"
    working_dir var
  end

  def caveats
    <<~EOS
      Gmail MCP server installed.

      1. Configure the HTTP transport:
           cp #{etc}/gmail-mcp/gmail-mcp-http.env.sample #{etc}/gmail-mcp/gmail-mcp-http.env
         Edit it to set GMAIL_MCP_HTTP_HOST/PORT and, for any non-loopback
         bind, a long random GMAIL_MCP_HTTP_AUTH_TOKEN.

      2. Authorize Google access (opens a browser; writes ~/.gmail-mcp/token.json):
           gmail-mcp-auth
         You must place your OAuth client at ~/.gmail-mcp/credentials.json first.

      3. Start the HTTP server as a managed service:
           brew services start gmail-mcp
         Endpoint: http://$GMAIL_MCP_HTTP_HOST:$GMAIL_MCP_HTTP_PORT/mcp
    EOS
  end

  test do
    assert_match "dist/http.js", File.read(bin/"gmail-mcp-http")
    assert_predicate libexec/"dist/http.js", :exist?
  end
end
