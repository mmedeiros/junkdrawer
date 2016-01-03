#!/bin/bash

# Run the following on dhcp server to see mac addresses that are asking for new dhcp leases
cat /var/log/messages | grep "10." | grep -v 192 | grep -v smokeping | grep -i discov | cut -d':' -f4- | sort | uniq|  tail -n 30
