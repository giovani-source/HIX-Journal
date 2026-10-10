#!/bin/sh
set -e

echo "Starting OJS Initialization..."

# Create necessary directories on the persistent disk
mkdir -p /var/www/files/public
mkdir -p /var/www/files/submissions

# Give full read/write to the directory regardless of the web server user
chmod -R 777 /var/www/files

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

# Handle config.inc.php
if [ -f "/var/www/files/config.inc.php" ]; then
    echo "Found persistent config.inc.php. Linking it..."
    rm -f /var/www/html/config.inc.php
    ln -s /var/www/files/config.inc.php /var/www/html/config.inc.php
else
    echo "No persistent config found."
    echo "Starting background task to watch for installation completion..."
    
    # Run in background: wait until OJS writes 'installed = On' to config
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

echo "Initialization complete. Starting Apache..."
# Start the standard apache process from the PHP base image
exec ojs-start
