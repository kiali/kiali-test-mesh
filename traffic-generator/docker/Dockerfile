FROM golang
LABEL maintainer="Kiali <kiali-dev@googlegroups.com>"
RUN go get -u github.com/tsenart/vegeta
ADD traffic-generator.sh .
CMD (./traffic-generator.sh)
USER 1000
