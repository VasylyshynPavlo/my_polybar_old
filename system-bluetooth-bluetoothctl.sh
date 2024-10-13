#!/bin/sh

bluetooth_print() {
    if [ "$(systemctl is-active "bluetooth.service")" = "inactive" ]; then
        echo "󰂲"
    else
        powered=$(bluetoothctl show | grep "Powered" | awk '{print $2}')
        if [ "$powered" = "no" ]; then
            echo "󰂲"
        else
            devices_paired=$(bluetoothctl devices Paired | grep Device | cut -d ' ' -f 2)
            counter=0
            output="󰂱"

            for device in $devices_paired; do
                device_info=$(bluetoothctl info "$device")

                if echo "$device_info" | grep -q "Connected: yes"; then
                    device_output=$(echo "$device_info" | grep "Alias" | cut -d ' ' -f 2-)
                    device_battery_percent=$(echo "$device_info" | grep "Battery Percentage" | awk -F'[()]' '{print $2}' | tr -d '%')

                    if [ -n "$device_battery_percent" ]; then
                        device_output="$device_output $device_battery_percent%"
                    fi

                    output="$output $device_output"
                    counter=$((counter + 1))
                fi
            done

            if [ $counter -eq 0 ]; then
                echo ""
            else
                echo "$output"
            fi
        fi
    fi
}

bluetooth_toggle() {
    if bluetoothctl show | grep -q "Powered: no"; then
        bluetoothctl power on >> /dev/null
        sleep 1

        devices_paired=$(bluetoothctl devices Paired | grep Device | cut -d ' ' -f 2)
        echo "$devices_paired" | while read -r line; do
            bluetoothctl connect "$line" >> /dev/null
        done
    else
        devices_paired=$(bluetoothctl devices Paired | grep Device | cut -d ' ' -f 3)
        echo "$devices_paired" | while read -r line; do
            bluetoothctl disconnect "$line" >> /dev/null
        done

        bluetoothctl power off >> /dev/null
    fi
}

case "$1" in
    --toggle)
        bluetooth_toggle
        ;;
    *)
        bluetooth_print
        ;;
esac

