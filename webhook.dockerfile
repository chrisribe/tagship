FROM almir/webhook

USER root

# Install git and docker CLI
RUN apk add --no-cache git docker-cli docker-cli-compose bash openssh-client gettext

# Pre-populate GitHub's host key
RUN mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh && \
    ssh-keyscan github.com >> /root/.ssh/known_hosts

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
