/**
 * OpenCode plugin that injects session tracking headers into Anthropic API requests.
 *
 * This enables the claude-max-proxy to reliably track sessions and resume
 * Claude Agent SDK conversations instead of starting fresh every time.
 *
 * What it does:
 *   Adds x-opencode-session and x-opencode-request headers to requests
 *   sent to the Anthropic provider. The proxy uses these to map OpenCode
 *   sessions to Claude SDK sessions for conversation resumption.
 *
 * Without this plugin:
 *   The proxy falls back to fingerprint-based session matching (hashing
 *   the first user message). This works but is less reliable.
 */

type ChatHeadersHook = (
  incoming: {
    sessionID: string
    agent: any
    model: { providerID: string }
    provider: any
    message: { id: string }
  },
  output: { headers: Record<string, string> }
) => Promise<void>

type PluginHooks = {
  "chat.headers"?: ChatHeadersHook
}

type PluginFn = (input: any) => Promise<PluginHooks>

export const ClaudeMaxHeadersPlugin: PluginFn = async (_input) => {
  return {
    "chat.headers": async (incoming, output) => {
      // Only inject headers for Anthropic provider requests
      if (incoming.model.providerID !== "anthropic") return

      output.headers["x-opencode-session"] = incoming.sessionID
      output.headers["x-opencode-request"] = incoming.message.id
    },
  }
}

export default ClaudeMaxHeadersPlugin
