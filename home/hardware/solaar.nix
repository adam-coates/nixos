{ config, pkgs, ... }:

{
  xdg.configFile."solaar/config.yaml" = {
    force = true;
    source = ./solaar/config.yaml;
  };

  xdg.configFile."solaar/rules.yaml" = {
    force = true;
    text = ''
      %YAML 1.3
      ---
      - Test: [thumb_wheel_up, 10]
      - KeyPress:
        - Super_L
        - depress
      - MouseScroll: [0, 1]
      - Later: 1.0
      - KeyPress:
        - Super_L
        - release
      ...
      ---
      - Test: [thumb_wheel_down, 10]
      - KeyPress:
        - Super_L
        - depress
      - MouseScroll: [0, -1]
      - Later: 1
      - KeyPress:
        - Super_L
        - release
      ...
    '';
  };
}
