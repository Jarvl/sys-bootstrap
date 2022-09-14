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

A `Dockerfile` is included with this project to simulate testing on a fresh installation of Ubuntu. The bootstrap script should be run with this docker image after making any changes to the script. Once the script is done executing, the docker container will exit and be removed.

Build the container
```bash
$ docker build -t sys-bootstrap .
```

Run the container
```bash
$ docker run --rm -v .:/sys-bootstrap sys-bootstrap
```