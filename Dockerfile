# Use an official Ubuntu as a parent image
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ARG CMDSTAN_VERSION=2.26.2
ARG DUCKDB_CLI_VERSION=0.5.0
ARG GIT_CODE_REPO=aaweaver-actuary/omni
ARG GIT_MODEL_FILE=model.stan
ARG DATA_FILE=data.parquet


# Set working directory
WORKDIR /workspace

# Install basic utilities
RUN apt-get update -o Acquire::https::Verify-Peer=false  \
    && apt-get install -o Acquire::https::Verify-Peer=false -y \
        curl \
        build-essential \
        git \
        wget \
        ca-certificates \
\
    && ( \
        echo "Downloading and installing command-line stan (for model fitting)" \
        && wget https://github.com/stan-dev/cmdstan/releases/download/v${CMDSTAN_VERSION}/cmdstan-${CMDSTAN_VERSION}.tar.gz -O /tmp/cmdstan.tar.gz \
        && mkdir -p /opt/cmdstan \
        && tar -xzf /tmp/cmdstan.tar.gz -C /opt/cmdstan --strip-components=1 \
        && rm /tmp/cmdstan.tar.gz \
        && cd /opt/cmdstan \
        && make build \
    ) || ( \
        echo "Failed to download cmdstan-${CMDSTAN_VERSION}.tar.gz. Adding blank files." \
        && mkdir -p /opt/cmdstan \
        && touch /opt/cmdstan/stan \
        && chmod +x /opt/cmdstan/stan \
    ) \
\
    && ( \
        echo "Downloading and installing duckdb (for data processing)" \
        && wget https://github.com/duckdb/duckdb/releases/download/v${DUCKDB_CLI_VERSION}/duckdb_cli-linux-amd64.zip -O /tmp/duckdb_cli.zip \
        && unzip /tmp/duckdb_cli.zip -d /opt/duckdb \
        && rm /tmp/duckdb_cli.zip \
    ) || ( \
        echo "Failed to download duckdb_cli-linux-amd64.zip. Adding blank files." \
        && mkdir -p /opt/duckdb \
        && touch /opt/duckdb/duckdb \
        && chmod +x /opt/duckdb/duckdb \
    ) \
\
    && mkdir -p /workspace/code \
    && ( \
        echo "Cloning repo ${GIT_CODE_REPO} to get model file ${GIT_MODEL_FILE} (model definition)" \
        && git clone -c http.sslVerify=false http://github.com/${GIT_CODE_REPO} /workspace/code \
        && cp /workspace/code/${GIT_MODEL_FILE} /workspace/${GIT_MODEL_FILE} \
        && cp /workspace/code/run_model.sh /workspace/run_model.sh \
        && rm -rf /workspace/code \
        && chmod +x /workspace/run_model.sh \
    ) || ( \
        echo "Failed to clone code repository. Adding blank files." \
        && touch /workspace/${GIT_MODEL_FILE} \
        && touch /workspace/run_model.sh \
    ) \
    \
    && apt-get clean \
    && apt-get remove -y \
        curl \
        wget \
        ca-certificates \
        git \
        build-essential \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/* \
    && rm -rf /var/cache/apt/archives/*


# Add CMDStan to path
ENV PATH="/opt/cmdstan/bin:${PATH}"

# Add DuckDB CLI to path
ENV PATH="/opt/duckdb:${PATH}"

# Set environment variables for CMDStan
ENV STAN_NUM_THREADS=4

# Default command to execute the container
CMD ["./run_model.sh"]
