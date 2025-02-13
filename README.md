# itg-bsys

A debian package that contains all the required software and 
scripts used on the itgmania bluesys image.

## Build from sources

1. Clone the repository

    ```bash
    git clone git@github.com:bluedot-arcade/itg-bsys.git
    cd itg-bsys
    ```

2. Init submodules

    ```bash
    git submodule update --init --recursive
    ```

3. Build the project

    ```bash
    ./build.sh
    ```

    This will build the `.deb` package in the `build` directory.

## Create an update media

An update media is a drive that can be connected to the target system
to perform an update.

The update media must a FAT32 formatted drive with the `BSYS-UPDATE` label
and an `itg-bsys` `.deb` package in the root directory. The system will automatically
detect the update media when plugged in and prompt the user to perform the update.

To create the update media the `make-update-media.sh` script can be used.

1. Build the project. You can skip this step if you have already built the project.

    ```bash
    ./build.sh
    ```

2. Connect a media drive to your system. For example, a USB drive. Make sure
the drive is big enough to hold the `.deb` package.

2. Run the `make-update-media.sh` script

    ```bash
    ./make-update-media.sh
    ```

3. The script will prompt you to select the drive you want to use as the update media. 

    For example:
    ```bash
    Listing available disks...
    1) /dev/sda - 931.5G
    2) /dev/sdb - 57.7G
    3) /dev/nvme0n1 - 931.5G
    Select a disk to format (1-3): 
    ```

    Select the drive you want to use as the update media by entering the corresponding number.
    
    In the example above, you would enter `2` to select `/dev/sdb` which is the USB drive.

4. Confirm the drive selection and wait for the script to finish.

    Be careful to select the correct drive as the script will format the drive and erase all data on it.

5. Safely remove the drive from your system.

    You can now connect the drive to the target system to perform the update.

    On the target system, you can run the `update-check` command to verify that
    the update media is connected and a new version is ready to be installed.

