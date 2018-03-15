FROM golang
LABEL maintainer="TODO <TODO-dev@lists.jboss.org>"
RUN go get -u github.com/tsenart/vegeta
ADD traffic-generator.sh .
CMD (./traffic-generator.sh)
