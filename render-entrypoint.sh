#!/bin/sh
set -e

echo "Starting OJS Initialization..."

# Create necessary directories on the persistent disk
# We use a subfolder inside the mount point because mount roots often resist chown/chmod
mkdir -p /var/www/files/ojsdata
mkdir -p /var/www/files/public

# Give full read/write to the directory regardless of the web server user
chmod -R 777 /var/www/files/ojsdata
chmod -R 777 /var/www/files/public

# Handle public directory (used for logos, custom CSS, etc)
echo "First time setup: Linking public directory contents to persistent disk..."
# Copy existing files to persistent disk if any
if [ "$(ls -A /var/www/html/public)" ]; then
    cp -an /var/www/html/public/* /var/www/files/public/ || true
fi
# Empty the volume directory
rm -rf /var/www/html/public/*
# Symlink subdirectories
mkdir -p /var/www/files/public/site
mkdir -p /var/www/files/public/journals
ln -sf /var/www/files/public/site /var/www/html/public/site
ln -sf /var/www/files/public/journals /var/www/html/public/journals
chmod -R 777 /var/www/files/public

# Ensure OJS correctly handles Render's reverse proxy (fixes CSS and redirect loops)
if [ -f "/var/www/html/config.TEMPLATE.inc.php" ]; then
    sed -i "s/force_ssl = Off/force_ssl = On/g" /var/www/html/config.TEMPLATE.inc.php
    sed -i "s/trust_x_forwarded_for = Off/trust_x_forwarded_for = On/g" /var/www/html/config.TEMPLATE.inc.php
fi

# Nuke-proof HTTPS fix: Force PHP to see HTTPS directly
if [ -f "/var/www/html/index.php" ]; then
    # We only inject it if not already injected
    if ! grep -q '$_SERVER\["HTTPS"\]' /var/www/html/index.php; then
        sed -i 's/<?php/<?php\n\$_SERVER\["HTTPS"\] = "on";\n/g' /var/www/html/index.php
    fi
fi

# Handle config.inc.php
if [ -f "/var/www/files/config.inc.php" ]; then
    echo "Found persistent config.inc.php. Linking it..."
    rm -f /var/www/html/config.inc.php
    ln -s /var/www/files/config.inc.php /var/www/html/config.inc.php
else
    echo "No persistent config found."
    echo "Starting background task to save config once installation completes..."
    
    # Wait for installation to complete and then save the config safely
    sh -c '
        while true; do
            if [ -f "/var/www/html/config.inc.php" ] && grep -q "^installed = On" "/var/www/html/config.inc.php" 2>/dev/null; then
                echo "Installation completed! Moving config to persistent disk..."
                cp /var/www/html/config.inc.php /var/www/files/config.inc.php
                rm /var/www/html/config.inc.php
                ln -s /var/www/files/config.inc.php /var/www/html/config.inc.php
                chmod 777 /var/www/files/config.inc.php
                break
            fi
            sleep 5
        done
    ' &
fi

echo "Initialization complete. Starting OJS..."
exec ojs-start
