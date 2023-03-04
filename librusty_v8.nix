{
  rust,
  stdenv,
  fetchurl,
}: let
  arch = rust.toRustTarget stdenv.hostPlatform;
  fetch_librusty_v8 = args:
    fetchurl {
      name = "librusty_v8-${args.version}";
      url = "https://github.com/denoland/rusty_v8/releases/download/v${args.version}/librusty_v8_release_${arch}.a";
      sha256 = args.shas.${stdenv.hostPlatform.system};
      meta = {inherit (args) version;};
    };
in
  fetch_librusty_v8 {
    version = "0.32.1";
    shas = {
      x86_64-linux = "0ds3g30xk0k7x7chnzmx76vsamn39a52843kjygx09017vi6d56z";
      aarch64-linux = "15nk6vfw9f4jbm72arzkfxbc9ccpjm66h4mlvc787zd80qbn6nf3";
      x86_64-darwin = "1yf8hbpk9rgpmn3yvrdvwri6xbrjaw22j99ihhlwi034a7vcbnm0";
      aarch64-darwin = "1k3cbsv0gqr0zyg46bxci2cg6933xmaq7j39d9c65g5103a44gq7";
    };
  }
