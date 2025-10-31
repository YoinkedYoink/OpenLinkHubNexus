#!/bin/bash

rm -f ./OpenLinkHub
go build .

set -e
USERNAME="nord"
DIST="/etc/lsb-release"
SYSTEMD_FILE="/home/nord/.config/systemd/user/OpenLinkHub.service"
PRODUCT="OpenLinkHub"

if [ ! -f $PRODUCT ]; then
  echo "No binary file. Exit"
  exit 0
fi

# if [ -f $DIST ]; then
#   SYSTEMD_FILE="/etc/systemd/system/OpenLinkHub.service"
# else
#   SYSTEMD_FILE="/usr/lib/systemd/system/OpenLinkHub.service"
# fi


if [ -f $SYSTEMD_FILE ]; then
  tee $SYSTEMD_FILE <<- EOM
[Unit]
Description=Open source interface for iCUE LINK System Hub, Corsair AIOs and Hubs
After=default.target

[Service]
Type=simple
WorkingDirectory=%h/.local/share/$PRODUCT
ExecStart=%h/.local/share/$PRODUCT/$PRODUCT
ExecReload=/bin/kill -s HUP \$MAINPID
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOM
        sudo systemctl daemon-reload
fi


if [ -f $SYSTEMD_FILE ]; then
  echo "$PRODUCT is already installed. Performing upgrade"
  systemctl --user stop $PRODUCT
  cp -r ./ ${HOME}/.local/share/$PRODUCT
  chmod -R 755 ${HOME}/.local/share/$PRODUCT/
  chown -R "$USERNAME":"$USERNAME" ${HOME}/.local/share/$PRODUCT/
  cp ${HOME}/.local/share/$PRODUCT/99-openlinkhub.rules /etc/udev/rules.d/
  echo "Reloading udev..."
  systemctl --user daemon-reload
  systemctl --user start $PRODUCT
  echo "Done"
  exit 0
fi

echo "Installation is running..."
cp -r ../OpenLinkHub ${HOME}/.local/share
# Permissions
echo "Setting permissions..."
chmod -R 755 ${HOME}/.local/share/$PRODUCT/
chown -R "$USERNAME":"$USERNAME" ${HOME}/.local/share/$PRODUCT/

# systemd file
echo "Creating systemd file..."
tee $SYSTEMD_FILE <<- EOM
[Unit]
Description=Open source interface for iCUE LINK System Hub, Corsair AIOs and Hubs
After=default.target

[Service]
Type=simple
WorkingDirectory=%h/.local/share/$PRODUCT
ExecStart=%h/.local/share/$PRODUCT/$PRODUCT
ExecReload=/bin/kill -s HUP \$MAINPID
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOM

echo "Running systemctl daemon-reload"
systemctl --user daemon-reload

# echo "Setting udev device permissions..."
# sudo rm -f /etc/udev/rules.d/99-corsair*.rules
# sudo cp 99-openlinkhub.rules /etc/udev/rules.d/

# echo "Reloading udev..."
# sudo udevadm control --reload-rules
# sudo udevadm trigger

echo "Setting service to state: enabled"
systemctl --user enable $PRODUCT

echo "Starting $PRODUCT..."
systemctl --user start $PRODUCT

echo "Done. You can access WebUI console via: http://127.0.0.1:27003/"
exit 0

