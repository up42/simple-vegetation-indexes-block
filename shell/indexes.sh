#!/bin/bash

## indexes.sh --- Computes a set of vegetation indexes using OTB
## BandMath CLI utility.

## Copyright (C) 2022 UP42 GmbH.

## Author: António P. P. Almeida <antonio.almeida@up42.com>

# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# Except as contained in this notice, the name(s) of the above copyright
# holders shall not be used in advertising or otherwise to promote the sale,
# use or other dealings in this Software without prior written authorization.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

SCRIPTNAME=${0##*/}

## Required programs.
JQ=$(command -v jq) || exit 1
## Timestamp utility for logging.
TST=$(command -v ts) || exit 21

function print_usage() {
    echo "Usage: $SCRIPTNAME -p <params> -i <input directory> -o <output directory> -t <path to OTB installation>"
    exit 2
}

## Default input and output directories.
INPUT_DIR=/tmp/input
OUTPUT_DIR=/tmp/output

## Default location for the OrfeoToolbox.
OTB_PATH=/otb

## Source the parameters from the environment.
PARAMS="$UP42_TASK_PARAMETERS"

## Parse the arguments.
while getopts :i:o:p:t: OPT; do
    case $OPT in
        i|+i)
            INPUT_DIR="$(realpath "$OPTARG")"
            ;;
        o|+o)
            OUTPUT_DIR="$(realpath "$OPTARG")"
            ;;
        p|+p)
            PARAMS="$OPTARG"
            ;;
        t|+t)
            OTB_PATH="$OPTARG"
            ;;
        *)
            print_usage
            exit 3
    esac
done
shift $(( OPTIND - 1 ))
OPTIND=1

## Get the data.json path.
DATA_JSON="$INPUT_DIR/data.json"

if [ ! -r "$DATA_JSON" ]; then
    echo "$SCRIPTNAME: Cannot open data.json file."
    exit 4
fi

## Check for OrfeoToolbox's presence.
if [ -x "$OTB_PATH/otbenv.profile" ]; then
    source "$OTB_PATH/otbenv.profile"
else
    echo "$SCRIPTNAME: Cannot locate OrfeoToolbox installation."
    exit 5
fi

## Given a path returns the data path(s).
## $1: the path to the data.json file.
function get_data_path() {
    echo "$($JQ -r '.features[].properties | .["up42.data_path"]' "$1")"
}

## Get the constellation name from the metadata.
## $1: the path to the data.json file.
function get_constellation_name() {
    echo "$($JQ -r '.features[0].properties.constellation | ascii_downcase' "$1")"
}

## Logs a message and timestamps it.
## $1: log message.
function log_it() {
    ## Logs are written to stderr.
    printf '%s\n' "$1" | $TST "%b %d %H:%M:%.S"
}

## Copies the data.json file from input to output.
## $1: the path to the data.json file.
function create_data_json() {
    cp "$1" "$OUTPUT_DIR"
}

## Does the band math calculations for a given formula.
## $1: input data files.
## $2: muParser formula.
## $3: output file name component.
function do_band_math() {
    local out_fn out_dir
    ## Loop on the input images.
    for i in $1; do
        ## Get the output directory.
        out_dir="$OUTPUT_DIR/$(dirname $i)"
        ## Create the parant directory of the output file if it
        ## doesn't exist.
        test -d "$out_dir" || mkdir -p "$out_dir"
        ## Get the output file name,
        out_fn="$(basename "${i%%.*}")_$3.${i##*.}"
        ## Compute the band math.
        otbcli_BandMath -il "$INPUT_DIR/$i" \
                        -out "$out_dir/$out_fn" float \
                        -exp "$2" \
                        -ram $OTB_RAM
        ## Update the data paths in the output data.json. Since we may
        ## create multiple files per feature we point to the
        ## directory, instead of a particular file.
        $JQ --arg op "$i" --arg np "$(dirname $i)" '(.features[].properties | select(.["up42.data_path"] == $op) | .["up42.data_path"]) |= $np' $OUTPUT_DIR/data.json | sponge $OUTPUT_DIR/data.json 2>/dev/null
        log_it "Computing $3 for input $i."
    done
}

## Computes the NDVI for a given set of data.
## $1: the path to the data.json file.
## $2: output directory.
function compute_ndvi() {
    local constellation="$(get_constellation_name "$1")"

    case $constellation in
        spot|phr)
            do_band_math "$(get_data_path "$1")" "(im1b4-im1b1)/(im1b4+im1b1)" "ndvi"
            ;;
        sentinel-2)
            do_band_math "$(get_data_path "$1")" "(im1b8-im1b4)/(im1b8+im1b4)" "ndvi"
            ;;
        *)
            echo "$SCRIPTNAME: Cannot compute NDVI for constellation $constellation."
            exit 60
    esac
}

## Computes the GNDVI for a given set of data.
## $1: the path to the data.json file.
## $2: output directory.
function compute_gndvi() {
    local constellation="$(get_constellation_name "$1")"

    case $constellation in
        spot|phr)
            do_band_math "$(get_data_path "$1")" "(im1b4-im1b2)/(im1b4+im1b2)" "gndvi"
            ;;
        sentinel-2)
            do_band_math "$(get_data_path "$1")" "(im1b8-im1b3)/(im1b8+im1b3)" "gndvi"
            ;;
        *)
            echo "$SCRIPTNAME: Cannot compute GNDVI for constellation $constellation."
            exit 61
    esac
}

## Computes the EVI for a given set of data.
## $1: the path to the data.json file.
## $2: output directory.
function compute_evi() {
    local constellation="$(get_constellation_name "$1")"

    case $constellation in
        spot|phr)
            do_band_math "$(get_data_path "$1")" \
                         "2.5*(im1b4 - im1b1)/(im1b4 + 6*im1b1 - 7.5*im1b3 + 2^16)" "evi"
            ;;
        sentinel-2)
            do_band_math "$(get_data_path "$1")" \
                         "2.5*(im1b8 - im1b4)/(im1b8 + 6.4*im1b4 -7.5*im1b2+ 2^16)" "evi"
            ;;
        *)
            echo "$SCRIPTNAME: Cannot compute EVI for constellation $constellation."
            exit 80
    esac
}

## Computes the EVI2 for a given set of data.
## $1: the path to the data.json file.
## $2: output directory.
function compute_evi2() {
    local constellation="$(get_constellation_name "$1")"

    case $constellation in
        spot|phr)
            do_band_math "$(get_data_path "$1")" \
                         "2.5*(im1b4 - im1b1)/(im1b4 + 2.4*im1b1 + 2^16)" "evi2"
            ;;
        sentinel-2)
            do_band_math "$(get_data_path "$1")" \
                         "2.5*(im1b8 - im1b4)/(im1b8 + 2.4*im1b4 + 2^16)" "evi2"
            ;;
        *)
            echo "$SCRIPTNAME: Cannot compute EVI for constellation $constellation."
            exit 81
    esac
}

## Computes the EVI for a given set of data.
## $1: the path to the data.json file.
## $2: output directory.
function compute_evi22() {
    local constellation="$(get_constellation_name "$1")"

    case $constellation in
        spot|phr)
            do_band_math "$(get_data_path "$1")" \
                         "2.5*(im1b4 - im1b1)/(im1b4 + im1b1 + 2^16)" "evi22"
            ;;
        sentinel-2)
            do_band_math "$(get_data_path "$1")" \
                         "2.5*(im1b8 - im1b4)/(im1b8 + im1b4 + 2^16)" "evi22"
            ;;
        *)
            echo "$SCRIPTNAME: Cannot compute EVI for constellation $constellation."
            exit 82
    esac
}

## Computes the SAVI for a given set of data.
## $1: the path to the data.json file.
## $2: output directory.
function compute_savi() {
    local constellation="$(get_constellation_name "$1")"

    case $constellation in
        spot|phr)
            do_band_math "$(get_data_path "$1")" "1.5*(im1b4-im1b1)/(im1b4+im1b1+0.5*2^16)" "savi"
            ;;
        sentinel-2)
            do_band_math "$(get_data_path "$1")" "1.5*(im1b8-im1b4)/(im1b8+im1b4+0.5*2^16)" "savi"
            ;;
        *)
            echo "$SCRIPTNAME: Cannot compute SAVI for constellation $constellation."
            exit 9
    esac
}

## Computes the CVI for a given set of data.
## $1: the path to the data.json file.
## $2: output directory.
function compute_cvi() {
    local constellation="$(get_constellation_name "$1")"

    case $constellation in
        spot|phr)
            do_band_math "$(get_data_path "$1")" "im1b4 * im1b1/im1b2^2" "cvi"
            ;;
        sentinel-2)
            do_band_math "$(get_data_path "$1")" "im1b8 * im1b4/im1b3^2" "cvi"
            ;;
        *)
            echo "$SCRIPTNAME: Cannot compute CVI for constellation $constellation."
            exit 10
    esac
}

## Computes the Burn Area Index (BAI) for a given set of data.
## $1: the path to the data.json file.
## $2: output directory.
function compute_bai() {
    local constellation="$(get_constellation_name "$1")"

    case $constellation in
        spot|phr)
            do_band_math "$(get_data_path "$1")" \
                         "2^32/((0.1*2^16 - im1b1)^2 + (0.06*2^16 - im1b4)^2)" "bai"
            ;;
        sentinel-2)
            do_band_math "$(get_data_path "$1")" \
                         "2^32/((0.1 *2^16- im1b4)^2 + (0.06* 2^16 - im1b8)^2)" "bai"
            ;;
        *)
            echo "$SCRIPTNAME: Cannot compute BAI for constellation $constellation."
            exit 11
    esac
}

## Computes the Normal Burn Rate (NBR) for a given set of Sentinel 2
## data.
## $1: the path to the data.json file.
## $2: output directory.
function compute_nbr() {
    local constellation="$(get_constellation_name "$1")"

    case $constellation in
        spot|phr)
            echo "Normal Burn Rate cannot be calculated for $constellation."
            exit 20
            ;;
        sentinel-2)
            do_band_math "$(get_data_path "$1")" \
                         "(im1b8 - im1b12)/(im1b8 + im1b12)" "nbr"
            ;;
        *)
            echo "$SCRIPTNAME: Cannot compute NBR for constellation $constellation."
            exit 12
    esac
}

## Invokes the correct function to compute an index given an
## operation.
## $1: operation.
function dispatch_operation() {
    ## Perfornm the requested operation.
    case "$1" in
        "ndvi")
            compute_ndvi "$DATA_JSON" "OUTPUT_DIR"
            ;;
        "gndvi")
            compute_gndvi "$DATA_JSON" "OUTPUT_DIR"
            ;;
        "evi")
            compute_evi "$DATA_JSON" "OUTPUT_DIR"
            ;;
        "evi2")
            compute_evi2 "$DATA_JSON" "OUTPUT_DIR"
            ;;
        "evi22")
            compute_evi22 "$DATA_JSON" "OUTPUT_DIR"
            ;;
        "savi")
            compute_savi "$DATA_JSON" "OUTPUT_DIR"
            ;;
        "cvi")
            compute_cvi "$DATA_JSON" "OUTPUT_DIR"
            ;;
        "bai")
            compute_bai "$DATA_JSON" "OUTPUT_DIR"
            ;;
        "nbr")
            compute_nbr "$DATA_JSON" "OUTPUT_DIR"
            ;;
        *)
            echo "$SCRIPTNAME: Unknown operation requested."
            echo "Must be one of: ndvi, gndvi, evi, evi2, evi22, savi, cvi, bai or nbr."
            print_usage
            exit 13
    esac
}

## Computes all the indexes given in the block parameters.
## $1: block parameters (JSON).
function compute_indices() {
    local indexes="$(echo "$1" | $JQ -r '.indexes[]')"
    ## Get the RAM to be used by OTB.
    OTB_RAM=$(echo "$1" | $JQ -r '.ram')

    ## Create the output data.json file,
    create_data_json "$DATA_JSON"
    ## Loop on the given indexes.
    for i in $indexes; do
        dispatch_operation "$i"
    done
}

compute_indices "$PARAMS"
