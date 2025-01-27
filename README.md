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