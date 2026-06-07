{
  description = "Моя конфигурация NixOS с Flake и Disko";

  nixConfig = {
    extra-substituters = [ 
      "https://numtide.com"
      "https://zed.cachix.org" # Добавляем кэш для Zed
    ];
    extra-trusted-public-keys = [ 
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU=" # Ключ кэша Zed
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; # Или укажите конкретную версию, например nixos-24.11
    
    # Подключаем официальный репозиторий Disko
    disko = {
	url = "github:nix-community/disko";
        inputs.nixpkgs.follows = "nixpkgs";
    };
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zed-flake = {
      url = "github:zed-industries/zed";
      # Чтобы не качать дубликаты nixpkgs, заставляем zed использовать ваш системный:
      inputs.nixpkgs.follows = "nixpkgs"; 
    };

    llm-agents.url = "github:numtide/llm-agents.nix";
  };


  outputs = { self, nixpkgs, disko, home-manager, zed-flake, llm-agents, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
    nixosConfigurations = {
      # Замените "my-nixos" на желаемое имя хоста (hostname)
      zerg = nixpkgs.lib.nixosSystem {
        inherit system; # Замените, если у вас архитектура ARM (aarch64-linux)
        modules = [
          # Подключаем модуль Disko во Flake
          disko.nixosModules.disko

          ./hardware-configuration.nix
          ./configuration.nix
          ./disko.nix
        ];
      };
    };

      # 2. АВТОНОМНАЯ конфигурация пользователя (Standalone Home Manager)
      homeConfigurations = {
	"zerg" = home-manager.lib.homeManagerConfiguration {
               
	 inherit pkgs;
        
        # Указываем путь к вашему файлу home.nix
        modules = [ ./home.nix ];
        
        # Передаем глобальные inputs внутрь home.nix (например, для NUR или других флейков)
        extraSpecialArgs = { inherit inputs; };
      };
	};
  };
}

