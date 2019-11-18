A container to help manage TUF targets in the foundries.io ota-lite service.

## How to use this image
You can publish an OSTree repo using your OTA connect credentials.zip with:
```
# Pick your machine type: raspberrypi3-64, cl-som-imx7, intel-corei7-64, etc
MACHINE=raspberrypi3-64
docker run --rm -it -v $PWD:/build --workdir=/build \
       hub.foundries.io/aktualizr: \
       ota-publish -m $MACHINE -c credentials.zip \
                   -r ostree_repo
```
