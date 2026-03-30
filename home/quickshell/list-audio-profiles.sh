#!/usr/bin/env bash
# Outputs audio device profiles as parseable lines.
# Format:
#   DEVICE<TAB>id<TAB>name<TAB>description<TAB>api
#   PROFILE<TAB>device_id<TAB>index<TAB>name<TAB>description<TAB>available<TAB>active
# Only includes devices with >1 profile (excludes "off"-only devices).

pw-dump 2>/dev/null | @jq@ -r '
  [.[] | select(.type == "PipeWire:Interface:Device" and .info.params.EnumProfile != null)]
  | map(
      select([.info.params.EnumProfile[] | select(.name != "off")] | length > 0)
    )
  | .[] |
    .info.props as $props |
    (.id | tostring) as $id |
    "DEVICE\t" + $id + "\t" + ($props."device.name" // "unknown") + "\t" + ($props."device.description" // "Unknown Device") + "\t" + ($props."device.api" // "unknown"),
    (.info.params.Profile[0].name // "off") as $active |
    (.info.params.EnumProfile[] |
      select(.name != "off") |
      "PROFILE\t" + $id + "\t" + (.index | tostring) + "\t" + .name + "\t" + .description + "\t" + (.available // "unknown") + "\t" + (if .name == $active then "active" else "inactive" end)
    )
'
