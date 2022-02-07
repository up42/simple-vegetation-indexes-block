FROM debian:testing-slim

# Required packages.
RUN apt-get update && \
    apt-get install -y --no-install-recommends jq moreutils coreutils bash otb-bin

# Get the script for computing the indexes.
COPY shell/indexes.sh .
RUN chmod 755 indexes.sh

# OrfeoToolbox environment variables.
ENV ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=8
ENV GDAL_NUM_THREADS=8

# Invoking the script to compute the indexes.
CMD ["./indexes.sh"]
