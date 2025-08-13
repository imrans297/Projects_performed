#!/bin/bash
# Cron job script to automatically update inventory every 5 minutes

# Set up cron job for automatic inventory updates
(crontab -l 2>/dev/null; echo "*/5 * * * * /home/ubuntu/inventory_updater.sh update >> /var/log/inventory-update.log 2>&1") | crontab -

echo "Cron job set up to update inventory every 5 minutes"