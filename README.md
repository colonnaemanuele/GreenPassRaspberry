# GreenPassRaspberry

Do you need a green pass reader and can't use your phone? This project will allow you to create a linux image for raspberry with a software installed directly inside to read the green pass. 

## Packer Plugin ARM Images
This plugin lets you take an existing ARM image, and modify it on your x86 machine.
With this plugin, you can:

- Provision new ARM images from existing ones.
- Use ARM binaries for provisioning (apt-get install for example)
- Resize the last partition (the filesystem partition in the raspberry pi) in case you need more space than the default.

### How it works?
The plugin runs the provisioners in a chroot environment.  Binary execution is done using
`qemu-arm-static`, via `binfmt_misc`.

### Dependencies:
This builder uses the following shell commands:
- `qemu-user-static` - Executing arm binaries. This is optional as the released binary can use embedded versions of `qemu-aarch64-static` and `qemu-arm-static`. If you have one installed, it will be used instead of the embedded ones.
- `losetup` - To mount the image. This command is pre-installed in most distributions.

To install the needed binaries on derivatives of the Debian Linux variant:
```shell
sudo apt install qemu-user-static
```

Fedora:
```shell
sudo dnf install qemu-user-static
```

Archlinux:
```shell
pacman -S qemu-arm-static
```
Other commands that are used are (that should already be installed) : mount, umount, cp, ls, chroot.

To resize the filesystem, the following commands are used:
- `e2fsck`
- `resize2fs`

To provide custom arguments to `qemu-arm-static` using the `qemu_args` config, `gcc` is required (to compile a C wrapper).

Note: resizing is only supported for the last active
partition in an MBR partition table (as there is no need to move things).

This builder uses the following uses this kernel feature:
- support for `/proc/sys/fs/binfmt_misc` so that ARM binaries are automatically executed with qemu

### Configuration
To use, you need to provide an existing image that we will then modify. We re-use packer's support
for downloading ISOs (though the image should not be an ISO file).
Supporting also zipped images (enabling you downloading official raspbian images directly).

See [raspbian_green_pass.json](samples/raspbian_green_pass.json) and [config.go](pkg/builder/config.go) for details.
For configuration reference, see the [builder doc](docs/builders/arm-image.mdx).

*Note* if your image is arm64, set `qemu_binary` to `qemu-aarch64-static` in your configuration json file.

# Compiling and Testing
## Building
As this tool performs low-level OS manipulations - consider using a VM to run this code for isolation. While this is recommended, it is not mandatory.

This project uses [go modules](https://github.com/golang/go/wiki/Modules) for dependencies introduced in Go 1.11.
To build:
```bash
git clone https://github.com/CarpiDiem98/GreenPassRaspberry.git
cd GreenPassRaspberry
go mod download
go build
```
## Running with locally
This builder requires root permissions as it performs low level machine operations. To run it locally,
you can set `PACKER_CONFIG_DIR` back to your local home before sudo-ing to packer. For example:
```
PACKER_CONFIG_DIR=$HOME sudo -E $(which packer) build .
```
## Running with Docker
### Prerequisites
Docker needs capability of creating new devices on host machine, so it can create `/dev/loop*` and mount image into it. While it may be possible to accomplish with multiple `--device-cgroup-rule` and `--add-cap`, it's much easier to use `--privileged` flag to accomplish that. Even so, it is considered bad practice to do so, do it with extra precautions. Also because of those requirements rootless will not work for this container.

### Clone this repo and build the Docker image locally

Build the Docker image locally
```shell
docker build -t packer-builder-arm .
```

Build the `samples/raspbian_green_pass.json` Packer image
```shell
docker run \
  --rm \
  --privileged \
  -v /dev:/dev \
  -v ${PWD}:/build:ro \
  -v ${PWD}/packer_cache:/build/packer_cache \
  -v ${PWD}/output-arm-image:/build/output-arm-image \
  -e PACKER_CACHE_DIR=/build/packer_cache \
  packer-builder-arm build samples/raspbian_green_pass.json
```
## Running Standalone
```
packer build samples/raspbian_green_pass.json
```
# Zipping
This arm image building proces may take some time to complete. You will get output file output-arm-image/image. You can archive the output image file to reduce the size on disk.
```shell
zip -r rm-image.zip output-arm-image/image
```
Finally Raspberry Pi image is ready to prepare SD card and boot-up the Raspberry Pi device. You can use the Raspberry Pi Imager or any other tool to create a bootable SD card.

# Flashing
We have a post-processor stage for flashing.

## Golang flasher
```shell
go build cmd/flasher/main.go
```

It will auto-detect most things and guides you with questions.

## dd
(Tested on MacOS)

```shell
# find the identifier of the device you want to flash
diskutil list

# un-mount the disk
diskutil unmountDisk /dev/disk2

# flash the image, go for a coffee
sudo dd bs=4m if=output-arm-image/image of=/dev/disk2

# eject the disk
diskutil eject /dev/disk2
```
