# sys-bootstrap
Utility for bootstrapping a fresh system (Ubuntu) install. Current use is for fresh bare metal installs on a workstation.


## Running Locally

### Prerequisites

Install git
```bash
$ sudo apt update && sudo apt install git
```

### Usage

Clone this repository, then run the following
```bash
$ cd sys-bootstrap && chmod +x bootstrap.sh && ./bootstrap.sh
```

## Development

A `Dockerfile` is included with this project to simulate testing on a fresh installation of Ubuntu. The bootstrap script should be run within the created docker container after making any changes to the script.

Build the container
```bash
$ docker build -t sys-bootstrap .
```

Run and SSH into container
```bash
$ docker run -ti -v $(pwd)/:/home/testuser/sys-bootstrap sys-bootstrap /bin/bash
```

After SSHing into the container, run the script
```bash
./bootstrap.sh
```

Cache can also be invalidated when running the script. This is useful for testing purposes or if the cache has persisted (via mounted volume) but container has not (e.g. container is removed after exiting the shell)
```bash
./boostrap.sh --no-cache
```