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
        # ollama: список моделей должен содержать явные id (схема не принимает пустую строку).
        # Добавь сюда id своих локальных моделей, например { id = "llama3.1"; }.
        # ollama = {
        #   api = "openai-completions";
        #   apikey = "ollama";
        #   baseUrl = "http://localhost:11434/v1";
        #   models = [
        #     { id = "llama3.1"; }
        #   ];
        # };
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
      # defaultModel = "deepseek-v4";
      # defaultProvider = "anymodel";
      # defaultThinkingLevel = "auto";
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
