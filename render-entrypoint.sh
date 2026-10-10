#!/bin/bash
set -e

echo "Starting OJS Initialization..."

# Create necessary directories on the persistent disk
mkdir -p /var/www/files/public
mkdir -p /var/www/files/submissions

# Make sure permissions are correct for Apache
chown -R www-data:www-data /var/www/files

# Handle public directory (used for logos, custom CSS, etc)
# If it's not a symlink yet, set it up
if [ -d "/var/www/html/public" ] && [ ! -L "/var/www/html/public" ]; then
    echo "First time setup: Linking public directory to persistent disk..."
    # Copy existing files to persistent disk if any
    if [ "$(ls -A /var/www/html/public)" ]; then
        cp -an /var/www/html/public/* /var/www/files/public/ || true
    fi
    rm -rf /var/www/html/public
    ln -s /var/www/files/public /var/www/html/public
    chown -R www-data:www-data /var/www/files/public
fi

# Handle config.inc.php
if [ -f "/var/www/files/config.inc.php" ]; then
    echo "Found persistent config.inc.php. Linking it..."
    rm -f /var/www/html/config.inc.php
    ln -s /var/www/files/config.inc.php /var/www/html/config.inc.php
else
    echo "No persistent config found."
    echo "Starting background task to watch for installation completion..."
    
    # Run in background: wait until OJS writes 'installed = On' to config
    bash -c '
        while true; do
            if [ -f "/var/www/html/config.inc.php" ] && grep -q "^installed = On" "/var/www/html/config.inc.php" 2>/dev/null; then
                echo "Installation completed! Moving config to persistent disk..."
                cp /var/www/html/config.inc.php /var/www/files/config.inc.php
                rm /var/www/html/config.inc.php
                ln -s /var/www/files/config.inc.php /var/www/html/config.inc.php
                chown www-data:www-data /var/www/files/config.inc.php
                break
            fi
            sleep 5
        done
    ' &
fi

echo "Initialization complete. Starting Apache..."
# Start the standard apache process from the PHP base image
exec apache2-foreground
