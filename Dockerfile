FROM rocker/r-base:4.5.1 AS builder

WORKDIR /app

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
  libxml2-dev \
  libssl-dev

COPY DESCRIPTION /app/

RUN Rscript -e "install.packages('remotes')"
RUN Rscript -e "remotes::install_deps(dependencies = TRUE)"

COPY main.R sql/ ./

RUN Rscript -e "install.packages('lintr')"
RUN Rscript -e "lintr::lint_package()"

COPY tests/ ./

RUN Rscript -e "install.packages('testthat')"
RUN Rscript -e "testthat::test_dir('tests')"


FROM rocker/r-base:4.5.1

ENV PROCESSING_PERIOD=""
ENV ACTIVE_PERIOD=""

WORKDIR /app

COPY --from=builder /usr/local/lib/R/site-library /usr/local/lib/R/site-library
COPY --from=builder /app /app

CMD ["Rscript", "main.R"]
