# Simple custom block to calculate vegetation indexes

## Introduction

The code in this repository implements a very simple block that
computes various vegetation indexes for
[Pléiades](https://docs.up42.com/getting-started/data-products/pleiades),
[SPOT 6/7](https://docs.up42.com/getting-started/data-products/spot/)
and [Sentinel-2](https://sentinel.esa.int/web/sentinel/missions/sentinel-2 "Sentinel-2").

 * [NDVI](https://en.wikipedia.org/wiki/Normalized_difference_vegetation_index) -
   Normalized Difference Vegetation Index
 * [GNDVI](https://www.indexdatabase.de/db/i-single.php?id=28) - Green
   Normalized Difference Vegetation Index
 * [EVI](https://en.wikipedia.org/wiki/Enhanced_vegetation_index) -
   Enhanced Vegetation Index
 * [EVI2](https://www.indexdatabase.de/db/si-single.php?sensor_id=96&rsindex_id=237) -
 Enhanced Vegetation Index 2
 * [EVI2-2](https://www.indexdatabase.de/db/i-single.php?id=576) -
   Enhanced Vegetation Index 2 - 2
 * [SAVI](https://en.wikipedia.org/wiki/Soil-adjusted_vegetation_index) -
   Soil-Adjusted Vegetation Index
 * [CVI](https://www.indexdatabase.de/db/i-single.php?id=391) -
   Chlorophyll Vegetation Index
 * [BAI](https://www.space4water.org/taxonomy/term/1255) - Burn Area Index
 * [NBR](https://un-spider.org/advisory-support/recommended-practices/recommended-practice-burn-severity/in-detail/normalized-burn-ratio) -
   Normalized Burn Ratio

The calculation is done using the
[OrfeoToolbox BandMath](https://www.orfeo-toolbox.org/CookBook/Applications/app_BandMath.html?highlight=bandmath)
utility.

Writen in C++, the [OrfeoToolbox](https://www.orfeo-toolbox.org/)
(OTB) is maintained by the French Space Agency &mdash; Centre National
d'Études Spatiales (CNES). It consists of a series of command line
utilities to work with remote sensing data sets from a user point of
view. It offers a toolkit/library to program remote sensing algorithms
in C++.

It has also a [Python API](https://www.orfeo-toolbox.org/CookBook/PythonAPI.html) and
a [QGIS](https://www.orfeo-toolbox.org/CookBook/QGISInterface.html)
interface.

Performance wise OTB offers [Streaming and
Threading](https://www.orfeo-toolbox.org/CookBook/C++/StreamingAndThreading.html)
for handling large datasets effectively.


### Inputs & outputs

This block takes as input a set of Level 2A Sentinel-2 images, a
Pléiades or SPOT 6/7 reflectance products for analysis.

The output is a set [GeoTIFF](https://en.wikipedia.org/wiki/GeoTIFF) files.

### Block capabilities

The block takes a set of GeoTIFF files as input
[capability](https://docs.up42.com/developers/blocks/capabilities)
and delivers a GeoTIFF as output capability.

## Requirements

### Generic

 1. [docker](https://docs.docker.com/install/).
 2. [GNU make](https://www.gnu.org/software/make/).

### For [local development](#local-development)

 1. [Bash](https://en.wikipedia.org/wiki/Bash_(Unix_shell)).
 2. [cURL](https://curl.haxx.se).
 3. [jq](https://stedolan.github.io/jq/).
 4. [GNU core utilities](https://www.gnu.org/software/coreutils/coreutils.html).
 5. [moreutils](https://joeyh.name/code/moreutils/).
 6. [OrfeoToolbox](https://www.orfeo-toolbox.org/).

## Usage

### Clone the repository

```bash
git clone git@github.com:up42/simple-vegetation-indexes-block.git <directory>
```
where `<directory>` is the directory where the cloning is done.

### Build the docker images

For building the images you should tag the image such that it can bu
pushed to the UP42 docker registry, enabling you to run it as a custom
block. For that you need to pass your user ID (UID) in the `make`
command.

The quickest way to get that is just to go into the UP42 console and
copy & paste from the last clipboard that you get at the
[custom-blocks](https://console.up42.com/custom-blocks) page and after
clicking on **PUSH a BLOCK to THE PLATFORM**. For example, it will be
something like:

```bash
docker push registry.up42.com/<UID>/<image_name>:<tag>
```

Now you can launch the image building using `make` like this:

```bash
make build UID=<UID>
```

You can avoid selecting the exact UID by using `pbpaste` in a Mac (OS
X) or `xsel --clipboard --output` in Linux and do:

```bash
# mac: OS X.
make build UID=$(pbpaste | cut -f 2 -d '/')

# Linux.
make build UID=$(xsel --clipboard --output | cut -f 2 -d '/')
```

You can additionaly specifiy a custom tag for your image (default tag
is `simple-vegetation-indexes:latest`):

```bash
make build UID=<UID> DOCKER_TAG=<docker tag>
```

if you don't specify the docker tag, it gets the default value of `latest`.

### Push the image to the UP42 registry

You first need to login into the UP42 docker registry.

```bash
make login USER=me@example.com
```

where `me@example.com` should be replaced by your username, which is
the email address you use in UP42.

Now you can finally push the image to the UP42 docker registry:

```bash
make push UID=<UID>
```

where `<UID>` is user ID referenced above. Again using the copy &
pasting on the clipboard.

```bash
# mac: OS X.
make build UID=$(pbpaste | cut -f 2 -d '/')

# Linux.
make build UID=$(xsel --clipboard --output | cut -f 2 -d '/')
```
```bash
make push UID=<UID>
```
Note that if you specified a custom docker tag when you built the image, you
need to pass it now to `make`.

```bash
make push UID=<UID> DOCKER_TAG=<docker tag>
```

where `<UID>` is user ID referenced above. Again using the copy &
pasting on the clipboard.

```bash
# mac: OS X.
make build UID=$(pbpaste | cut -f 2 -d '/') DOCKER_TAG=<docker tag>

# Linux.
make build UID=$(xsel --clipboard --output | cut -f 2 -d '/') DOCKER_TAG=<docker tag>
```

After the image is pushed you should be able to see your custom block
in the [console](https://console.up42.com/custom-blocks/) and you can
now use the block in a workflow.

### Run the processing block locally

#### Configure the job

To run the docker image locally you need first to configure the job
with the parameters specific to this block. Create a `params.json`
like this:

```js
{
  "polarisations": <array polarizations>,
  "mask": <array mask type>,
  "tcorrection": <boolean>
}
```
where:

+ `<array polarizations>`: JS array of possible polarizations: `"VV"`,
  `"VH"`, `"HV"`, `"HH"`.
+ `<array of mask type>`: JS array of possible mask `"sea"` or `"land"`.
+ `<boolean>`: `true` or `false` stating if terrain correction is to
  be done or not.

Here is an example `params.json`:

```js
{
  "polarisations": ["VV"],
  "mask": ["sea"],
  "tcorrection": false
}
```
#### Get the data

A radar image is needed for the block to run. Such image can be
obtained by creating a workflow with a single **Sentinel 1 L1C GRD**
data block and download the the result.

Then create the directory `/tmp/e2e_snap_polarimetric/`:

```bash
mkdir /tmp/e2e_snap_polarimetric
```

Now untar the tarball with the result in that directory:

```bash
tar -C /tmp/e2e_snap_polarimetric -zxvf <downloaded tarball>
```
#### Run the block

```bash
make run
```

If set a custom docker tag then the command ro run the block is:

```bash
make run DOCKER_TAG=<docker tag>
```

### Local development

#### Install the required programs


Now you need to [build](#build-the-docker-images) and
[run](#run-the-processing-block-locally) the block locally.

## Support

 1. Open an issue here.
 2. Reach out to us on
      [gitter](https://gitter.im/up42-com/community).
 3. Mail us [support@up42.com](mailto:support@up42.com).
