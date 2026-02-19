#!/bin/bash

notify-send "Getting list of available Wi-Fi networks..."
# Get a list of available wifi networks and display them in wofi
wifi_list=$(nmcli --fields "SECURITY,SSID" device wifi list | sed 1d | sed 's/  */ /g' | sed -E "s/WINFRA //g" | sed "s/--/Open/g" | sed "s/802.1X/Protected/g" | grep -v "^--")
connected=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d\' -f2)

# Use wofi to select a wifi network
chosen_network=$(echo -e "$wifi_list" | uniq -u | wofi --show dmenu --prompt "Wi-Fi SSID: $connected" --width=400 --height=300)

# Get the SSID from the chosen network
read -r chosen_id <<< "${chosen_network} "
chosen_ssid=$(echo "${chosen_network}" | awk '{$1=""; print $0}' | sed 's/^ *//')

if [ "$chosen_ssid" = "" ]; then
    exit
fi

# Message to show when connection is activated successfully
success_message="You are now connected to the Wi-Fi network \"$chosen_ssid\"."

# Get saved connections
saved_connections=$(nmcli -g NAME connection)

if [[ $(echo "$saved_connections" | grep -w "$chosen_ssid") = "$chosen_ssid" ]]; then
    nmcli connection up id "$chosen_ssid" | grep "successfully" && notify-send "Connection Established" "$success_message"
else
    if [[ "$chosen_network" =~ "Open" ]]; then
        nmcli device wifi connect "$chosen_ssid" | grep "successfully" && notify-send "Connection Established" "$success_message"
    else
        # Prompt for password
        wifi_password=$(wofi --show dmenu --prompt "Password for $chosen_ssid" --password --width=300 --height=100)
        nmcli device wifi connect "$chosen_ssid" password "$wifi_password" | grep "successfully" && notify-send "Connection Established" "$success_message"
    fi
fi
