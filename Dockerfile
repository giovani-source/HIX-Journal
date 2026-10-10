FROM pkpofficial/ojs:stable-3_4_0

USER root

# Install PostgreSQL extensions so OJS can talk to Render's database
# OJS 3.4 image uses PHP 8.1 on Alpine. We need to install the extensions.
RUN apk update && apk add --no-cache postgresql-dev php81-pdo_pgsql php81-pgsql || true
RUN docker-php-ext-install pdo pdo_pgsql pgsql || true

# Copy our custom entrypoint script
COPY render-entrypoint.sh /usr/local/bin/render-entrypoint.sh
# Make the entrypoint executable
RUN chmod +x /usr/local/bin/render-entrypoint.sh

# Render will override the CMD via render.yaml using `dockerCommand`,
# but we can set the ENTRYPOINT here just in case, though we will
# rely on `dockerCommand: /usr/local/bin/render-entrypoint.sh` for maximum compatibility
# with Render's docker execution model.
