# Simple custom block to calculate vegetation indexes

## Introduction

The code in this repository implements a very simple block that
computes various vegetation indexes for
[Pléiades](https://docs.up42.com/getting-started/data-products/pleiades),
[SPOT 6/7](https://docs.up42.com/getting-started/data-products/spot/)
and [Sentinel-2](https://sentinel.esa.int/web/sentinel/missions/sentinel-2 "Sentinel-2").

 * [NDVI](https://en.wikipedia.org/wiki/Normalized_difference_vegetation_index) - Normalized Difference Vegetation Index
 * [EVI](https://en.wikipedia.org/wiki/Enhanced_vegetation_index) -
   Enhanced Vegetation Index
 * [EVI2](https://www.indexdatabase.de/db/si-single.php?sensor_id=96&rsindex_id=237) -
 Enhanced Vegetation Index 2
 * [EVI2-2](https://www.indexdatabase.de/db/i-single.php?id=576) -
   Enhanced Vegetation Index 2 - 2
 * [SAVI](https://en.wikipedia.org/wiki/Soil-adjusted_vegetation_index) - Soil-Adjusted Vegetation Index
 * [BAI](https://www.space4water.org/taxonomy/term/1255) - Burn Area Index
 * [NBR](https://un-spider.org/advisory-support/recommended-practices/recommended-practice-burn-severity/in-detail/normalized-burn-ratio) -
   Normalized Burn Ratio

The calculation is done using the [OrfeoToolbox
   BandMath](https://www.orfeo-toolbox.org/CookBook/Applications/app_BandMath.html?highlight=bandmath)
   utility.

Writen in C++, the
[OrfeoToolbox](https://www.orfeo-toolbox.org/) (OTB) is maintained
by the French Space Agency &mdash; Centre National d'Études Spatiales
(CNES). It consists of a serious of command line utilities to work
with remote sensing data sets.

It has also a [Python API](https://www.orfeo-toolbox.org/CookBook/PythonAPI.html) and
a [QGIS](https://www.orfeo-toolbox.org/CookBook/QGISInterface.html)
interface.

Performance wise OTB offers [Streaming and
Threading](https://www.orfeo-toolbox.org/CookBook/C++/StreamingAndThreading.html)
for handling large datasets effectively.
