FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        software-properties-common \
        ca-certificates \
        gnupg2 \
    && rm -rf /var/lib/apt/lists/*

RUN add-apt-repository -y ppa:ubuntugis/ubuntugis-unstable

RUN apt-get update && apt-get install -y --no-install-recommends \
        dirmngr \
        wget \
        cmake \
        python3-pip \
        python3-dev \
        gdal-bin \
        libgdal-dev \
        libgeos-dev \
        libproj-dev \
        libspatialindex-dev \
        libtbb-dev \
        libnetcdf-dev \
        libtiff-dev \
        libjpeg-dev \
        libpng-dev \
        libwebp-dev \
        libopenjp2-7-dev \
        libcfitsio-dev \
        libhdf4-alt-dev \
        libhdf5-dev \
        libnetcdf-dev \
        libpq-dev \
        libcairo2-dev \
        libblas-dev \
        liblapack-dev \
        gfortran \
        libuv1-dev \
        libharfbuzz-dev \
        libfribidi-dev \
        r-base \
        r-base-dev \
        r-cran-devtools \
        r-cran-dplyr \
        r-cran-snow \
        r-cran-doparallel \
        r-cran-foreach \
        r-cran-raster \
        r-cran-data.table \
        r-cran-geosphere \
        && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p ~/.R && \
    echo "CXX = g++ -std=c++17" >> ~/.R/Makevars && \
    echo "CXXFLAGS = -fpic -g -O2" >> ~/.R/Makevars && \
    echo "CXX11 = g++ -std=c++17" >> ~/.R/Makevars && \
    echo "CXX14 = g++ -std=c++17" >> ~/.R/Makevars && \
    echo "CXX17 = g++ -std=c++17" >> ~/.R/Makevars

RUN Rscript -e "options(warn=2);install.packages('remotePARTS')"
RUN Rscript -e "options(warn=2);install.packages('rgdal', repos='https://packagemanager.posit.co/cran/2023-10-03')"
RUN Rscript -e "options(warn=2);remotes::install_github('rspatial/terra')"
