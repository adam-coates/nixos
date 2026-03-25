{ pkgs, ... }:

{
  programs.nixvim.plugins = {
    gitsigns.enable = true;

    lazygit = {
      enable = true;
      settings.floating_window_use_plenary = false;
    };
  };

  programs.nixvim.keymaps = [
    { mode = "n"; key = "<leader>lg"; action = "<cmd>LazyGit<cr>"; options.desc = "Open lazy git"; }
  ];

  programs.nixvim.extraPackages = with pkgs; [
    lazygit
  ];
}
