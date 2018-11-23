README MAIN_write_dmqc_files.m

**************
This program is used to write core Argo D-files with salinity calibration for offset or drift obtained with OW software:
In the input netcdf files, it is assumed that:
- TEMP_QC, PSAL_QC, PRES_QC have been eddited in DM (e.g flag spikes, density inversions not correctly detected in Real Time,...)
- if PRES DM adjsutments have been made previously, they are stored in PRES_ADJUSTED variables. In this case, this program will recalculate PSAL accordinly to PRES_ADJUSTED before applying OW correction.
- if CTM corrections have been made previously, they are stored in PSAL_ADJUSTED variables.In this case, this program will use PARAM_ADJUSTED variables to compute the final PSAL_ADJUSTED.

output netcdf  D files (single cycle files)  can be distributed on gdac.

**************
INSTITUTION ? : enter the institution that performs Delayed mode analysis

***************
CORRECTION ?

3 possibilities:
- no salinity correction is applied
- the salinity correction obtained from the OW method is applied (OW)
- a constant salinity correction obtained from CTD cast made at float launch is applied (LAUNCH_OFFSET)

Note that OW correction can be applied only for some cycles (i.e. from cycle xxx ... to cycle yyy). No correction is applied for the remaining cycles.

The OW calibration will be applied to the  salinity using the following equations:
PTMP = sw_ptmp(input_psal,input_temp,input_pres,0);
COND = sw_c3515*sw_cndr(input_psal,PTMP,0);
cal_COND = Calibration_ow_file.pcond_factor(index_cycle) .* COND;
cal_SAL = sw_salt( cal_COND/sw_c3515,PTMP,0);

by default:
input_temp is TEMP, 
input_pres is PRES or PRES_ADJUSTED if PRES was ADJUSTED before, 
input_psal is PSAL or PSAL recalculated to take into account effects of pressure adjustement


**************
SETTING PSAL_ADJUSTED_QC ?
It is assumed that TEMP_QC, PSAL_QC, PRES_QC have been eddited in DM (e.g flag spikes, density inversions not correctly detected in Real Time)

DEFAULT PSAL_ADJUSTED_QC=1, means that:
 PSAL_ADJUSTED_QC = 1 if PSAL_QC =1
 PSAL_ADJUSTED_QC = 1 if PSAL_QC =2
 PSAL_ADJUSTED_QC = 1 if PSAL_QC =3
 PSAL_ADJUSTED_QC = 4 if PSAL_QC =4  (the others QCs are unchanged)
                           
It is possible to change the default PSAL_ADJUSTED_QC
ex: if DEFAULT PSAL_ADJUSTED_QC=2 then: 

PSAL_ADJUSTED_QC = 2 if PSAL_QC =1
PSAL_ADJUSTED_QC = 2 if PSAL_QC =2
PSAL_ADJUSTED_QC = 2 if PSAL_QC =3
PSAL_ADJUSTED_QC = 4 if PSAL_QC =4  (the others QCs are unchanged)

Note: It is possible to choose which cycles will be affected by this change and to specify if this aplly to ascending or descending profiles only

if DEFAULT PSAL_ADJUSTED_QC>=2 then PSAL_ADJUSTED_ERROR is set to a minimum value of 0.016 PSU


**************
PSAL_ADJUSTED_ERROR

It is possible to choose  1) PSAL_ADJUSTED_ERROR = max(OW err, INST_UNCERTAINTY)
                         or 2) PSAL_ADJUSTED_ERROR = PI_UNCERTAINTY
               
if 1),  INST_UNCERTAINTY = 0.01 PSU by default.

Note: if, for a given cycle, PSAL_ADJUSTED QC is >=2 or if |PSAL_ADJUSTED -PSAL|>0.05 PSU then PSAL_ADJUSTED_ERROR = max(PSAL_ADJUSTED_ERROR,0.016) 

****************

How do you want to store calibration information, 'N_CALIB=1', 'N_CALIB=N_CALIB+1?

'N_CALIB is a dimension used in the SCIENTIFIC CALIBRATION variables',...
This corresponds to the maximum number of calibration performed on a profile:', ...
* if N_CALIB=1, all previous calibration comments will be erased. That means that the details of all steps in PSAL adjustement (press adjutement effect', ...
thermal lag, OW adjustement) have to be described in a single calibration comment',...
* if N_CALIB=N_CALIB+1 the OW step will result in an additional calibration comment'

****************
CTM ???

Has salinity previously adjusted for thermal mass effect?
if YES: the program will apply OW calibration on PSAL_ADJUSTED: input_temp is TEMP_ADJUSTED,input_pres is PRES_ADJUSTED,input_psal is PSAL_ADJUSTED
if NO: input_temp is TEMP, input_pres is PRES or PRES_ADJUSTED if PRES was ADJUSTED before, 
input_psal is PSAL or PSAL recalculated to take into account effects of pressure adjustement

**************
INFORMATIONS ON OW METHOD USED TO CALIBRATE PSAL:

these informations will be used to write SCIENTIFIC_CALIB_COMMENT for PSAL


**************
PRES_ADJUSTED

This program does not adjust PRES in delayed mode, however:

If PRES_ADJUSTED exists (not fillvalue) :
----------------------------------------
- it will not be overwritten;
- salinity is computed according to PRES_ADJUSTED.
- if no other salinity adjustemet is necessary then PSAL_ADJUSTED = PSAL (re-calculated  using PRES_ADJUSTED).


- if PRES_ADJUSTED is in 'D mode', PRES_ADJUSTED_ERROR is already filled as well as scientific_calib_equation, coefficient and comment; they will not be overwritten
- if PRES_ADJUSTED is in 'A mode', PRES_ADJUSTED_ERROR is empty. 
     - if PRES = PRES_ADJUSTED, then the SCIENTIFIC_CALIB_COMMENT will be "No significant pressure drift detected"
      PRES_ADJUSTED_ERROR will be filled with the instrument accuracy.
      
     - otherwise if   PRES~=PRES_ADJUSTED 
      The following warming will be display:                            
     'Pressure is adjsuted in Real Time: you should first process the delayed time adjustment of the pressure before calibrating salinity'
     
     However, the program will still proceed:
     the SCIENTIFIC_CALIB_COMMENT will be: "Pressure adjusted for offset by using surface pressure, following the real-mode pressure adjustment procedure described in the Argo quality control manual version 2.9." 

If PRES_ADJUSTED is fillvalue (mode 'R'), this prog will fill PRES_ADJUSTED = PRES, PRES_ADJUSTED_ERROR is instrument accuracy. 
---------------------------------------

Note: if PRES_ADJUSTED_QC =4 then TEMP_ADJUSTED_QC=4 and PSAL_ADJUSTED_QC=4


***************
This program do not adjust TEMP in delayed mode
TEMP_ADJUSTED=TEMP
TEMP_ADJUSTED_QC=TEMP_QC
TEMP_ADJUSTED_ERROR is the instrument accuracy








               





