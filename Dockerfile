# Base MATLAB image, extended from the matlab-ref-arch group
FROM ubuntu:22.04

# Install the apt dependencies
ENV DEBIAN_FROTNEND="noninteractive" TZ="Etc/UTC"
COPY apt-dependencies.txt apt-dependencies.txt
RUN apt-get update \
    && apt-get install --no-install-recommends -y `grep -ve \# apt-dependencies.txt | xargs` \
    && apt-get clean \
    && apt-get -y autoremove \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf apt-dependencies.txt

# Install extrausers for adding our user on the fly
RUN sed -i '/^passwd:/ s/$/ extrausers/' /etc/nsswitch.conf \
    && sed -i '/^group:/ s/$/ extrausers/' /etc/nsswitch.conf
