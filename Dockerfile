FROM debian:testing-slim

# Required packages.
RUN apt-get update && \
    apt-get install -y --no-install-recommends jq moreutils coreutils bash otb-bin

# Get the script for computing the indexes.
COPY shell/indexes.sh .
RUN chmod 755 indexes.sh

# Invoking the script to compute the indexes.
CMD ["./indexes.sh"]
