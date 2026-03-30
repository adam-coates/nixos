#!/usr/bin/env bash
# Queries MagicPodsCore WebSocket for earbuds battery info.
# Output: left_pct<TAB>left_charging<TAB>left_status<TAB>right_pct<TAB>right_charging<TAB>right_status<TAB>case_pct<TAB>case_charging<TAB>case_status<TAB>device_name
# Status: 0=NotAvailable 1=Disconnected 2=Connected 3=Cached
# Outputs "none" if no device is connected or daemon not running.

result=$(echo '{"method":"GetActiveDeviceInfo"}' | \
  @websocat@ -t -n --max-messages-rev 2 ws://127.0.0.1:2020/ 2>/dev/null | \
  grep '"info"')

if [ -z "$result" ]; then
  echo "none"
  exit 0
fi

connected=$(echo "$result" | grep -o '"connected":true' | head -1)
if [ -z "$connected" ]; then
  echo "none"
  exit 0
fi

get_battery_field() {
  echo "$result" | grep -oP "\"${1}\":\{[^}]*\"${2}\":\K[^,}]+" | head -1
}

left_bat=$(get_battery_field left battery)
left_chg=$(get_battery_field left charging)
left_st=$(get_battery_field left status)

right_bat=$(get_battery_field right battery)
right_chg=$(get_battery_field right charging)
right_st=$(get_battery_field right status)

case_bat=$(get_battery_field case battery)
case_chg=$(get_battery_field case charging)
case_st=$(get_battery_field case status)

name=$(echo "$result" | grep -oP '"name":"\K[^"]+' | tail -1)

printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
  "${left_bat:-0}" "${left_chg:-false}" "${left_st:-0}" \
  "${right_bat:-0}" "${right_chg:-false}" "${right_st:-0}" \
  "${case_bat:-0}" "${case_chg:-false}" "${case_st:-0}" \
  "${name:-Unknown}"
