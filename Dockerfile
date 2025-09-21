FROM rocker/r-base:4.5.1

ENV PROCESSING_PERIOD=""
ENV ACTIVE_PERIOD=""

WORKDIR /app

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev && \
    rm -rf /var/lib/apt/lists/*

ADD DESCRIPTION .

RUN R -e "options(warn=2); remotes::install_deps()"

# Copy the R script and deps into image
COPY main.R sql/ ./

# Run the main R script when the image starts
CMD ["Rscript", "main.R"]
