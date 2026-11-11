{
  brave-origin,
  sources,
}:
brave-origin.overrideAttrs (oldAttrs: {
  version = sources.brave-origin.version;
  src = sources.brave-origin.src;
})
