FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get -y install bash procps openssl iproute2 curl jq libsnappy1v5 net-tools nano && \
    rm -rf /var/lib/apt/lists/* && \
    addgroup --gid 10000 vernemq && \
    adduser --uid 10000 --system --ingroup vernemq --home /vernemq --disabled-password vernemq

WORKDIR /vernemq

# Defaults
ENV DOCKER_VERNEMQ_KUBERNETES_LABEL_SELECTOR="app=vernemq" \
    DOCKER_VERNEMQ_LOG__CONSOLE=console \
    PATH="/vernemq/bin:$PATH" \
    CONNECTMQ_VERSION="v2.1.1"
COPY --chown=10000:10000 bin/vernemq.sh /usr/sbin/start_vernemq
COPY --chown=10000:10000 bin/join_cluster.sh /usr/sbin/join_cluster
COPY --chown=10000:10000 files/vm.args /vernemq/etc/vm.args

# Download Apache 2.0 licensed ConnectMQ binaries (no EULA required)
RUN ARCH=$(uname -m | sed -e 's/x86_64/amd64/' -e 's/aarch64/arm64/') && \
    curl -L https://github.com/connect-iot-bv/connectmq/releases/download/$CONNECTMQ_VERSION/connectmq-$CONNECTMQ_VERSION-linux-$ARCH.tar.gz -o /tmp/connectmq.tar.gz && \
    tar -xzvf /tmp/connectmq.tar.gz -C /tmp && \
    mv /tmp/vernemq/* /vernemq/ && \
    rm -rf /tmp/connectmq.tar.gz /tmp/vernemq && \
    chown -R 10000:10000 /vernemq && \
    ln -s /vernemq/etc /etc/vernemq && \
    ln -s /vernemq/data /var/lib/vernemq && \
    ln -s /vernemq/log /var/log/vernemq

# Ports
# 1883  MQTT
# 8883  MQTT/SSL
# 8080  MQTT WebSockets
# 44053 VerneMQ Message Distribution
# 4369  EPMD - Erlang Port Mapper Daemon
# 8888  Health, API, Prometheus Metrics
# 9100 9101 9102 9103 9104 9105 9106 9107 9108 9109  Specific Distributed Erlang Port Range

EXPOSE 1883 8883 8080 44053 4369 8888 \
       9100 9101 9102 9103 9104 9105 9106 9107 9108 9109


VOLUME ["/vernemq/log", "/vernemq/data", "/vernemq/etc"]

HEALTHCHECK CMD vernemq ping | grep -q pong

USER vernemq

CMD ["start_vernemq"]
