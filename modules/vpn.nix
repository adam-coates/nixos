# Uni Graz VPN, shared between the system helper (hosts/adam/default.nix) and
# the openconnect-sso auto-fill config (home/programs/openconnect-sso.nix).
#
# `user` doubles as the keyring account: the password is stored under it, and
# the TOTP seed under "totp/<user>".
{
  user = "adam.coates@uni-graz.at";
  gateway = "univpn.uni-graz.at";
  authgroup = "Bedienstete";
}
