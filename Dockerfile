FROM zmkfirmware/zmk-build-arm:stable

RUN apt-get update && apt-get install -y yq jq just curl
