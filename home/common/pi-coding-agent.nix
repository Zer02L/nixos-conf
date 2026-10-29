{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.pi-coding-agent = {
    enable = true;
    # context = "";
    # extraPackages = [ ];
    keybindings = { };
    models = {
      providers = {
        anymodel = {
          baseUrl = "https://anymodel.org/v1";
          api = "openai-completions";
          compat = {
            supportsReasoningEffort = true;
          };
          models = [
            {
              id = "gpt-5.6-terra";
              name = "GPT-5.6 Terra";
              reasoning = true;
              input = [ "text" ];
            }
          ];
        };
      };
    };
    settings = {
      compaction = {
        enabled = true;
        keepRecentTokens = 20000;
        reserveTokens = 16384;
      };
      extensions = [
        "../../dotfiles/.pi/agent/extensions/omniroute.ts"
      ];
      defaultProvider = "anymodel";
      defaultModel = "gpt-5.6-terra";
      defaultThinkingLevel = "high";
      # enabledModels = [
      #   "claude-*"
      #   "gpt-4o"
      # ];
      packages = [
        "npm:@termdraw/pi"
        "npm:pi-mcp-adapter"
      ];
      retry = {
        enabled = true;
        maxRetries = 3;
      };
      theme = "dark";
    };

  };
}
