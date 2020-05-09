## Short Description

In this project, I aim to compare data on defectors from the ruling party in Burkina Faso in January 2014 against some covariates about their home provinces. Existing theories suggest
that these 75 defectors left the party because they suddenly become born-again democrats. I am skeptical, however, and thus think there may be regional/ethnolinguistic dynamics at
play that specifically explain this set of 75 ruling party officials decided to defect together. I create a new dataset (provdata) that include this defector data as well as data on
the main ethnicity/language of the defectors' home provinces, info on urban/rural dynamics, and some province-level survey data I gleaned from Afrobarometer on public attitudes toward
democracy and the ruing party. In the end, I find no statistically-significant correlations but made some interesting maps and graphs!

## Dependencies

1. R Studio
2. QGIS Bucuresti

## Files

1. 01_analysis.pdf: knitted version of RMD file.
2. Final presentation.ppt: Lightning talk slides
3. Graphs and Maps (x12)

#### Code/
1. 01_analysis.R: R script for the project
2. 01_analysisRMD.RMD: R Markdown version
01_collect-nyt.R: Collects data from New York Times API and exports data to the file nyt.csv

#### Data/

1. bfo_r4_data.sav: 2008 Afrobarometer survey
2. defector_data.csv: data on the 75 defectors
3. Province data.csv: main dataset used for analysis.

