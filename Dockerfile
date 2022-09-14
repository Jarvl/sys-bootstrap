FROM ubuntu:22.04

RUN apt update && apt install -y sudo git
RUN useradd -m testuser && usermod -aG sudo testuser
RUN echo "testuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/10-testuser # Bypasses sudo prompting for password for testing purposes

USER testuser

WORKDIR /home/testuser/sys-bootstrap
COPY --chown=testuser:testuser . .

CMD ["./bootstrap.sh"]