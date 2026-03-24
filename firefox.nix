{ config, pkgs, ... }:

let
  c = config.theme.colors;

  lock-false = { Value = false; Status = "locked"; };
  lock-true  = { Value = true;  Status = "locked"; };

  extension = shortId: uuid: {
    name = uuid;
    value = {
      install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${shortId}/latest.xpi";
      installation_mode = "normal_installed";
    };
  };

  userChrome = ''
    :root {
      --gruvbox-bg:      #${c.bg};
      --gruvbox-bg1:     #${c.bg1};
      --gruvbox-bg2:     #${c.bg2};
      --gruvbox-fg:      #${c.fg};
      --gruvbox-accent:  #${c.accent};
      --gruvbox-gray:    #${c.gray};
      --gruvbox-blue:    #${c.blue};
    }

    /* Toolbar and tab bar */
    #navigator-toolbox {
      background-color: var(--gruvbox-bg) !important;
      border-bottom: 1px solid var(--gruvbox-bg1) !important;
    }

    /* Tabs */
    .tab-background {
      background-color: var(--gruvbox-bg) !important;
    }

    tab[selected] .tab-background {
      background-color: var(--gruvbox-bg1) !important;
    }

    .tab-label {
      color: var(--gruvbox-gray) !important;
    }

    tab[selected] .tab-label {
      color: var(--gruvbox-fg) !important;
    }

    /* URL bar */
    #urlbar {
      background-color: var(--gruvbox-bg1) !important;
      color: var(--gruvbox-fg) !important;
      border-color: var(--gruvbox-bg2) !important;
    }

    #urlbar:focus-within {
      border-color: var(--gruvbox-accent) !important;
    }

    #urlbar-input {
      color: var(--gruvbox-fg) !important;
    }

    /* Toolbar buttons */
    toolbar {
      background-color: var(--gruvbox-bg) !important;
    }

    toolbarbutton {
      color: var(--gruvbox-gray) !important;
    }

    toolbarbutton:hover {
      background-color: var(--gruvbox-bg1) !important;
      color: var(--gruvbox-fg) !important;
    }

    /* Sidebar */
    #sidebar-box {
      background-color: var(--gruvbox-bg) !important;
      color: var(--gruvbox-fg) !important;
    }
  '';
in
{
  programs.firefox = {
    enable = true;

    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisableFirefoxAccounts = true;
      DisableAccounts = true;
      DisableFirefoxScreenshots = true;
      DisablePocket = true;
      DisableFormHistory = true;
      DontCheckDefaultBrowser = true;
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";
      DisplayBookmarksToolbar = "never";
      DisplayMenuBar = "default-off";
      SearchBar = "unified";
      ShowHomeButton = false;
      HttpsOnlyMode = "enabled";
      TranslateEnabled = false;
      OfferToSaveLogins = false;
      AutofillAddressEnabled = false;
      AutofillCreditCardEnabled = false;

      PictureInPicture = {
        Enabled = false;
        Locked = true;
      };

      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };

      Homepage = {
        URL = "chrome://browser/content/blanktab.html";
        StartPage = "previous-session";
      };

      SearchEngines = {
        Add = [
          {
            Alias = "@np";
            Description = "Search NixOS Packages";
            IconURL = "https://nixos.org/favicon.png";
            Method = "GET";
            Name = "NixOS Packages";
            URLTemplate = "https://search.nixos.org/packages?from=0&size=200&sort=relevance&type=packages&query={searchTerms}";
          }
          {
            Alias = "@no";
            Description = "Search NixOS Options";
            IconURL = "https://nixos.org/favicon.png";
            Method = "GET";
            Name = "NixOS Options";
            URLTemplate = "https://search.nixos.org/options?from=0&size=200&sort=relevance&type=packages&query={searchTerms}";
          }
        ];
      };

      ExtensionSettings = builtins.listToAttrs [
        (extension "ublock-origin"          "uBlock0@raymondhill.net")
        (extension "vimium-ff"              "{d7742d87-e61d-4b78-b8a1-b469842139fa}")
        (extension "zotero-connector"       "zotero@chnm.gmu.edu")
        (extension "todoist-task-manager"   "todoist@todoist.com")
      ];

      Preferences = {
        "browser.contentblocking.category"                                          = { Value = "strict"; Status = "locked"; };
        "extensions.pocket.enabled"                                                 = lock-false;
        "extensions.screenshots.disabled"                                           = lock-true;
        "browser.topsites.contile.enabled"                                          = lock-false;
        "browser.formfill.enable"                                                   = lock-false;
        "browser.search.suggest.enabled"                                            = lock-false;
        "browser.search.suggest.enabled.private"                                    = lock-false;
        "browser.urlbar.suggest.searches"                                           = lock-false;
        "browser.urlbar.showSearchSuggestionsFirst"                                 = lock-false;
        "browser.newtabpage.activity-stream.feeds.section.topstories"              = lock-false;
        "browser.newtabpage.activity-stream.feeds.snippets"                        = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includePocket"      = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includeBookmarks"   = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includeDownloads"   = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includeVisited"     = lock-false;
        "browser.newtabpage.activity-stream.showSponsored"                         = lock-false;
        "browser.newtabpage.activity-stream.system.showSponsored"                  = lock-false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites"                 = lock-false;
      };
    };

    profiles.default = {
      id = 0;
      name = "default";
      isDefault = true;

      settings = {
        # Enable userChrome.css
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "browser.uidensity" = 1;
        "browser.compactmode.show" = true;

        # UI
        "browser.aboutConfig.showWarning" = false;
        "browser.ctrlTab.recentlyUsedOrder" = false;
        "browser.tabs.loadInBackground" = true;
        "browser.link.open_newwindow" = true;
        "general.autoScroll" = true;
        "browser.shell.checkDefaultBrowser" = false;
        "browser.download.useDownloadDir" = false;
        "browser.helperApps.deleteTempFileOnExit" = true;
        "browser.uitour.enabled" = false;

        # URL bar bloat
        "browser.urlbar.quickactions.enabled" = false;
        "browser.urlbar.quickactions.showPrefs" = false;
        "browser.urlbar.shortcuts.quickactions" = false;
        "browser.urlbar.suggest.quickactions" = false;
        "browser.urlbar.showSearchSuggestionsFirst" = false;
        "browser.urlbar.suggest.calculator" = true;

        # New tab page
        "browser.newtabpage.activity-stream.default.sites" = "";
        "browser.newtabpage.activity-stream.feeds.topsites" = false;
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.discovery.enabled" = false;

        # Disable geolocation via Google/OS
        "geo.provider.use_gpsd" = false;
        "geo.provider.use_geoclue" = false;

        # Normandy/Shield (telemetry recipe system)
        "app.normandy.enabled" = false;
        "app.normandy.api_url" = "";
        "app.shield.optoutstudies.enabled" = false;

        # Telemetry — comprehensive kill
        "datareporting.policy.dataSubmissionEnabled" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "toolkit.telemetry.unified" = false;
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.server" = "data:,";
        "toolkit.telemetry.archive.enabled" = false;
        "toolkit.telemetry.newProfilePing.enabled" = false;
        "toolkit.telemetry.shutdownPingSender.enabled" = false;
        "toolkit.telemetry.shutdownPingSender.enabledFirstSession" = false;
        "toolkit.telemetry.updatePing.enabled" = false;
        "toolkit.telemetry.bhrPing.enabled" = false;
        "toolkit.telemetry.firstShutdownPing.enabled" = false;
        "toolkit.telemetry.coverage.opt-out" = true;
        "toolkit.coverage.opt-out" = true;
        "toolkit.coverage.endpoint.base" = "";
        "toolkit.telemetry.reportingpolicy.firstRun" = false;
        "browser.ping-centre.telemetry" = false;
        "browser.newtabpage.activity-stream.feeds.telemetry" = false;
        "browser.newtabpage.activity-stream.telemetry" = false;
        "browser.vpn_promo.enabled" = false;

        # Extensions
        "extensions.getAddons.showPane" = false;
        "extensions.htmlaboutaddons.recommendations.enabled" = false;
        "extensions.update.enabled" = false;

        # Network
        "network.connectivity-service.enabled" = false;

        # Always restore previous session on restart
        "browser.startup.page" = 3;
        "browser.sessionstore.resume_from_crash" = true;

        # Language / locale
        "general.useragent.locale" = "en-US";
        "intl.accept_languages" = "en-US, en";
        "intl.locale.requested" = "en-US";
        "browser.search.region" = "US";
        "distribution.searchplugins.defaultLocale" = "en-US";

        # Privacy
        "privacy.donottrackheader.enabled" = true;
        "dom.forms.autocomplete.formautofill" = false;

        # Print headers/footers
        "print.print_footerleft" = "";
        "print.print_footerright" = "";
        "print.print_headerleft" = "";
        "print.print_headerright" = "";
      };

      userChrome = userChrome;
    };
  };
}
