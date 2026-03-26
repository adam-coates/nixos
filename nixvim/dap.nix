{ pkgs, ... }:

{
  programs.nixvim.plugins = {
    dap = {
      enable = true;

      signs = {
        dapBreakpoint = { text = ""; texthl = "DiagnosticSignError"; };
        dapBreakpointRejected = { text = ""; texthl = "DiagnosticSignError"; };
        dapStopped = { text = ""; texthl = "DiagnosticSignWarn"; linehl = "Visual"; numhl = "DiagnosticSignWarn"; };
      };
    };

    dap-ui.enable = true;
    dap-virtual-text = {
      enable = true;
      settings.commented = true;
    };
    dap-python = {
      enable = true;
      adapterPythonPath = "python3";
    };
  };

  programs.nixvim.extraConfigLuaPost = ''
    -- DAP auto-open UI
    local dap, dapui = require("dap"), require("dapui")
    dap.listeners.after.event_initialized["dapui_config"] = function()
      dapui.open()
    end
  '';

  programs.nixvim.keymaps = [
    { mode = "n"; key = "<leader>db"; action.__raw = "function() require('dap').toggle_breakpoint() end"; options = { desc = "Toggle Breakpoint"; silent = true; }; }
    { mode = "n"; key = "<leader>dc"; action.__raw = "function() require('dap').continue() end"; options = { desc = "Start/Continue Debugging"; silent = true; }; }
    { mode = "n"; key = "<leader>do"; action.__raw = "function() require('dap').step_over() end"; options = { desc = "Step Over"; silent = true; }; }
    { mode = "n"; key = "<leader>di"; action.__raw = "function() require('dap').step_into() end"; options = { desc = "Step Into"; silent = true; }; }
    { mode = "n"; key = "<leader>dO"; action.__raw = "function() require('dap').step_out() end"; options = { desc = "Step Out"; silent = true; }; }
    { mode = "n"; key = "<leader>dq"; action.__raw = "function() require('dap').terminate() end"; options = { desc = "Quit Debugging"; silent = true; }; }
    { mode = "n"; key = "<leader>du"; action.__raw = "function() require('dapui').toggle() end"; options = { desc = "Toggle DAP UI"; silent = true; }; }
  ];
}
