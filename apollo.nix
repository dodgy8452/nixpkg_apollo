{
  lib,
  stdenv,
  fetchFromGitHub,
  autoPatchelfHook,
  autoAddDriverRunpath,
  makeWrapper,
  buildNpmPackage,
  nixosTests,
  cmake,
  avahi,
  libevdev,
  libpulseaudio,
  xorg,
  libxcb,
  openssl,
  libopus,
  boost,
  pkg-config,
  libdrm,
  wayland,
  wayland-scanner,
  libffi,
  libcap,
  libgbm,
  curl,
  pcre,
  pcre2,
  python3,
  libuuid,
  libselinux,
  libsepol,
  libthai,
  libdatrie,
  libxkbcommon,
  libepoxy,
  libva,
  libvdpau,
  libglvnd,
  numactl,
  amf-headers,
  intel-media-sdk,
  svt-av1,
  vulkan-loader,
  libappindicator,
  libnotify,
  miniupnpc,
  nlohmann_json,
  config,
  cudaSupport ? config.cudaSupport,
  cudaPackages ? { },
}:
let
  stdenv' = if cudaSupport then cudaPackages.backendStdenv else stdenv;
in
stdenv'.mkDerivation rec {
  pname = "apollo";
  version = "0.3.1-hotfox.1"; # Update this with the current version or tag

  src = fetchFromGitHub {
    owner = "ClassicOldSong";
    repo = "Apollo";
    rev = "v0.3.1-hotfox.1"; # Replace with the appropriate tag or commit when available
    hash = "sha256-0YH01k+PwQxkXxq1a11NYXhBF1LWXj7uuRVFSNHKztc="; # Replace with the correct hash
    fetchSubmodules = true;
  };

  # build webui
  ui = buildNpmPackage {
    inherit src version;
    pname = "sunshine-ui";
   # npmDepsHash = "sha256-T1t/2MVgb9zi1tcpa6iFV0o1s/m1lUDCnzZgPa4wc6g="; # You'll need to generate this
   # npmDepsHash = "sha256-sWCmx1dMEyRyuYeeuqAjHZLVnckskgQO4saFM64s4Y4=";
   # npmDepsHash = "sha256-HBEAFkRBitDT09xSAEA/fgRQlSaLaAczutf0urQIfeM="; # This one is used when lib.fakehash is tested
   # npmDepsHash = lib.fakeHash;
   # npmDepsHash = "sha256-7b+8yijOZg8E25EVcVEvWCUyS5x7zX5zCevbAW5AOq8=";
    npmDepsHash = "sha256-7YwsQNbm0t/j1tEY4cxbW04+kDiw9bNwSeT8qX0hDEs=";
    makeCacheWritable = true; # Allow npm to write to the cache
   # npmFlags = [ "--legacy-peer-deps" "--no-offline" ]; # Resolve peer dependency conflicts
     # If Apollo uses a different approach for package-lock.json, adjust accordingly
     postPatch = ''
       cp ${./package-lock.json} ./package-lock.json
     '';

    installPhase = ''
    #  mkdir -p $out/build
    #  npm run build
    #  cp -r dist/* $out/build/
      mkdir -p $out
      cp -r * $out/

    '';
  };

  nativeBuildInputs =
    [
      cmake
      pkg-config
      python3
      makeWrapper
      wayland-scanner
      # Avoid fighting upstream's usage of vendored ffmpeg libraries
      autoPatchelfHook
    ]
    ++ lib.optionals cudaSupport [
      autoAddDriverRunpath
    ];

  buildInputs =
    [
      avahi
      libevdev
      libpulseaudio
      xorg.libX11
      libxcb
      xorg.libXfixes
      xorg.libXrandr
      xorg.libXtst
      xorg.libXi
      openssl
      libopus
      boost
      libdrm
      wayland
      libffi
      libevdev
      libcap
      libdrm
      curl
      pcre
      pcre2
      libuuid
      libselinux
      libsepol
      libthai
      libdatrie
      xorg.libXdmcp
      libxkbcommon
      libepoxy
      libva
      libvdpau
      numactl
      libgbm
      amf-headers
      svt-av1
      libappindicator
      libnotify
      miniupnpc
      nlohmann_json
    ]
    ++ lib.optionals cudaSupport [
      cudaPackages.cudatoolkit
      cudaPackages.cuda_cudart
    ]
    ++ lib.optionals stdenv.hostPlatform.isx86_64 [
      intel-media-sdk
    ];

  runtimeDependencies = [
    avahi
    libgbm
    xorg.libXrandr
    libxcb
    libglvnd
  ];

  cmakeFlags =
    [
      "-Wno-dev"
      # upstream tries to use systemd and udev packages to find these directories in FHS; set the paths explicitly instead
      (lib.cmakeBool "UDEV_FOUND" true)
      (lib.cmakeBool "SYSTEMD_FOUND" true)
      (lib.cmakeFeature "UDEV_RULES_INSTALL_DIR" "lib/udev/rules.d")
      (lib.cmakeFeature "SYSTEMD_USER_UNIT_INSTALL_DIR" "lib/systemd/user")
      (lib.cmakeBool "BOOST_USE_STATIC" false)
      (lib.cmakeBool "BUILD_DOCS" false)
      (lib.cmakeFeature "SUNSHINE_PUBLISHER_NAME" "nixpkgs") # May need to change SUNSHINE_ prefix to APOLLO_
      (lib.cmakeFeature "SUNSHINE_PUBLISHER_WEBSITE" "https://nixos.org")
      (lib.cmakeFeature "SUNSHINE_PUBLISHER_ISSUE_URL" "https://github.com/NixOS/nixpkgs/issues")
    ]
    ++ lib.optionals (!cudaSupport) [
      (lib.cmakeBool "SUNSHINE_ENABLE_CUDA" false) # May need to change SUNSHINE_ prefix to APOLLO_
    ];

  env = {
    # needed to trigger CMake version configuration
    BUILD_VERSION = "${version}";
    BRANCH = "master";
    COMMIT = "";
  };

  postPatch = ''
    # remove upstream dependency on systemd and udev
    substituteInPlace cmake/packaging/linux.cmake \
      --replace-fail 'find_package(Systemd)' "" \
      --replace-fail 'find_package(Udev)' ""

    # don't look for npm since we build webui separately
    substituteInPlace cmake/targets/common.cmake \
      --replace-fail 'find_program(NPM npm REQUIRED)' ""

    substituteInPlace packaging/linux/sunshine.desktop \
      --subst-var-by PROJECT_NAME 'Apollo' \
      --subst-var-by PROJECT_DESCRIPTION 'Self-hosted game stream host for Moonlight' \
      --subst-var-by SUNSHINE_DESKTOP_ICON 'sunshine' \
      --subst-var-by CMAKE_INSTALL_FULL_DATAROOTDIR "$out/share" \
      --replace-fail '/usr/bin/env systemctl start --u sunshine' 'sunshine'

    substituteInPlace packaging/linux/sunshine.service.in \
      --subst-var-by PROJECT_DESCRIPTION 'Self-hosted game stream host for Moonlight' \
      --subst-var-by SUNSHINE_EXECUTABLE_PATH $out/bin/sunshine
  '';

  preBuild = ''
    # copy webui where it can be picked up by build
    #   mkdir -p ../sunshine/assets/web
    #cp -r ${ui}/* ../sunshine/assets/web
    #cp -r ${ui}/* ../sunshine/assets/web
  cp -r ${ui}/build ../     # this is original line in sunshine package
  #  mkdir -p build/assets/web
  #cp -r ${ui}/build/* build/assets/web
  '';

  buildFlags = [
    "sunshine" # Change to the appropriate build target
  ];

  # allow Apollo to find libvulkan
  postFixup = lib.optionalString cudaSupport ''
    wrapProgram $out/bin/apollo \
      --set LD_LIBRARY_PATH ${lib.makeLibraryPath [ vulkan-loader ]}
  '';

  # redefine installPhase to avoid attempt to build webui
  installPhase = ''
    runHook preInstall
    cmake --install .
    runHook postInstall
  '';

  postInstall = ''
    install -Dm644 ../packaging/linux/sunshine.desktop $out/share/applications/${pname}.desktop
  '';

  meta = with lib; {
    description = "Apollo is a Game stream host for Moonlight";
    homepage = "https://github.com/ClassicOldSong/Apollo";
    license = licenses.gpl3Only;
    mainProgram = "apollo";
    maintainers = with maintainers; [ ]; # Add yourself here if you're maintaining this
    platforms = platforms.linux;
  };
}