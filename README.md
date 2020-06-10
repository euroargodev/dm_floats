
# dm_floats: prepare OWC input files and write D_files 


Two matlab tools are provided here:
* in **\/src\/ow_source** you will find routines for creating OWC software input file (i.e. .mat file in /float_source/) from the netcdf single-cycle core files.
* in **\/src\/create_dm_files** you will find routines for writing core Argo D-files using salinity calibration from OWC software

In **\/lib** you will find the library that are needed to run the codes:
    - The ITS-90 version of the CSIRO SEAWATER library: \/lib\/seawater_330_its90
	- the package libargo that contains routines to handle argo netcdf files : \/lib\/+libargo


## How to use?

We will need to add the following paths to your matlab path:

addpath('\/lib\/')

addpath('\/lib\/seawater_330_its90\/')


### Prepare OWC input file
 * Go to **\/src\/ow_source**
 * Edit the config.txt file to set your paths 
 * create_float_source(float_name)  eg. create_float_source('4900139')  will create the source file 4900139.mat for float 4900139
 * help create_float_source will give you more information on how to use this program.
 
 
### Write netcdf Argo D_files
 * Go to src\/../create_dm_files/
 * Edit the config.txt file to set your paths 
 * MAIN_write_dmqc_files(flt_name)  eg. MAIN_write_dmqc_files('4900139')  will create the netcdf Argo D-files for float 4900139 using salinity calibration from OWC software
 
Interactive dialog boxes are used to set:
   - default PSAL_ADJUSTED_QC  flags 
   - errors  PSAL_ADJUSTED_ERROR
   - comments  used to fill SCIENTIFIC_CALIBRATION_comment for PSAL
 User inputs are saved (paramlog) for each float and can be re-used later.

 See **readme_en.txt** for more details
