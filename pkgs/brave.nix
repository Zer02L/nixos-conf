{
  brave,
  sources,
}:
brave.overrideAttrs (oldAttrs: {
  version = sources.brave.version;
  src = sources.brave.src;
})
