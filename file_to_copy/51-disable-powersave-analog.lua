-- Disable idle/suspend timeout for the Realtek ALC887-VD analog card
alsa_monitor.rules = {
  {
    matches = {
      {
        { "device.name", "matches", "alsa_card.pci-*" },
        { "device.nick", "matches", "ALC887%-VD*" },
      },
    },
    apply_properties = {
      ["api.alsa.idle.timeout-seconds"] = 0,      -- Prevent ALSA suspend
      ["session.suspend-timeout-seconds"] = 0,    -- Prevent WirePlumber suspend
    },
  },
}

