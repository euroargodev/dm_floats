% ========================================================
%   USAGE :  MAIN_write_dmqc_files(flt_name)
%
%   PURPOSE : This program is used to write core Argo D-files with salinity calibration for offset or drift obtained with OW software
%   
%    This program allows to choose between 3 corrections:
%   - no salinity correction is applied (NO)
%   - salinity correction obtained from the OW method is applied (OW) : it is possible to apply the OW correction only on a part of the time series and no correction before or/and after. 
%   - a constant salinity offset obtained from CTD cast made at LAUNCH is applied (LAUNCH_OFFSET)
%   
%   Interactive dialog boxes are used to set: 
%   - default PSAL_ADJUSTED_QC for each cycle
%   - errors  PSAL_ADJUSTED_ERROR
%   - comments  used to fill SCIENTIFIC_CALIBRATION_comment for PSAL
%   User inputs are saved (paramlog) for each float and can be reused later.
%
%   see readme_en.txt for more details
%
% -----------------------------------
%   INPUT :
%     flt_name  (char)  -- wmo float name  e.g.: '4900139'
%
% -----------------------------------
%   OUTPUT :
%   netcdf core D files (single cycle files) that can be distributed on gdac.
% -----------------------------------
%   HISTORY
%  ??/???? : C.Coatanoan: - creation (fichier_nc_dmqc_ovide.m)
%  from 12/2014 : C.Cabanes : -interactive input, use of +libargo, format 3.1
% 
%  tested with matlab  8.3.0.532 (R2014a)
%
%  EXTERNAL LIB
%  package +libargo : addpath('dm_float/lib/')
%  seawater  : addpath('dm_float/lib/seawater_330_its90/')
%
%  CONFIGURATION file: config.txt;
%==================================================
function MAIN_write_dmqc_files(flt_name)


disp('%%%%%%%')
disp('Delayed-Mode NetCDF files')
% if run in create_dm_files directory
addpath('../../lib/')  
addpath('../../lib/seawater_330_its90/')

% INPUT/OUTPUT files
C=load_configuration('config.txt');
DIR_FTP= C.DIR_FTP;    % input files directory
DIR_OW = C.DIR_OW;     % calibration files directory(cal_$flt_name$.mat files)
DIR_OUT = C.DIR_OUT;   % output files with DMQC corrections are put in this directory

%%%%%%%%%%%%%%%%%
if ischar(flt_name)==0
flotteur = num2str(flt_name);
else
flotteur = strtrim(flt_name);
end

DIR_CAL=[DIR_OW 'float_calib/'  ];

C_FILE = load([DIR_CAL num2str(flotteur) '/cal_' num2str(flotteur) '.mat']);

root_in=[DIR_FTP num2str(flotteur) '/profiles/']

root_out=[DIR_OUT num2str(flotteur) '/profiles/'];

[status,msg]=mkdir(root_out);

%  Select netcdf files (single-cycle files): only core files

rep=dir([root_in '*.nc']);
filenames={rep.name};
ischarcellB = strfind(filenames,'B');
ischarcellM = strfind(filenames,'M');

if ~isempty(ischarcellB)|~isempty(ischarcellM) % enleve B et M files
    core_files = filenames(cellfun(@isempty,ischarcellB)&cellfun(@isempty,ischarcellM));
end


% reorder rep.name (descending profiles before ascending profiles for each cycle)

d=core_files;
d=strrep(d,'.nc','Z.nc');
d=sort(d); % in alphabetical order "10DZ.nc' is before "10Z.nc"
d=strrep(d,'Z.nc','.nc');
therep=d;


% Cycle Number: first and last
NcVar.cycle_number.name='CYCLE_NUMBER';
NcVar.station_parameters.name='STATION_PARAMETERS';
NcVar.vertical_sampling_scheme.name='VERTICAL_SAMPLING_SCHEME';
NcVar.format_version.name='FORMAT_VERSION';

[FLe] = libargo.read_netcdf_allthefile([root_in,therep{end}],NcVar);
[FLd] = libargo.read_netcdf_allthefile([root_in,therep{1}],NcVar);

format_version = str2num(FLd.format_version.data');
if format_version>=3
   is_primary = libargo.findstr_tab(FLd.vertical_sampling_scheme.data,'Primary sampling');
   n_prof = find(is_primary);
        if isempty(n_prof)
            warning([file_in ' :Primary profile not found'])
        end
else
   n_prof=1;
end
first_cycle = FLd.cycle_number.data(n_prof);

format_version=str2num(FLe.format_version.data');
if format_version>=3
   is_primary=libargo.findstr_tab(FLe.vertical_sampling_scheme.data,'Primary sampling');
   n_prof = find(is_primary);
        if isempty(n_prof)
            warning([file_in ' :Primary profile not found'])
        end
else
   n_prof=1;
end
last_cycle = FLe.cycle_number.data(n_prof);

%keyboard
%  if exist('./paramlog','dir')==0
%      mkdir('.' ,'paramlog')
%  end

if exist(['./paramlog/' flotteur],'dir')==0
    mkdir(['./paramlog/' flotteur])
end

log_file = ['./paramlog/' flotteur '/log_dmqc_' flotteur '.txt'];
fic=fopen(log_file,'w');

fprintf (fic,'%s \n', ['Max cycle found: ' num2str(last_cycle) '. Delayed mode performed up to cycle ' num2str(max(C_FILE.PROFILE_NO))]);

% load interactively the parameters for this float

if exist(['./paramlog/load_param_dmqc_' flotteur '.mat'],'file')
    
    isw = menu('load_param_dmqc', 'USE EXISTING PARAM', 'ENTER NEW PARAM');
    
    if isw==1
        load (['./paramlog/load_param_dmqc_' flotteur '.mat'])
    else
        s=load_param_dmqc_interac(flotteur,C_FILE,FLd,C);
    end
else
    s=load_param_dmqc_interac(flotteur,C_FILE,FLd,C);
end

%keyboard

ifirst=NaN;
iswc_pres=2;

thedate=datestr(now,'yyyymmddHHMMSS');
%keyboard
%--------------------------------------------------------------------
i=0; % CHECK indices
for ifile=1:length(therep)  % WORK ON EACH FILE 
    
    ifirst=min(ifirst,ifile);
    % open R_file (or D_file) and check cycle number
    file_in=therep{ifile};
    
    % read the netcddf file    
    [FL,DIM,Globatt] = libargo.read_netcdf_allthefile([root_in,file_in]);
    
    format_version=str2num(FL.format_version.data');
    
    if format_version>=3
        is_primary = libargo.findstr_tab(FL.vertical_sampling_scheme.data,'Primary sampling');
        n_prof = find(is_primary);
        if isempty(n_prof)
            warning([file_in ' :Primary profile not found'])
        end
    else
        n_prof=1;
    end
    
    if isempty(n_prof)==0
        cycle = FL.cycle_number.data(n_prof);
        direction = FL.direction.data(n_prof);
        % find default PSAL_ADJUSTED_QC for the current cycle
        trouv_mod=[];
        %keyboard
        for kkl=1:length(s.MOD_PSAL_ADJ_QC)
        if sum(cycle==s.MOD_PSAL_ADJ_QC_CYCLE{kkl})>0
           if direction==s.MOD_PSAL_ADJ_QC_DIRECTION{kkl}
            CYC_PSAL_ADJ_QC = s.MOD_PSAL_ADJ_QC{kkl};
            trouv_mod=kkl;
           end
        end
        end
        if isempty(trouv_mod)==0
           CYC_PSAL_ADJ_QC = s.MOD_PSAL_ADJ_QC{trouv_mod};
        else
            CYC_PSAL_ADJ_QC = s.DEF_PSAL_ADJ_QC;
        end
        
        
        % find the correction for the current cycle
        ind_correction = find(cycle > [-1 s.APPLY_upto_CY]& cycle<= [s.APPLY_upto_CY max(C_FILE.PROFILE_NO)]);
        
        if isempty(ind_correction)==0
            
            thecorrection = upper(strtrim(s.CORRECTION{ind_correction}));
            
            if strcmp(thecorrection,'LAUNCH_OFFSET') & isempty(s.LAUNCH_OFFSET)
                error('You should fill the LAUNCH_OFFSET value')
            end
            
            if ismember(thecorrection,{'NO','LAUNCH_OFFSET' , 'OW' })==0
                error([ 'CORRECTION ' s.CORRECTION{ind_correction} ' is not known'])
            end
            
            if strcmp(thecorrection,'LAUNCH_OFFSET')
                text_disp = ['Float ' num2str(flotteur) '- cycle ' num2str(cycle) direction '- CORRECTION: ' s.CORRECTION{ind_correction} ' :' num2str(s.LAUNCH_OFFSET) ' PSU'];
            else
                text_disp = ['Float ' num2str(flotteur) '- cycle ' num2str(cycle) direction '- CORRECTION: ' s.CORRECTION{ind_correction}];
            end
            fprintf (fic,'%s \n', '------------------------------------');
            fprintf (fic,'%s \n', text_disp);
            
            % Deal with descending profiles
            ind_cycle=[];
            if strcmp(thecorrection,'OW')
                if direction == 'D'& (cycle ~= first_cycle)
                    % OW correction for cycle n-1 A
                    ind_cycle = find(C_FILE.PROFILE_NO==cycle-1);
                    if ~isempty(ind_cycle)
                        fprintf (fic,'%s \n', ['Descending profile, we use the correction applied to cycle ' num2str(cycle-1) 'A'] );
                    else isempty(ind_cycle)
                        %OW correction for cycle n A
                        ind_cycle = find(C_FILE.PROFILE_NO==cycle);
                        fprintf (fic,'%s \n', ['WARNING: Descending profile, we use the correction applied to cycle ' num2str(cycle) 'A (no correction found for cycle n-1 A)'] );
                        CYC_PSAL_ADJ_QC='2';
                    end
                elseif direction == 'D' & cycle== first_cycle
                    % OW correction for cycle OA
                    ind_cycle = find(C_FILE.PROFILE_NO==cycle);
                    fprintf (fic,'%s \n', ['Descending profile, we use the correction applied to cycle ' num2str(cycle) 'A'] );
                elseif direction =='A'
                    ind_cycle = find(C_FILE.PROFILE_NO==cycle);
                end
            else
                ind_cycle = find(C_FILE.PROFILE_NO==cycle);
            end
            
            
            % if a cycle is missing in  C_FILE.PROFILE_NO, ind_cycle can be empty
            if (isempty (ind_cycle) & cycle < max(C_FILE.PROFILE_NO))||cycle > max(C_FILE.PROFILE_NO)
                warning(['The cycle ' num2str(cycle) ' has not gone through OW. Nothing is done for this file'])
                fprintf (fic,'%s \n', ['WARNING : The cycle ' num2str(cycle) ' has not gone through OW. Nothing is done for this file']);
            else
			i=i+1;
                % Format checker: if data_mode='D' or 1 2C : the file should be a 'D file'
                file_out=['D' file_in(2:length(file_in))];
                disp([text_disp ' - Dfile']);
               
                %clear day_cyc  today

                %***************************PREPARE OUTPUT  ********************************
                FLD = FL;
                DIMD = DIM;
                GlobattD = Globatt;
                
                FLD.data_state_indicator.data(n_prof,:) = '2C  ';
                
                FLD.data_mode.data(n_prof) = 'D';
                
                
                %****************************PARAMETERS*************************************
                %  CORE files : only PRES TEMP PSAL and CDND fields.
                
                %================PRESSURE------PRES field--------------
                
                %keyboard
                if isfield(FLD,'pres')&& isfield(FLD,'psal')&&  isfield(FLD,'temp')
                    
                    if ~isfield(FLD,'pres_adjusted') % fill PRES_ADJUSTED
                        FLD.pres_adjusted = FLD.pres; FLD.pres_adjusted.name='PRES_ADJUSTED';
                        % les valeurs pour les secondary profiles sont remplies
                        % par des fillvalues
                        FLD.pres_adjusted.data(~is_primary,:)= repmat(FLD.pres_adjusted.FillValue_,sum(~is_primary),size(FLD.pres_adjusted.data,2));
                        FLD.pres_adjusted_qc = FLD.pres_qc; FLD.pres_adjusted_qc.name='PRES_ADJUSTED_QC';
                        FLD.pres_adjusted_qc.data(~is_primary,:)= repmat(FLD.pres_adjusted_qc.FillValue_,sum(~is_primary),size(FLD.pres_adjusted.data,2));
                        FLD.pres_adjusted_error = FLD.pres; FLD.pres_adjusted_error.name='PRES_ADJUSTED_ERROR';
                        FLD.pres_adjusted_error.data = repmat(FLD.pres_adjusted_error.FillValue_,size(FLD.pres_adjusted_error.data,1),size(FLD.pres_adjusted_error.data,2));
                        FLD.pres_adjusted_error = rmfield(FLD.pres_adjusted_error,{'valid_min','valid_max'});
                    end

                    %***************************INPUT : PRES or PRES_ADJUSTED? ******************
                    % find if PRES has already been adjusted (eg  APEX float)
                    % In this case OW inputs are: PRES_ADJUSTED, PSAL(calibrated in PRESSURE), TEMP
                    
                    select = FLD.pres.data(n_prof,:)~=FLD.pres.FillValue_ & FLD.pres_adjusted.data(n_prof,:)~=FLD.pres_adjusted.FillValue_;
                    diff_pres = zeros(size(FLD.pres.data(n_prof,:)));
                    diff_pres(select) = FLD.pres_adjusted.data(n_prof,select)-FLD.pres.data(n_prof,select);
                    diff = diff_pres;
                    
                    isfillval_err = FLD.pres_adjusted_error.data(n_prof,:)==FLD.pres_adjusted_error.FillValue_;
                    isfillval_pres = FLD.pres_adjusted.data(n_prof,:)==FLD.pres_adjusted.FillValue_;
                    
                    INPUT_PRESAD = 0;
                    %keyboard
                    
                    if mean(libargo.meanoutnan(diff))==0 % mode R or no adjustement FL.pres.data=FL.pres_adjusted.data
                        
                        if sum(isfillval_pres)==length(isfillval_pres)  % mode R
                            INPUT_PRESAD=0;
                            input_pres = FL.pres.data(n_prof,:);
                        else
                            if sum(isfillval_err)==length(isfillval_err)  % mode A with  FL.pres.data=FL.pres_adjusted.data
                                INPUT_PRESAD=0;
                                input_pres = FL.pres_adjusted.data(n_prof,:);
                            else % mode D with FL.pres.data=FL.pres_adjusted.data
                                INPUT_PRESAD=10;
                                input_pres = FL.pres_adjusted.data(n_prof,:);
                            end
                        end
                    else   % mode A or D with FL.pres.data~=FL.pres_adjusted.data
                        if  sum(isfillval_err)==length(isfillval_err)  % mode A: pressure adjusted in real time only: it is processed, but with a warning
                            INPUT_PRESAD=2;
                            input_pres = FL.pres_adjusted.data(n_prof,:);
                            f=warndlg('Pressure is adjsuted in Real Time: you should first process the delayed time adjustment of the pressure before calibrating salinity','PRES_ADJUSTED');
                            uiwait(f)
                            if isfield(s,'force')==0
                            disp([' Cycle' num2str(cycle) ': Input pressures are PRES_ADJUSTED, because an adjustement had been made on pressure'])
                            fprintf (fic,'%s \n', ['       : Input pressures are PRES_ADJUSTED, because an adjustement had been made on pressure']);
                            end
                        else % mode D
                            INPUT_PRESAD=1;
                            input_pres = FL.pres_adjusted.data(n_prof,:);
                            if isfield(s,'force')==0
                            disp([' Cycle' num2str(cycle) ': Input pressures are PRES_ADJUSTED, because an adjustement had been made on pressure'])
                            fprintf (fic,'%s \n', ['       : Input pressures are PRES_ADJUSTED, because an adjustement had been made on pressure']);
                            end
                        end
                    end

                    if isfield(s,'force')==1&&strcmp(s.force,'adjusted')
                        input_pres = FL.pres_adjusted.data(n_prof,:);
                    end
                    
                    if INPUT_PRESAD==0|INPUT_PRESAD==2; % fill PRES_ADJUSTED fields
                                                        % otherwise the previous PRES_ADJUSTED/ PRES_ADJUSTED_QC/ PRES_ADJUSTED_ERROR are kept
                        FLD.pres_adjusted.data(n_prof,:) = FLD.pres.data(n_prof,:);
                        FLD.pres_adjusted_qc.data(n_prof,:) = FLD.pres_qc.data(n_prof,:);
                        
                        inst_type = strtrim(FLD.wmo_inst_type.data(n_prof,:));
                        %if ismember(inst_type,{'841','843','844','846','851','853','856','860','831','838'}) % SBE
                        the_error = 2.4;
                        %elseif ismember (inst_type,{'842','847','852','857','861'}) % FSI
                        if ismember (inst_type,{'842','847','852','857','861'}) % FSI
                            the_error = 5;
                       % else
                            %disp('Unknown WMO_INST_TYPE')
                            %the_error =  5 ;
                        end
                        
                        FLD=libargo.replace_nan_byfill(FLD); % ajout le 12/04/2016
                        not_fillval_pres = (FLD.pres_adjusted.data(n_prof,:)~=FLD.pres_adjusted.FillValue_);
                        FLD.pres_adjusted_error.data(n_prof,not_fillval_pres) = the_error;
                        FLD.pres_adjusted_error.data(n_prof,~not_fillval_pres) = FLD.pres_adjusted_error.FillValue_;
                    end
                    
                    
                    % find PRES_QC=0 and replace with QC 1
                    
                    if isempty (strfind(FLD.pres_adjusted_qc.data(n_prof,:),'0' ))==0   
                        disp('  PRES_QC=0 found !')
                        fprintf (fic,'%s \n', ['       : PRES_QC=0 found !']);
                        FLD.pres_adjusted_qc.data(n_prof,:) = strrep(FLD.pres_adjusted_qc.data(n_prof,:),'0','1');
                    end
                    
                     % find QC  4 and 9
                    index_QC4_PRES = strfind(FLD.pres_adjusted_qc.data(n_prof,:),'4');
                    index_QC9_PRES = strfind(FLD.pres_adjusted_qc.data(n_prof,:),'9'); %  modif 18/06/2018
                    
                    if isempty(index_QC4_PRES)==0
                        disp('QC4 for PRES_ADJUSTED are found')
                        fprintf (fic,'%s \n', ['       : QC4 for PRES_ADJUSTED are found']);
                    end
                     if isempty(index_QC9_PRES)==0
                        disp('QC9 for PRES_ADJUSTED are found')
                        fprintf (fic,'%s \n', ['       : QC9 for PRES_ADJUSTED are found']); % modif 18/06/2018
                    end
                    
                    
                    FLD.pres_adjusted.data(n_prof,index_QC4_PRES) = FLD.pres_adjusted.FillValue_ ;
                    FLD.pres_adjusted_error.data(n_prof,index_QC4_PRES) = FLD.pres_adjusted_error.FillValue_ ;
                    
                    
                    %================TEMPERATURE------TEMP field--------------
                    %keyboard
                    if ~isfield(FLD,'temp_adjusted') % fill TEMP_ADJUSTED
                        FLD.temp_adjusted = FLD.temp; FLD.temp_adjusted.name='TEMP_ADJUSTED';
                        % les valeurs pour les secondary profiles sont remplies
                        % par des fillvalues
                        FLD.temp_adjusted.data(~is_primary,:)= repmat(FLD.temp_adjusted.FillValue_,sum(~is_primary),size(FLD.temp_adjusted.data,2));
                        FLD.temp_adjusted_qc = FLD.temp_qc; FLD.temp_adjusted_qc.name='TEMP_ADJUSTED_QC';
                        FLD.temp_adjusted_qc.data(~is_primary,:)= repmat(FLD.temp_adjusted_qc.FillValue_,sum(~is_primary),size(FLD.temp_adjusted_qc.data,2));
                        FLD.temp_adjusted_error = FLD.temp; FLD.temp_adjusted_error.name='TEMP_ADJUSTED_ERROR';
                        FLD.temp_adjusted_error.data = repmat(FLD.temp_adjusted_error.FillValue_,size(FLD.temp_adjusted_error.data,1),size(FLD.temp_adjusted_error.data,2));
                        FLD.temp_adjusted_error =rmfield(FLD.temp_adjusted_error,{'valid_min','valid_max'});
                    end
                    
                    FLD.temp_adjusted.data(n_prof,:) = FLD.temp.data(n_prof,:);
                    FLD.temp_adjusted_qc.data(n_prof,:) = FLD.temp_qc.data(n_prof,:);
                    
                    inst_type = strtrim(FLD.wmo_inst_type.data(n_prof,:));
                    %if ismember (inst_type,{'841','843','844','846','851','853','856','860','831','838'}) % SBE
                        the_error =0.002;
                    %elseif ismember (inst_type,{'842','847','852','857','861'}) % FSI
                    if ismember (inst_type,{'842','847','852','857','861'}) % FSI
                        the_error = 0.01;
                    %else
                        %disp('Unknown WMO_INST_TYPE')
                        %the_error =  0.01 ;
                    end
                    FLD.temp_adjusted_error.data(n_prof,:) = the_error;
                    
                    FLD=libargo.replace_nan_byfill(FLD); % ajout le 12/04/2016
                    not_fillval_temp = (FLD.temp_adjusted.data(n_prof,:)~=FLD.temp_adjusted.FillValue_);
                    FLD.temp_adjusted_error.data(n_prof,not_fillval_temp) = the_error;
                    FLD.temp_adjusted_error.data(n_prof,~not_fillval_temp) = FLD.temp_adjusted_error.FillValue_;
                    
                    % if flag '4' in PRES_ADJUSTED_QC then flag '4' in TEMP_ADJUSTED_QC
                    FLD.temp_adjusted_qc.data(n_prof,index_QC4_PRES) = '4';
                    
                    % Check for TEMP_ADJUSTED_QC='4'-> TEMP_ADJUSTED and TEMP_ADJUSTED_ERROR are fill_value
                    
                    
                    index_QC4 = strfind(FLD.temp_adjusted_qc.data(n_prof,:),'4');
                    
                    FLD.temp_adjusted.data(n_prof,index_QC4) = FLD.temp_adjusted.FillValue_ ;
                    FLD.temp_adjusted_error.data(n_prof,index_QC4) = FLD.temp_adjusted_error.FillValue_ ;
                    
                    input_temp = FL.temp.data(n_prof,:);

                    if isfield(s,'force')==1&&strcmp(s.force,'adjusted')
                        input_temp = FL.temp_adjusted.data(n_prof,:);
                    end
                    
                    %keyboard
                    
                    %================PSALINITY------PSAL field--------------
                    
                    if ~isfield(FLD,'psal_adjusted') % fill PSAL_ADJUSTED
                        FLD.psal_adjusted = FLD.psal; FLD.psal_adjusted.name='PSAL_ADJUSTED';
                        % les valeurs pour les secondary profiles sont remplies
                        % par des fillvalues
                        FLD.psal_adjusted.data(~is_primary,:)= repmat(FLD.psal_adjusted.FillValue_,sum(~is_primary),size(FLD.psal_adjusted.data,2));
                        FLD.psal_adjusted_qc = FLD.psal_qc; FLD.psal_adjusted_qc.name='PSAL_ADJUSTED_QC';
                        FLD.psal_adjusted_qc.data(~is_primary,:)= repmat(FLD.psal_adjusted_qc.FillValue_,sum(~is_primary),size(FLD.psal_adjusted_qc.data,2));
                        FLD.psal_adjusted_error = FLD.psal; FLD.psal_adjusted_error.name='PSAL_ADJUSTED_ERROR';
                        FLD.psal_adjusted_error.data = repmat(FLD.psal_adjusted_error.FillValue_,size(FLD.psal_adjusted_error.data,1),size(FLD.psal_adjusted_error.data,2));
                        FLD.psal_adjusted_error =rmfield(FLD.psal_adjusted_error,{'valid_min','valid_max'});
                    end
                    
                    
                    FL=libargo.replace_fill_bynan(FL);
                    
                    % compute correction and error from OW
                    
                    if INPUT_PRESAD==0|INPUT_PRESAD==10;      % modif 18/06/2018
                        input_psal = FL.psal.data(n_prof,:);
                    else
                        cndr = sw_cndr(FL.psal.data(n_prof,:),FL.temp.data(n_prof,:),FL.pres.data(n_prof,:));
                        
                        input_pres = FL.pres_adjusted.data(n_prof,:);
                        input_psal = sw_salt(cndr,FL.temp.data(n_prof,:),FL.pres_adjusted.data(n_prof,:));
                    end
                    
      
                    if isfield(s,'force')==1&&strcmp(s.force,'adjusted')
                        input_psal = FL.psal_adjusted.data(n_prof,:);
                        testi = libargo.check_isfillval_prof(FL,'psal_adjusted')
                        if numel(input_psal)==sum(isnan(input_psal))
                           error('You replied that the CTM correction was applied,  but the PSAL_ADJUSTED variable is empty!!!')
                        end
                    end
                    
                    PTMP = sw_ptmp(input_psal,input_temp,input_pres,0);
                    COND = sw_c3515*sw_cndr(input_psal,PTMP,0);
                    cal_COND = C_FILE.pcond_factor(ind_cycle) .* COND;
                    cal_SAL = sw_salt( cal_COND/sw_c3515,PTMP,0);
                    
                    cal_COND_err =  C_FILE.pcond_factor_err(ind_cycle).*COND;
                    cal_SAL1 = sw_salt( (cal_COND+cal_COND_err)/sw_c3515, PTMP,0);
                    cal_SAL_err = 2*abs( cal_SAL-cal_SAL1);
                    
                    %keyboard
                    
                    FL=libargo.replace_nan_byfill(FL);
                    
                    % compute error
                    % -------------------
                    
                    switch   s.PSAL_ERROR
                        
                        case {'MAX_OW_INST'};
                            the_error = max(cal_SAL_err,s.SAL_INST_UNCERTAINTY);
                            s.ERROR_PSAL_comment.here = s.ERROR_PSAL_comment.MAX_OW_INST;
                            ERROR_CNDC_comment = ['Error = maximum [statistical uncertainty, instrument accuracy]. '];
                        case {'FROM_PI'}
                            
                            the_error = repmat(s.SAL_PI_UNCERTAINTY,1,size(FL.psal.data,2));
                            s.ERROR_PSAL_comment.here = s.ERROR_PSAL_comment.FROM_PI;
                            ERROR_CNDC_comment = ['Error provided by the PI.'];
                    end
                    
                    
                    % apply the correction
                    %--------------------------------
                    switch   thecorrection
                        case {'NO'}; % considered as good and do not need adjustement in DM
                            
                            psal_adjusted = input_psal;
                            
                            psal_adjusted_error = the_error;
                            
                            psal_adjusted_qc = FL.psal_qc.data(n_prof,:);
                            if isfield(s,'force')==1&&strcmp(s.force,'adjusted')
                               psal_adjusted_qc = FL.psal_adjusted_qc.data(n_prof,:);
                            end
                            
                        case {'LAUNCH_OFFSET'} % launch offset
                            
                            psal_adjusted = input_psal + s.LAUNCH_OFFSET ;
                            
                            psal_adjusted_error = the_error;
                            
                            psal_adjusted_qc = FL.psal_qc.data(n_prof,:);
                            if isfield(s,'force')==1&&strcmp(s.force,'adjusted')
                               psal_adjusted_qc = FL.psal_adjusted_qc.data(n_prof,:);
                            end
                            
                            
                        case {'OW'} % ow correction
                            
                            psal_adjusted = cal_SAL ;
                            
                            psal_adjusted_error = the_error;
                            
                            psal_adjusted_qc = FL.psal_qc.data(n_prof,:);
                            
                            if isfield(s,'force')==1&&strcmp(s.force,'adjusted')
                               psal_adjusted_qc = FL.psal_adjusted_qc.data(n_prof,:);
                            end
                            
                            % if flag '9' in PRES_ADJUSTED_QC then flag '4' in PSAL_ADJUSTED_QC
                            psal_adjusted_qc(index_QC9_PRES) = '4';                      % % modif 18/06/2018
                            
                    end
                    %keyboard
                    
                   % set PSAL_ADJUSTED_QC
                   %--------------
                   % keyboard                   
                   
                    % if flag '4' in PRES_ADJUSTED_QC then flag '4' in PSAL_ADJUSTED_QC
                    psal_adjusted_qc(index_QC4_PRES) = '4';
                    
                    
                    % if PSAL_QC==2, PSAL_QC_ADJUSTED==1
                    psal_adjusted_qc = strrep(psal_adjusted_qc,'2','1');
                    
                    % if PSAL_QC==3, PSAL_QC_ADJUSTED==1 (except for deep arvor qc==3 -> qc=2 for depth >2000m)
                    %keyboard
                    if ismember(inst_type,{'838'}) % deep ARVOR
                    psal_adjusted_qc(FL.pres.data(n_prof,:)>2000&psal_adjusted_qc=='3')='2'; % for deep arvor(ajout du 27/10/2016 pour les DEEP)
                    end
                    psal_adjusted_qc = strrep(psal_adjusted_qc,'3','1');
                    
                    
                    % replace PSAL_QC==1 with  CYC_PSAL_ADJ_QC (user input)
                    psal_adjusted_qc = strrep(psal_adjusted_qc,'1',CYC_PSAL_ADJ_QC);
                    % for deep Arvor
                    if ismember(inst_type,{'838'})&isempty(strfind(CYC_PSAL_ADJ_QC,'1'))
                    psal_adjusted_qc = strrep(psal_adjusted_qc,'2',CYC_PSAL_ADJ_QC);
                    end
                    
                    %find PSAL_QC==4 and set PSAL_ADJSUTED and PSAL_ADJUSTED_ERROR to FillValue)
                    is_qc4 = strfind( psal_adjusted_qc, '4');
                    
                    psal_adjusted (is_qc4) = FLD.psal_adjusted.FillValue_;
                    psal_adjusted_error (is_qc4) = FLD.psal_adjusted_error.FillValue_;
                    

                    % Check if adjustement > 0.05PSU
                    is_sup_005 = find((abs(psal_adjusted-FL.psal.data(n_prof,:))>0.05) & psal_adjusted~=FLD.psal_adjusted.FillValue_);
                    
                    if  ~isempty (is_sup_005) % confidence in adjustement is low
                        disp('Confidence in the PSAL adjustement is low (> 0.05 PSU),QC is 2 and error is 0.016PSU)')
                        fprintf (fic,'%s \n', ['       :Confidence in the PSAL adjustement is low (> 0.05 PSU),QC is 2 and error is 0.016PSU)']);
                        
                        psal_adjusted_qc = strrep(psal_adjusted_qc,'1','2');
                        psal_adjusted_error = max(0.016,psal_adjusted_error);
                        switch   s.PSAL_ERROR
                            case {'MAX_OW_INST'};
                                if s.SAL_INST_UNCERTAINTY<0.016
                                    s.ERROR_PSAL_comment.here = strrep(s.ERROR_PSAL_comment.here,num2str(s.SAL_INST_UNCERTAINTY),'0.016');
                                end
                            case {'FROM_PI'}
                                s.ERROR_PSAL_comment.here = ['Error = max[error provided by the PI,0.016]'];
                        end
                        
                    else % adjsutment is <=0.05
                        
                        if str2num(CYC_PSAL_ADJ_QC)==2 % BUT  the PI has decided to set PSAL_ADJUSED_QC==2 
                            disp('Confidence in the PSAL adjustement is low,QC is 2 and error is 0.016PSU)')
                            fprintf (fic,'%s \n', ['       :Confidence in the PSAL adjustement is low, QC is 2 and error is 0.016PSU)']);
                            psal_adjusted_qc = strrep(psal_adjusted_qc,'1','2');
                            psal_adjusted_error = max(0.016,psal_adjusted_error);
                            switch   s.PSAL_ERROR
                                
                                case {'MAX_OW_INST'};
                                    if s.SAL_INST_UNCERTAINTY<0.016
                                        s.ERROR_PSAL_comment.here = strrep(s.ERROR_PSAL_comment.here,num2str(s.SAL_INST_UNCERTAINTY),'0.016');
                                    end
                                case {'FROM_PI'}
                                    s.ERROR_PSAL_comment.here = ['Error = max[error provided by the PI,0.016]'];
                            end
                            
                            
                        end
                    end
                    
                    
                    
                    FLD.psal_adjusted.data(n_prof,:) = psal_adjusted;
                    FLD.psal_adjusted_qc.data(n_prof,:) = psal_adjusted_qc;
                    
                    FLD=libargo.replace_nan_byfill(FLD); % ajout le 12/04/2016
                    not_fillval_psal = (FLD.psal_adjusted.data(n_prof,:)~=FLD.psal_adjusted.FillValue_);
                    FLD.psal_adjusted_error.data(n_prof,:) = psal_adjusted_error;
                    FLD.psal_adjusted_error.data(n_prof,~not_fillval_psal) = FLD.psal_adjusted_error.FillValue_;
                    
                    % keyboard
                    
                else
                    error('One of the field pres, psal or temp is not found in the netcdf file')
                end
                
                %===============CNDC------CNDC field--------------
                
                
                if isfield(FLD,'cndc')
                    
                    if ~isfield(FLD,'cndc_adjusted') % remplit les structures CNDC_ADJUSTED
                        FLD.cndc_adjusted = FLD.cndc; FLD.cndc_adjusted.name='CNDC_ADJUSTED';
                        
                        FLD.cndc_adjusted_qc = FLD.cndc_qc; FLD.cndc_adjusted_qc.name='CNDC_ADJUSTED_QC';
                        FLD.cndc_adjusted_error = FLD.cndc; FLD.cndc_adjusted_error.name='CNDC_ADJUSTED_ERROR';
                        FLD.cndc_adjusted_error =rmfield(FLD.cndc_adjusted_error,{'valid_min','valid_max'});
                    end
                    test=check_isfillval_prof(FLD,'cndc');
                    if test.cndc==0;
                        inst_type = strtrim(FLD.wmo_inst_type.data(n_prof,:));
                        %if ismember(inst_type,{'841','843','844','846','851','853','856','860','831','838'}) % SBE
                            the_error = 0.005; % mS/cm
                        %elseif ismember (inst_type,{'842','847','852','857','861'}) % FSI
                        if ismember (inst_type,{'842','847','852','857','861'}) % FSI   
                            the_error = 0.01; % mS/cm
                       % else
                        %    disp('Unknown WMO_INST_TYPE')
                        %    the_error =  0.01; %mS/cm
                        end
                        
                        % remplit le champs CNDC adjusted de façon cohérente avec psal_adjusted, temp_adjusted, et pres_adjusted
                        FLD = libargo.replace_fill_bynan(FLD);
                        
                        if ~strcmp(strtrim(FLD.cndc.units),'mhos/m')
                            error(['Make sure tha the unit of FLD.cndc :' FLD.cndc.units ' is consistent with the computation of cndc adjusted and error'])
                        end
                        % ATTENTION unite des fonctions sw 10-3 mhos/cm = mS/cm / unites dans fichier netcdf mhos/m = 10-1 mS/cm!
                        
                        cndc = sw_c3515*sw_cndr( FLD.psal.data(n_prof,:),FLD.temp.data(n_prof,:),FLD.pres.data(n_prof,:)); % mS/cm
                        cndc_adjusted = sw_c3515*sw_cndr( FLD.psal_adjusted.data(n_prof,:),FLD.temp_adjusted.data(n_prof,:),FLD.pres_adjusted.data(n_prof,:)); % mS/cm
                        
                        if ismember({thecorrection},{'NO'})
                            FLD.cndc_adjusted.data(n_prof,:) = FLD.cndc.data(n_prof,:);
                            
                        else
                            cndc_adjusted=cndc_adjusted/10; % 10-1 mS/cm => mhos/m
                            cndc_adjusted (isnan(cndc_adjusted)) = FLD.cndc_adjusted.FillValue_;
                            
                            FLD.cndc_adjusted.data(n_prof,:) = cndc_adjusted; % mhos/m
                            
                        end
                        
                        FLD.cndc_adjusted_qc.data(n_prof,:)  =  FLD.psal_adjusted_qc.data(n_prof,:); % same QC as PSAL_ADJUSTED
                        index_QC4 = strfind(FLD.cndc_adjusted_qc.data(n_prof,:),'4');
                        FLD.cndc_adjusted.data(n_prof,index_QC4) = NaN;
                        
                        cal_COND_err =  C_FILE.pcond_factor_err(ind_cycle).*cndc; % mS/cm
                        
                        FLD.cndc_adjusted_error.data(n_prof,:) = max(the_error/10,cal_COND_err/10); % mhos/m
                        
                        FLD.cndc_adjusted_error.data(n_prof,index_QC4) = NaN;
                        
                        FLD = libargo.replace_nan_byfill(FLD);
                    end
                    
                end
                
                %==============|PROFILE_****_QC|--------------------------
                
                % compute again the profile_QC for each parameter
                
                FLD = libargo.check_profile_qc(FLD);
                
                %==================== SCIENTIFIC_CALIB fields==================================
                
                
                if s.ADD_NCALIB==0
                    n_calib=1;
                    % test if the field "parameter" is filled or not
                    testfill = FLD.parameter.data(:,n_calib,:,:)==FLD.parameter.FillValue_;
                    if libargo.sumel(testfill)==numel(testfill) % parameter est a fillvalue
                        FLD.parameter.data(:,n_calib,:,:) = FLD.station_parameters.data;
                    end
                else
                    n_calib= DIMD.n_calib.dimlength+1;
                    
                    if  DIMD.n_calib.dimlength==1 % test if the field scientific_calib_comment is fillvalue
                    testfill =FLD.scientific_calib_comment.data(:,DIMD.n_calib.dimlength,:,:)==FLD.scientific_calib_comment.FillValue_;
                    if libargo.sumel(testfill)==numel(testfill) % parameter est a fillvalue
                       n_calib= DIMD.n_calib.dimlength
                    end
                    end
                    display(n_calib)
                    FLD.parameter.data(:,n_calib,:,:) = FLD.station_parameters.data;
                end
                
                
%                  % test if the field "parameter" is filled or not
%                  testfill = FLD.parameter.data(:,n_calib,:,:)==FLD.parameter.FillValue_;
%                  if libargo.sumel(testfill)==numel(testfill) % parameter est a fillvalue
%                      FLD.parameter.data(:,n_calib,:,:) = FLD.station_parameters.data;
%                  end
                
                
                
                % fill scientific calibration  for  PSAL
                % --------------------------
                %keyboard
                theparameters = strtrim(squeeze(FLD.parameter.data(n_prof,n_calib,:,:)));
                ind_psal = ismember(cellstr(theparameters),'PSAL');
                ind_pres = ismember(cellstr(theparameters),'PRES');
                % find in pressure equation if surface pressure has been used to calibrate pressure
                presiscalib = ~isempty(strfind(squeeze(FL.scientific_calib_equation.data(n_prof,n_calib,ind_pres,:))','-'));
                
                switch   thecorrection
                    case {'NO'}; % considered as good and need no adjustement in DM
                        
                        equation = 'PSAL_ADJUSTED = PSAL ';
                        %equation = 'none';  % modif 08/09/2016
                        
                        %keyboard
                        if (INPUT_PRESAD ==1||INPUT_PRESAD ==2||INPUT_PRESAD==10&&presiscalib==1)&&s.ADD_NCALIB==0
                            equation = strrep(equation,'PSAL ', 'PSAL (re-calculated using PRES_ADJUSTED)');
                        end
                        if s.THERM==1&&s.ADD_NCALIB==0
                           equation=[equation s.CTM_equation];
                        end
                        
                        if str2num(CYC_PSAL_ADJ_QC)==4
                        equation = 'none'; % BAD
                        end
                        
                        l_eq = length(equation);
                        
                        FLD.scientific_calib_equation.data(n_prof,n_calib,ind_psal,:)=FLD.scientific_calib_equation.FillValue_;
                        FLD.scientific_calib_equation.data(n_prof,n_calib,ind_psal,1:l_eq) = equation;
                        
                        coeff = 'none';
                        if s.THERM==1&&s.ADD_NCALIB==0
                           coeff=[ s.CTM_coefficient];
                        end
                        
                        if str2num(CYC_PSAL_ADJ_QC)==4
                        coeff = 'none'; % BAD
                        end
                        
                        l_co = length(coeff);
                        FLD.scientific_calib_coefficient.data(n_prof,n_calib,ind_psal,:) = FLD.scientific_calib_coefficient.FillValue_;
                        FLD.scientific_calib_coefficient.data(n_prof,n_calib,ind_psal,1:l_co) = coeff;
                        
                        comment =  [s.CORR_PSAL_comment.NO  s.ERROR_PSAL_comment.here s.METHOD  s.REPPORT];
                        if str2num(CYC_PSAL_ADJ_QC)==4
                        comment = ['Bad data; not adjustable. ' s.METHOD  s.REPPORT]; % BAD
                        end
                        
                        CHECK.psal.comment{i}=comment;
                        maxl_co = DIM.(lower(FLD.scientific_calib_comment.dim{4})).dimlength;
                        
                        l_co = length(comment);
                        
                        if l_co > maxl_co
                            error(['The comment ' comment ' is too long']);
                        end
                        
                        
                        FLD.scientific_calib_comment.data(n_prof,n_calib,ind_psal,:) = FLD.scientific_calib_comment.FillValue_;
                        FLD.scientific_calib_comment.data(n_prof,n_calib,ind_psal,1:l_co) = comment;
                        
                        
                    case {'LAUNCH_OFFSET'} % launch offset
                        
                        equation = 'PSAL_ADJUSTED = PSAL ';
                        if (INPUT_PRESAD ==1||INPUT_PRESAD ==2||INPUT_PRESAD==10&&presiscalib==1)&&s.ADD_NCALIB==0
                            equation = strrep(equation,'PSAL ', 'PSAL (re-calculated by using PRES_ADJUSTED)');
                        end
                        if s.THERM==1&&s.ADD_NCALIB==0
                           equation=[equation s.CTM_equation];
                        end
                        
                        equation = [equation ' + launch_offset'];
                        
                        if str2num(CYC_PSAL_ADJ_QC)==4
                        equation = 'none'; % BAD
                        end
                        
                        l_eq = length(equation);
                        
                        
                        FLD.scientific_calib_equation.data(n_prof,n_calib,ind_psal,:)=FLD.scientific_calib_equation.FillValue_;
                        FLD.scientific_calib_equation.data(n_prof,n_calib,ind_psal,1:l_eq) = equation;
                        
                        coefficient = ['launch_offset = ' num2str(s.LAUNCH_OFFSET)];
                        if s.THERM==1&&s.ADD_NCALIB==0
                           coefficient=[coefficient '. ' s.CTM_coefficient];
                        end
                        if str2num(CYC_PSAL_ADJ_QC)==4
                        coefficient = 'none'; % BAD
                        end
                        l_coe = length(coefficient);
                        
                        FLD.scientific_calib_coefficient.data(n_prof,n_calib,ind_psal,:)=FLD.scientific_calib_coefficient.FillValue_;
                        FLD.scientific_calib_coefficient.data(n_prof,n_calib,ind_psal,1:l_coe) = coefficient;
                        
                        comment = [s.CORR_PSAL_comment.LAUNCH_OFFSET s.ERROR_PSAL_comment.here   s.METHOD  s.REPPORT];
                        if str2num(CYC_PSAL_ADJ_QC)==4
                        comment = ['Bad data; not adjustable. ' s.METHOD  s.REPPORT]; % BAD
                        end
                        CHECK.psal.comment{i}=comment;
                        l_co = length(comment);
                        maxl_co = DIM.(lower(FLD.scientific_calib_comment.dim{4})).dimlength;
                        
                        
                        if l_co > maxl_co
                            error(['The comment ' comment ' is too long']);
                        end
                        
                        FLD.scientific_calib_comment.data(n_prof,n_calib,ind_psal,:) = FLD.scientific_calib_comment.FillValue_;
                        FLD.scientific_calib_comment.data(n_prof,n_calib,ind_psal,1:l_co) = comment;
                        
                        
                    case {'OW'}
                        
                        equation = ['PSAL_ADJUSTED = PSAL '];
                        
                        if (INPUT_PRESAD ==1||INPUT_PRESAD ==2||INPUT_PRESAD==10&&presiscalib==1)&&s.ADD_NCALIB==0
                            equation = strrep(equation,'PSAL ', 'PSAL (re-calculated by using PRES_ADJUSTED)');
                        end
                        
                        if s.THERM==1&&s.ADD_NCALIB==0
                           equation=[equation s.CTM_equation];
                        end
                        equation=[equation ' + Delta_S, where Delta_S is calculated from a potential conductivity (ref to 0 dbar) multiplicative adjustment term r'];

                        if str2num(CYC_PSAL_ADJ_QC)==4
                        equation = 'none'; % BAD
                        end
                        
                        
                        l_eq = length(equation);
                        FLD.scientific_calib_equation.data(n_prof,n_calib,ind_psal,:)=FLD.scientific_calib_equation.FillValue_;
                        FLD.scientific_calib_equation.data(n_prof,n_calib,ind_psal,1:l_eq) = equation;
                        
                        
                        FLD = libargo.replace_fill_bynan(FLD);
                        
                        correction = libargo.meanoutnan(FLD.psal_adjusted.data(n_prof,:)-input_psal);
                        
                        therror = libargo.meanoutnan(FLD.psal_adjusted_error.data(n_prof,:));
                        FLD = libargo.replace_nan_byfill(FLD);
                        
                        ic=find(~isnan(correction));
                        correction=correction(ic);
                        
                        ic=find(~isnan(therror));
                        therror=therror(ic);
                        
                        coefficient = ['r= ' num2str(C_FILE.pcond_factor(ind_cycle)) ' (+/- ' num2str(libargo.sd_round(C_FILE.pcond_factor_err(ind_cycle),1)) ') , vertically averaged dS =' num2str(correction) ' (+/- ' num2str(therror) ')' ];
                        
                        if s.THERM==1&&s.ADD_NCALIB==0
                           coefficient=[coefficient '. ' s.CTM_coefficient];
                        end
                        if str2num(CYC_PSAL_ADJ_QC)==4
                        coefficient = 'none'; % BAD
                        end
                        l_coe = length(coefficient);
                        
                        FLD.scientific_calib_coefficient.data(n_prof,n_calib,ind_psal,:)=FLD.scientific_calib_coefficient.FillValue_;
                        FLD.scientific_calib_coefficient.data(n_prof,n_calib,ind_psal,1:l_coe) = coefficient;
                        
                        comment=[s.CORR_PSAL_comment.OW s.ERROR_PSAL_comment.here  s.METHOD  s.REPPORT];
                        if str2num(CYC_PSAL_ADJ_QC)==4
                        comment = ['Bad data; not adjustable. ' s.METHOD  s.REPPORT]; % BAD
                        end
                        CHECK.psal.comment{i}=comment;
                        
                        l_co = length(comment);
                        maxl_co = DIM.(lower(FLD.scientific_calib_comment.dim{4})).dimlength;
                        
                        
                        if l_co > maxl_co
                            error(['The comment ' comment ' is too long']);
                        end
                        FLD.scientific_calib_comment.data(n_prof,n_calib,ind_psal,:) = FLD.scientific_calib_comment.FillValue_;
                        FLD.scientific_calib_comment.data(n_prof,n_calib,ind_psal,1:l_co) = comment;
                        
                end
                
                if format_version<2.3
                    FLD.calibration_date.data(n_prof,n_calib,ind_psal,:)=thedate;
                else
                    FLD.scientific_calib_date.data(n_prof,n_calib,ind_psal,:)=thedate;
                end
                
                
                
                % fill scientific calibration  for PRES
                % --------------------------
                
                %keyboard
                
                theparameters = strtrim(squeeze(FLD.parameter.data(n_prof,n_calib,:,:)));
                ind_pres = ismember(cellstr(theparameters),'PRES');
                if s.ADD_NCALIB==0
                    NINPUT_PRESAD=-1;
                    if INPUT_PRESAD==1|INPUT_PRESAD==10 %if  previous adjustement for PRES
                        iswc_pres=2;
                        % si les scientific calib ne sont pas remplis
                        nbelement = numel(FLD.scientific_calib_comment.data(n_prof,n_calib,ind_pres,:));
                        isfillval = sum(FLD.scientific_calib_comment.data(n_prof,n_calib,ind_pres,:) == FLD.scientific_calib_comment.FillValue_);
                        
                        %keyboard
                        if nbelement==isfillval
                        disp('WARNING: No Scientific calibration comment for PRES')

                        if INPUT_PRESAD==10
                            NINPUT_PRESAD=0;
                            disp('-> PRES_ADJUSTED = PRES. Calibration comments will be filled')
                        end
                        end
                    end
                    
                    if INPUT_PRESAD==0 |NINPUT_PRESAD==0 %   if no previous adjustement for PRES
                        eq=['PRES_ADJUSTED = PRES'];  % modif 08/09/2016
                        %eq= 'none';
                        l_co = length(eq);
                        
                        FLD.scientific_calib_equation.data(n_prof,n_calib,ind_pres,:) = FLD.scientific_calib_equation.FillValue_;
                        FLD.scientific_calib_equation.data(n_prof,n_calib,ind_pres,1:l_co) = eq;
                        
                        
                        coeff= 'none' ;
                        l_co = length(coeff);
                        FLD.scientific_calib_coefficient.data(n_prof,n_calib,ind_pres,:) = FLD.scientific_calib_coefficient.FillValue_;
                        FLD.scientific_calib_coefficient.data(n_prof,n_calib,ind_pres,1:l_co) = coeff;
                        
                        
                        comment = s.CORR_PRES_comment;
                        maxl_co = DIM.(lower(FLD.scientific_calib_comment.dim{4})).dimlength;
                        l_co = length(comment);
                        
                        if l_co > maxl_co
                            error(['The comment ' comment ' is too long']);
                        end
                        % keyboard
                        FLD.scientific_calib_comment.data(n_prof,n_calib,ind_pres,:) = FLD.scientific_calib_comment.FillValue_;
                        FLD.scientific_calib_comment.data(n_prof,n_calib,ind_pres,1:l_co) = comment;
                        
                        
                        
                        if format_version<2.3
                            FLD.calibration_date.data(n_prof,n_calib,ind_pres,:)=thedate;
                        else
                            FLD.scientific_calib_date.data(n_prof,n_calib,ind_pres,:)=thedate;
                        end
                        iswc_pres=2;
                    end
                    
                    
                    
                    if INPUT_PRESAD==2  %  PRES is adjusted (data_mode=A): we keep it
                        
                        while iswc_pres==2
                            options.Resize='on';
                            options.WindowStyle='normal';
                            options.Interpreter='none';
                            dlg_title = 'PRESSURE ADJUSTEMENT IN REAL TIME';
                            clear prompt1 def
                            
                            prompt1{1} = ['Scientific_calib_comment'] ;
                            %def{1} = 'PRES_ADJUSTED(cycle i) = PRES(cycle i) - SP(cycle i)';
                            %def{2} = ['SP = ' num2str(sd_round(libargo.meanoutnan(-diff_pres),2)) ' ' strtrim(FL.pres_adjusted.units)] ;
                            def{1} = ['Pressure adjusted for offset by using surface pressure, following the real-mode pressure adjustment procedure described in the Argo quality control manual version 2.9. Calibration error is manufacturer specified accuracy'] ;
                            num_lines = 1;
                            answer_pres = inputdlg(prompt1,dlg_title,num_lines,def,options);
                            if isempty(answer_pres)==0
                                iswc_pres=1;
                            end
                        end
                        
                        eq=['PRES_ADJUSTED(cycle i) = PRES(cycle i) - SP(cycle i)'];
                        l_co = length(eq);
                        
                        
                        
                        FLD.scientific_calib_equation.data(n_prof,n_calib,ind_pres,:) = FLD.scientific_calib_equation.FillValue_;
                        FLD.scientific_calib_equation.data(n_prof,n_calib,ind_pres,1:l_co) = eq;
                        
                        
                        coeff= ['SP = ' num2str(libargo.sd_round(libargo.meanoutnan(-diff_pres),2)) ' ' strtrim(FL.pres_adjusted.units)] ;
                        l_co = length(coeff);
                        FLD.scientific_calib_coefficient.data(n_prof,n_calib,ind_pres,:) = FLD.scientific_calib_coefficient.FillValue_;
                        FLD.scientific_calib_coefficient.data(n_prof,n_calib,ind_pres,1:l_co) = coeff;
                        
                        comment = answer_pres{1};
                        
                        maxl_co = DIM.(lower(FLD.scientific_calib_comment.dim{4})).dimlength;
                        
                        l_co = length(comment);
                        
                        if l_co > maxl_co
                            error(['The comment ' comment ' is too long']);
                        end
                        % keyboard
                        
                        FLD.scientific_calib_comment.data(n_prof,n_calib,ind_pres,:) = FLD.scientific_calib_comment.FillValue_;
                        FLD.scientific_calib_comment.data(n_prof,n_calib,ind_pres,1:l_co) = comment;
                        
                        
                        
                        if format_version<2.3
                            FLD.calibration_date.data(n_prof,n_calib,ind_pres,:)=thedate;
                        else
                            FLD.scientific_calib_date.data(n_prof,n_calib,ind_pres,:)=thedate;
                        end
                        
                    end
                else
                    thestr='none'; l_thestr=length(thestr);
                    FLD.scientific_calib_equation.data(n_prof,n_calib,ind_pres,:) = FLD.scientific_calib_equation.FillValue_;
                    FLD.scientific_calib_equation.data(n_prof,n_calib,ind_pres,1:l_thestr) = thestr;
                    FLD.scientific_calib_coefficient.data(n_prof,n_calib,ind_pres,:) = FLD.scientific_calib_coefficient.FillValue_;
                    FLD.scientific_calib_coefficient.data(n_prof,n_calib,ind_pres,1:l_thestr) = thestr;   
                    FLD.scientific_calib_comment.data(n_prof,n_calib,ind_pres,:) = FLD.scientific_calib_comment.FillValue_;
                    FLD.scientific_calib_comment.data(n_prof,n_calib,ind_pres,1:l_thestr) = thestr;
                end
                CHECK.pres.comment{i} = squeeze(FLD.scientific_calib_comment.data(n_prof,n_calib,ind_pres,:))';
                
                % fill scientific calibration  for  TEMP
                % --------------------------
                
                theparameters = strtrim(squeeze(FLD.parameter.data(n_prof,n_calib,:,:)));
                ind_temp = ismember(cellstr(theparameters),'TEMP');
                if s.ADD_NCALIB==0
                    %eq=['TEMP_ADJUSTED = TEMP']; % modif 08/09/2016
                    eq='none';
                    l_co = length(eq);
                    
                    FLD.scientific_calib_equation.data(n_prof,n_calib,ind_temp,:) = FLD.scientific_calib_equation.FillValue_;
                    FLD.scientific_calib_equation.data(n_prof,n_calib,ind_temp,1:l_co) = eq;
                    
                    coeff='none';
                    l_co = length(coeff);
                    FLD.scientific_calib_coefficient.data(n_prof,n_calib,ind_temp,:) = FLD.scientific_calib_coefficient.FillValue_;
                    FLD.scientific_calib_coefficient.data(n_prof,n_calib,ind_temp,1:l_co) = coeff;
                    
                    comment = s.CORR_TEMP_comment;
                    %CHECK.temp.comment{i}=comment;
                    
                    maxl_co = DIM.(lower(FLD.scientific_calib_comment.dim{4})).dimlength;
                    
                    l_co = length(comment);
                    
                    if l_co > maxl_co
                        error(['The comment ' comment ' is too long']);
                    end
                    
                    FLD.scientific_calib_comment.data(n_prof,n_calib,ind_temp,:) = FLD.scientific_calib_comment.FillValue_;
                    FLD.scientific_calib_comment.data(n_prof,n_calib,ind_temp,1:l_co) = comment;
                    
                else
                    thestr='none'; l_thestr=length(thestr);
                    FLD.scientific_calib_equation.data(n_prof,n_calib,ind_temp,:) = FLD.scientific_calib_equation.FillValue_;
                    FLD.scientific_calib_equation.data(n_prof,n_calib,ind_temp,1:l_thestr) = thestr;
                    FLD.scientific_calib_coefficient.data(n_prof,n_calib,ind_temp,:) = FLD.scientific_calib_coefficient.FillValue_;
                    FLD.scientific_calib_coefficient.data(n_prof,n_calib,ind_temp,1:l_thestr) = thestr;   
                    FLD.scientific_calib_comment.data(n_prof,n_calib,ind_temp,:) = FLD.scientific_calib_comment.FillValue_;
                    FLD.scientific_calib_comment.data(n_prof,n_calib,ind_temp,1:l_thestr) = thestr;
                end
                CHECK.temp.comment{i} = squeeze(FLD.scientific_calib_comment.data(n_prof,n_calib,ind_temp,:))';
                if format_version<2.3
                    FLD.calibration_date.data(n_prof,n_calib,ind_temp,:)=thedate;
                else
                    FLD.scientific_calib_date.data(n_prof,n_calib,ind_temp,:)=thedate;
                end
                
                
                % fill scientific calibration for  CNDC
                % --------------------------
                theparameters = strtrim(squeeze(FLD.parameter.data(n_prof,n_calib,:,:)));
                ind_cndc = ismember(cellstr(theparameters),'CNDC');
                
                %see what to do if CTM correction!!
                if sum(ind_cndc)==1
                    
                    switch   thecorrection
                        case {'NO'}; % considered as good and need no adjustement in DM
                            
                            eq=['CNDC_ADJUSTED = CNDC']; %modif 08/09/2016
                            %eq='none';
                            if str2num(CYC_PSAL_ADJ_QC)==4
                            equation = 'None'; % BAD
                            end
                            
                            l_co = length(eq);
                            
                            FLD.scientific_calib_equation.data(n_prof,n_calib,ind_cndc,:) = FLD.scientific_calib_equation.FillValue_;
                            FLD.scientific_calib_equation.data(n_prof,n_calib,ind_cndc,1:l_co) = eq;
                            
                            coeff='none';
                            l_co = length(coeff);
                            FLD.scientific_calib_coefficient.data(n_prof,n_calib,ind_cndc,:) = FLD.scientific_calib_coefficient.FillValue_;
                            FLD.scientific_calib_coefficient.data(n_prof,n_calib,ind_cndc,1:l_co) = coeff;
                            
                            
                            FLD.scientific_calib_equation.data(n_prof,n_calib,ind_cndc,:) = FLD.scientific_calib_equation.FillValue_;
                            
                            FLD.scientific_calib_coefficient.data(n_prof,n_calib,ind_cndc,:) = FLD.scientific_calib_coefficient.FillValue_;
                            
                            CORR_CNDC_comment = regexprep(s.CORR_PSAL_comment.NO,'salinity','conductivity','preservecase');
                            
                            comment = [CORR_CNDC_comment ERROR_CNDC_comment  s.METHOD  '.' ];
                            
                            if str2num(CYC_PSAL_ADJ_QC)==4
                            comment = 'Bad data; not adjustable'; % BAD
                            end
                            
                            CHECK.cndc.comment{i}=comment;
                            
                            maxl_co = DIM.(lower(FLD.scientific_calib_comment.dim{4})).dimlength;
                            
                            l_co = length(comment);
                            
                            if l_co > maxl_co
                                error(['The comment ' comment ' is too long']);
                            end
                            
                            FLD.scientific_calib_comment.data(n_prof,n_calib,ind_cndc,:) = FLD.scientific_calib_comment.FillValue_;
                            FLD.scientific_calib_comment.data(n_prof,n_calib,ind_cndc,1:l_co) = comment;
                            
                            
                        case {'LAUNCH_OFFSET'}
                            % tank offset
                            
                            equation = 'CNDC_ADJUSTED = sw_c3515*sw_cndr(PSAL_ADJUSTED,TEMP_ADJUSTED,PRES_ADJUSTED)';
                            if str2num(CYC_PSAL_ADJ_QC)==4
                            equation = 'None'; % BAD
                            end
                            
                            l_eq = length(equation);
                            
                            FLD.scientific_calib_equation.data(n_prof,n_calib,ind_cndc,:) = FLD.scientific_calib_equation.FillValue_;
                            FLD.scientific_calib_equation.data(n_prof,n_calib,ind_cndc,1:l_eq) = equation;
                            
                            coefficient = 'sw_c3515=42.9140 mS/cm - SW_CNDR calculates conductivity ratio from S,T,P';
                            l_coe = length(coefficient);
                            
                            FLD.scientific_calib_coefficient.data(n_prof,n_calib,ind_cndc,:) = FLD.scientific_calib_coefficient.FillValue_;
                            FLD.scientific_calib_coefficient.data(n_prof,n_calib,ind_cndc,1:l_coe) = coefficient;
                            
                            CORR_CNDC_comment = regexprep(s.CORR_PSAL_comment.LAUNCH_OFFSET,'salinity','conductivity','preservecase');
                            
                            comment = [CORR_CNDC_comment ERROR_CNDC_comment s.METHOD '.' ];
                            if str2num(CYC_PSAL_ADJ_QC)==4
                            comment = 'Bad data; not adjustable'; % BAD
                            end
                            CHECK.cndc.comment{i}=comment;
                            
                            
                            l_co = length(comment);
                            maxl_co = DIM.(lower(FLD.scientific_calib_comment.dim{4})).dimlength;
                            
                            
                            if l_co > maxl_co
                                error(['The comment ' comment ' is too long']);
                            end
                            
                            FLD.scientific_calib_comment.data(n_prof,n_calib,ind_cndc,:) = FLD.scientific_calib_comment.FillValue_;
                            FLD.scientific_calib_comment.data(n_prof,n_calib,ind_cndc,1:l_co) = comment;
                            
                            
                        case {'OW'}
                            
                            equation = ['CNDC_ADJUSTED = sw_c3515*sw_cndr(PSAL_ADJUSTED,TEMP_ADJUSTED,PRES_ADJUSTED)'];
                            if str2num(CYC_PSAL_ADJ_QC)==4
                            equation = 'None'; % BAD
                            end
                            l_eq = length(equation);
                            
                            FLD.scientific_calib_equation.data(n_prof,n_calib,ind_cndc,:) = FLD.scientific_calib_equation.FillValue_;
                            FLD.scientific_calib_equation.data(n_prof,n_calib,ind_cndc,1:l_eq) = equation;
                            
                            
                            coefficient = ['sw_c3515=42.9140 mS/cm - SW_CNDR calculates conductivity ratio from S,T,P'];
                            
                            l_coe = length(coefficient);
                            
                            FLD.scientific_calib_coefficient.data(n_prof,n_calib,ind_cndc,:) = FLD.scientific_calib_coefficient.FillValue_;
                            FLD.scientific_calib_coefficient.data(n_prof,n_calib,ind_cndc,1:l_coe) = coefficient;
                            
                            CORR_CNDC_comment = regexprep(s.CORR_PSAL_comment.OW,'salinity','conductivity','preservecase');
                            
                            comment = [CORR_CNDC_comment ERROR_CNDC_comment s.METHOD '.' ];
                            if str2num(CYC_PSAL_ADJ_QC)==4
                            comment = 'Bad data; not adjustable'; % BAD
                            end
                            CHECK.cndc.comment{i}=comment;
                            
                            l_co = length(comment);
                            maxl_co = DIM.(lower(FLD.scientific_calib_comment.dim{4})).dimlength;
                            
                            
                            if l_co > maxl_co
                                error(['The comment ' comment ' is too long']);
                            end
                            
                            FLD.scientific_calib_comment.data(n_prof,n_calib,ind_cndc,:) = FLD.scientific_calib_comment.FillValue_;
                            FLD.scientific_calib_comment.data(n_prof,n_calib,ind_cndc,1:l_co) = comment;
                            
                    end
                    
                    if format_version<2.3
                        FLD.calibration_date.data(n_prof,n_calib,ind_cndc,:)=thedate;
                    else
                        FLD.scientific_calib_date.data(n_prof,n_calib,ind_cndc,:)=thedate;
                    end
                    
                end
                
        
                
                DIMD.n_param.dimlength = size(FLD.scientific_calib_comment.data,3);
                DIMD.n_calib.dimlength = size(FLD.scientific_calib_comment.data,2);
                
                %================== HISTORY fields
                %define new_hist=N_HISTORY+1
                
                new_hist = DIM.n_history.dimlength+1;
                
                allfields = fieldnames(FLD);
                
                ii = strfind(allfields,'history_');
                is_history = find(~cellfun('isempty',ii));
                
                FLD = libargo.check_FirstDimArray_is(FLD,'N_HISTORY');
                
                if DIM.n_history.dimlength~=0
                    % remplit un historique de plus avec des FillValue
                    [FLD_ex,DIM_ex]=libargo.extract_profile_dim(FLD,DIM,'N_HISTORY',1);
                    %keyboard
                    for ik = is_history'
                        oneChamp =allfields{ik};
                        ii=FLD_ex.(oneChamp).data~=FLD_ex.(oneChamp).FillValue_;
                        FLD_ex.(oneChamp).data(ii)=FLD_ex.(oneChamp).FillValue_;
                    end
                    
                    [FLD,DIMD] = libargo.cat_profile_dim(FLD,FLD_ex,DIMD,DIM_ex,'N_HISTORY');
                else
                    for ik = is_history'
                        oneChamp =allfields{ik};
                        siz(1)=1;
                        for tk=2:length(FLD.(oneChamp).dim)
                            siz(tk) = DIM.(lower(FLD.(oneChamp).dim{tk})).dimlength;
                        end
                        FLD.(oneChamp).data = repmat(FLD_ex.(oneChamp).FillValue_,siz);
                        DIMD.n_history.dimlength=1;
                    end
                end
                
                
                % fill HISTORY section
                institution=s.INSTITUTION;
                l_in=length(institution);
                FLD.history_institution.data(new_hist,n_prof,1:l_in)=institution;
                
                step='ARSQ';
                FLD.history_step.data(new_hist,n_prof,:)=step;
                
                soft='OW';
                l_so=length(soft);
                FLD.history_software.data(new_hist,n_prof,1:l_so)=soft;
                
                if length(s.OW_RELEASE)>4
                 warning('OW VERSION is truncated to 4 characters in HISTORY_SOFTWARE_RELEASE')
                soft_release=s.OW_RELEASE(1:4);
                else
                 soft_release=s.OW_RELEASE;
                end
                l_so_r=length(soft_release);
                FLD.history_software_release.data(new_hist,n_prof,1:l_so_r)=soft_release;
                
                ref = s.OW_REF;
                l_ref=length(ref);
                FLD.history_reference.data(new_hist,n_prof,1:l_ref)=ref;
                
                FLD.history_date.data(new_hist,n_prof,:)=thedate;
                
                action='IP';
                l_ac=length(action);
                FLD.history_action.data(new_hist,n_prof,1:l_ac)=action;
                
                parameter='PSAL';
                l_pa=length(parameter);
                FLD.history_parameter.data(new_hist,n_prof,1:l_pa)=parameter;
                
                thepres = FLD.pres.data(n_prof,:);
                thepres = thepres(~isnan(thepres));
                
                FLD.history_start_pres.data(new_hist,n_prof)=thepres(1);
                FLD.history_stop_pres.data(new_hist,n_prof)=thepres(end);
                
                
                %% Birgit 01/02/2006
                % eliminate NaNs in the PSAL_ADJUSTED which have been written into the
                % mat-files during mapping when TEMP_QC=4 or PSAL_QC=4
                % remarque CC 28/01/2014 : ce n'est plus necessaire si correction a partir de pcond_factor
                % la correction est calculee de toute façon mais remplacée par FillValue si PSAL_QC==4
                
                
                
                % Save modifications in the D file
                
                FLD.date_update.data = thedate';
                
                % verifie qu'il n'y ait pas de NaN, et sinon remplace par des
                % fill_value
               % keyboard
                FLD = libargo.replace_nan_byfill(FLD);
                
                if isfield(C,'OPERATOR_NAME')&&isfield(C,'OPERATOR_ORCID_ID')&&isfield(C,'OPERATOR_INSTITUTION')
                GlobattD.comment_dmqc_operator.att = ['PRIMARY | ' strtrim(C.OPERATOR_ORCID_ID) ' | ' strtrim(C.OPERATOR_NAME) ', ' strtrim(C.OPERATOR_INSTITUTION) ];
                GlobattD.comment_dmqc_operator.name = 'comment_dmqc_operator';
                end
                libargo.create_netcdf_allthefile(FLD,DIMD,[root_out file_out],GlobattD);
                
                
                % Save some variables to make plots for checking what was done
                FLD = libargo.format_flags_char2num(FLD); % modif cc 07/02/2020
                FL = libargo.format_flags_char2num(FL);   % modif cc 07/02/2020
                FLD = libargo.replace_fill_bynan(FLD);
                FL = libargo.replace_fill_bynan(FL);
                
                %CHECK.n_cycle_for_plot: numero de cycle pour le plot de check: profil ascendant decale de 0.5 dans cas ou il y a un profil descendant et un profil ascendant pour un meme cycle
                % cela permet de tracer les qc de tous les profils A et D.
                
				
                if direction=='A'
                    if i>ifirst && CHECK.n_cycle(i-1)==FLD.cycle_number.data(n_prof); % cyle D et cycle A pour un meme cycle
                        CHECK.n_cycle_for_plot(i) =double(FLD.cycle_number.data(n_prof))+0.5;
                    else
                        CHECK.n_cycle_for_plot(i) =double(FLD.cycle_number.data(n_prof));
                    end
                    
                elseif direction=='D'
                    CHECK.n_cycle_for_plot(i) =double(FLD.cycle_number.data(n_prof));
                end
                CHECK.n_cycle(i) = double(FLD.cycle_number.data(n_prof));
                CHECKOLD.n_cycle(i) = double(FL.cycle_number.data(n_prof));
                
                check_param={'psal','temp','pres','cndc','doxy'};
                
                for ok=[1:length(check_param)]
                    
                    param= check_param{ok};
                    
                    if isfield(FLD,[param '_adjusted'])
                        diff = FLD.([param '_adjusted']).data(n_prof,:) - FLD.([param]).data(n_prof,:);
                        CHECK.(param).n_correction(i) = libargo.meanoutnan(diff);
                        
                        CHECK.(param).adj(i)= libargo.meanoutnan(FLD.([param '_adjusted']).data(n_prof,:));
                        CHECK.(param).adj_err(i) = libargo.meanoutnan(FLD.([param '_adjusted_error']).data(n_prof,:));
                        CHECK.(param).raw(i) = libargo.meanoutnan(FLD.(param).data(n_prof,:));
                        
                        %FLD = libargo.format_flags_char2num(FLD);
                        
                        the_qc = FLD.([param '_adjusted_qc']).data(n_prof,:);
                        the_qc(the_qc==0)=99;
                        
                        CHECK.(param).adjqc(i,1:length(the_qc))=the_qc;
                        CHECK.(param).adjqc(CHECK.(param).adjqc==0)=NaN;
                        
                        the_qc = FLD.([param '_qc']).data(n_prof,:);
                        the_qc(the_qc==0)=99;
                        
                        the_pres = FLD.pres.data(n_prof,:);
                        CHECK.thepres(i,1:length(the_pres))=the_pres;
                        CHECK.thepres(CHECK.thepres==0)=NaN;
                        
                        CHECK.(param).qc(i,1:length(the_qc))=the_qc;
                        CHECK.(param).qc(CHECK.(param).qc==0)=NaN;
                        if isfield(FLD.(param),'resolution')
                            CHECK.(param).resolution(i)=FLD.(param).resolution;
                        end
                    end
                    % OLD corrections
                    if isfield(FL,[param '_adjusted'])
                        diff = FL.([param '_adjusted']).data(n_prof,:) - FL.([param]).data(n_prof,:);
                        CHECKOLD.(param).n_correction(i) = libargo.meanoutnan(diff);
                        
                        CHECKOLD.(param).adj(i)= libargo.meanoutnan(FL.([param '_adjusted']).data(n_prof,:));
                        CHECKOLD.(param).adj_err(i) = libargo.meanoutnan(FL.([param '_adjusted_error']).data(n_prof,:));
                        CHECKOLD.(param).raw(i) = libargo.meanoutnan(FL.(param).data(n_prof,:));
                        
                        %FL = libargo.format_flags_char2num(FL);
                        
                        the_qc = FL.([param '_adjusted_qc']).data(n_prof,:);
                        the_qc(the_qc==0)=99;
                        
                        CHECKOLD.(param).qc(i,1:length(the_qc))=the_qc;
                        CHECKOLD.(param).qc(CHECKOLD.(param).qc==0)=NaN;
                        
                    end
                end
                
                %clear FLD DIM FL DIMD
                
                
                
            end
            
        end
    end
end


fclose(fic);
%keyboard
CHECK.psal.cal_sal = libargo.meanoutnan(C_FILE.cal_SAL);

% Figure de CHECK
check_dmqc(CHECK,'psal',s.CORRECTION,s.APPLY_upto_CY,flotteur)

check_dmqc(CHECK,'temp',s.CORRECTION,s.APPLY_upto_CY,flotteur)

check_dmqc(CHECK,'pres',s.CORRECTION,s.APPLY_upto_CY,flotteur)

check_dmqc(CHECK,'cndc',s.CORRECTION,s.APPLY_upto_CY,flotteur)

check_dmqc(CHECK,'doxy',s.CORRECTION,s.APPLY_upto_CY,flotteur)


