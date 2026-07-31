{ ... }:

let
  vpn = import ../../modules/vpn.nix;

  # Uni Graz authenticates against Keycloak, whose form ids are stable across
  # the login and OTP steps. openconnect-sso walks these rules in order, waiting
  # for each selector to appear, so they must match the pages in sequence.
  #
  # `fill = "totp"` makes openconnect-sso derive a code from the seed in the
  # keyring (account "totp/<user>"), which is where `qr-totp save` puts it.
  #
  # With more than one registered token Keycloak first shows a chooser; the
  # tiles carry per-credential GUIDs, so the only stable handle is position:
  #   selector = ".otp-device--selector label:nth-of-type(N)"
  #   action = "click"
  # That rule would go immediately before the otp field. Not needed with a
  # single token, and it must be absent then -- openconnect-sso would otherwise
  # wait for a page that never appears.
  autoFillRules = ''
    [[auto_fill_rules."https://login.uni-graz.at/*"]]
    selector = "input#username"
    fill = "username"

    [[auto_fill_rules."https://login.uni-graz.at/*"]]
    selector = "input#password"
    fill = "password"

    [[auto_fill_rules."https://login.uni-graz.at/*"]]
    selector = "input#kc-login"
    action = "click"

    [[auto_fill_rules."https://login.uni-graz.at/*"]]
    selector = "input[name=otp]"
    fill = "totp"

    [[auto_fill_rules."https://login.uni-graz.at/*"]]
    selector = "input#kc-login"
    action = "click"

    [[auto_fill_rules."https://login.uni-graz.at/*"]]
    selector = "input#kc-accept"
    action = "click"

    [[auto_fill_rules."https://login.uni-graz.at/*"]]
    selector = "span#input-error"
    action = "stop"
  '';
in
{
  # openconnect-sso rewrites this file on every run. Home Manager owns it, so
  # that write fails -- openconnect-sso catches the error and carries on, which
  # is what keeps these rules from drifting.
  xdg.configFile."openconnect-sso/config.toml".text = ''
    on_disconnect = ""

    [default_profile]
    address = "${vpn.gateway}"
    user_group = ""
    name = "${vpn.authgroup}"

    [credentials]
    username = "${vpn.user}"

    [auto_fill_rules]
    ${autoFillRules}
  '';
}
