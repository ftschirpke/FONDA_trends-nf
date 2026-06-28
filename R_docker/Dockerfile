###########################################################################
# :AUTHOR: Katarzyna Ewa Lewinska  [lewinska@hu-berlin.de]
# :DATE: 14 March 2023
#
# :Description: A Docker image for a container to run remotePARTS
#
# :Updates:
#
# :2Do:
#
# :Disclaimer:  The author of this code accepts no responsibility for errors or omissions in this work
#               and shall not be liable for any damage caused by these.
###########################################################################

FROM r-base:4.2.2

# disable interactive frontends
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -o Acquire::AllowInsecureRepositories=true || true && \
    apt-get install -y --allow-unauthenticated debian-archive-keyring && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        cmake \
        libcurl4-openssl-dev \
        libfontconfig1-dev \
        libfreetype6-dev \
        libfribidi-dev \
        libgdal-dev \
        libharfbuzz-dev \
        libjpeg-dev \
        libpng-dev \
        libssh2-1-dev \
        libssl-dev \
        libtiff5-dev \
        libxml2-dev \
        zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*

RUN Rscript -e "options(warn=2); install.packages(c('devtools', 'dplyr', 'snow', 'doParallel', 'foreach', 'raster', 'data.table'), repos='https://cloud.r-project.org')" && \
    Rscript -e "devtools::install_github('morrowcj/remotePARTS')" && \
    Rscript -e "install.packages('sp', repos='https://cloud.r-project.org')" && \
    Rscript -e "install.packages('rgdal_1.6-7.tar.gz', repos=NULL, type='source')" && \
    rm rgdal_1.6-7.tar.gz
RUN apt-get clean && rm -r /var/cache/


ENV HOME /home/docker

WORKDIR /home/docker

CMD ['Rsc']
