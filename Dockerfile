FROM ubuntu:22.04

WORKDIR /sys-bootstrap
COPY . .

CMD ["./bootstrap.sh"]