FROM pkpofficial/ojs:3.4.0-5

# Copy our custom entrypoint script
COPY render-entrypoint.sh /usr/local/bin/render-entrypoint.sh

# Make the entrypoint executable
RUN chmod +x /usr/local/bin/render-entrypoint.sh

# Render will override the CMD via render.yaml using `dockerCommand`,
# but we can set the ENTRYPOINT here just in case, though we will
# rely on `dockerCommand: /usr/local/bin/render-entrypoint.sh` for maximum compatibility
# with Render's docker execution model.
