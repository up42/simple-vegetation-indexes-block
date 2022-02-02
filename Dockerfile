FROM alpine:latest

# Required packages.
RUN apk add --no-cache bash coreutils moreutils jq wget file

# Get OrfeoToolbox from the official binaries.
WORKDIR /otb

RUN wget https://www.orfeo-toolbox.org/packages/OTB-7.4.0-Linux64.run && \
    chmod +x OTB-7.4.0-Linux64.run && \
    ./OTB-7.4.0-Linux64.run

# Get the script for computing the indexes.
COPY indexes.sh .
RUN chmod 755 indexes.sh

# Invoking the script to compute the indexes.
CMD ["./indexes.sh"]
