# Stage 1: The Builder Stage
# This stage is for building and installing dependencies.
FROM rocker/r-base:4.5.1 AS builder

# Set a working directory
WORKDIR /app

# Install system dependencies if needed
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
  libxml2-dev \
  libssl-dev

# Install R dependencies from DESCRIPTION file
# We use the r-lib/actions/setup-r-dependencies equivalent in a Docker context
RUN install.packages("remotes")
COPY DESCRIPTION /app/
RUN Rscript -e "remotes::install_deps(dependencies = TRUE)"

# Copy the application code to be linted and tested
COPY main.R sql/ ./

# Run linting
RUN Rscript -e "install.packages('lintr')"
RUN Rscript -e "lintr::lint_package()"

# Run tests
RUN Rscript -e "install.packages('testthat')"
RUN Rscript -e "testthat::test_dir('tests')"


# Stage 2: The Runner Stage
# This stage is for the final, production-ready image.
FROM rocker/r-base:4.5.1

ENV PROCESSING_PERIOD=""
ENV ACTIVE_PERIOD=""

# Set a working directory
WORKDIR /app

# Copy R packages from the builder stage
# This copies all installed packages without the build tools
COPY --from=builder /usr/local/lib/R/site-library /usr/local/lib/R/site-library
COPY --from=builder /app /app

# Command to run your R application
CMD ["Rscript", "main.R"]
