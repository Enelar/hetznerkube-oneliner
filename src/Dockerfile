FROM golang:alpine

ENTRYPOINT ["/init.sh"]
VOLUME /keys

ENV PYTHONUNBUFFERED=1
RUN apk add --update --no-cache python3 git bash jq && ln -sf python3 /usr/bin/python
RUN python3 -m ensurepip
RUN pip3 install --no-cache --upgrade pip setuptools
RUN pip install --no-cache --upgrade yq

RUN go get -u github.com/xetys/hetzner-kube

COPY *.sh /