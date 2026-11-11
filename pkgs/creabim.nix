{ lib
, stdenv
, makeDesktopItem
, copyDesktopItems
, autoPatchelfHook
, wrapGAppsHook3
, gtk3
, webkitgtk_4_1
, libsoup_3
, glib
, libxkbcommon
, wayland
, libGL
, vulkan-loader
, libx11
, libxcursor
, libxrandr
, libxi
, callPackage
, sources ? callPackage ../_sources/generated.nix { }
}:

let
  src-info = sources.creabim;
  # Extract clean version like "1.1.0" from the tag / string if needed
  version = lib.head (builtins.match ".*v?([0-9]+\\.[0-9]+\\.[0-9]+).*" src-info.version);

  # Runtime dlopened libraries needed by winit, glutin, wgpu, xkbcommon-dl, wayland
  runtimeLibs = [
    libxkbcommon
    wayland
    libGL
    vulkan-loader
    libx11
    libxcursor
    libxrandr
    libxi
  ];
in
stdenv.mkDerivation {
  pname = "creabim";
  inherit version;

  src = src-info.src;

  nativeBuildInputs = [
    autoPatchelfHook
    wrapGAppsHook3
    copyDesktopItems
  ];

  buildInputs = [
    gtk3
    webkitgtk_4_1
    libsoup_3
    glib
    libxkbcommon
  ];

  # Add runtime libraries to DT_RUNPATH so winit / xkbcommon-dl / wayland / egl dlopen calls find them
  runtimeDependencies = runtimeLibs;

  appendRunpaths = map (pkg: "${lib.getLib pkg}/lib") runtimeLibs;

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    cd CreaBIM-*

    install -Dm755 creabim $out/bin/creabim
    install -Dm755 creabim-cli $out/bin/creabim-cli

    install -Dm644 README.md $out/share/doc/creabim/README.md
    install -Dm644 LICENSE $out/share/licenses/creabim/LICENSE

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "creabim";
      exec = "creabim";
      comment = "Design-first BIM, modelled like Blender, made for architects";
      desktopName = "CreaBIM";
      genericName = "BIM Modeller";
      categories = [
        "Graphics"
        "3DGraphics"
        "Engineering"
      ];
    })
  ];

  meta = with lib; {
    description = "Design-first BIM, modelled like Blender, made for architects";
    homepage = "https://github.com/chopinregis/CreaBIM";
    license = licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "creabim";
  };
}
