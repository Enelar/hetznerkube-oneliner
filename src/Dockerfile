FROM golang:alpine

ENTRYPOINT ["/init.sh"]
VOLUME /keys

RUN apk add --update --no-cache git
RUN go get -u github.com/xetys/hetzner-kube

ENV PYTHONUNBUFFERED=1
RUN apk add --update --no-cache python3 bash jq && ln -sf python3 /usr/bin/python
RUN python3 -m ensurepip
RUN pip3 install --no-cache --upgrade pip setuptools
RUN pip install --no-cache --upgrade yq

RUN wget -q "https://storage.googleapis.com/kubernetes-release/release/$(wget -q -O - https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl" -O /usr/local/bin/kubectl \
  && chmod +x /usr/local/bin/kubectl 

COPY * /