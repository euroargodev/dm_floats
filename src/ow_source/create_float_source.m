% ========================================================
%   USAGE :  create_float_source(flt_name)
%
%   PURPOSE : create FLOAT SOURCE file (.mat file in /float_source/) for the OW software from
%   the netcdf single-cycle core files. 
%
%   By default, variables loaded are raw PRES, PSAL and TEMP. 
%   If PRES is adjusted, variables loaded are PRES_ADJUSTED, raw PSAL calibrated in pressure and raw TEMP.
%   You can force the program to load raw PRES, PSAL and TEMP whatever PRES is adjusted or not:
%   -> run create_float_source(flt_name,'force','raw')
%   or you can force the program to load adjusted variables: PRES_ADJUSTED, PSAL_ADJUSTED, TEMP_ADJUSTED 
%   -> then run create_float_source(flt_name,'force','adjusted')
% -----------------------------------
%   INPUT :
%     flt_name  (char)  -- wmo float name  e.g.: '4900139'
%
%   OPTIONAL INPUT :
%     force      (char)     'raw' : force the program to load PRES TEMP and PSAL
%                           'adjusted': force the program to load PRES_ADJUSTED, PSAL_ADJUSTED, TEMP_ADJUSTED
%     email      (char)      your email, in case you want to download  the netcdf file from ftp://ftp.ifremer.fr/ifremer/argo/dac/ (user anonymous, psswd: email)
%                             e.g. create_float_source(flt_name,'email','myname@ifremer.fr')
%                             @l.95  Change 'System' to 'WINDOWS' if needed
% -----------------------------------
%   OUTPUT :
%     mat file: /data/float_source/{flt_name}.mat with the following
%     variables  (m vertical levels, n profiles)
%       DATES (1xn, in decimal year, e.g. 10 Dec 2000 = 2000.939726)
%       LAT   (1xn, in decimal degrees, -ve means south of the equator, e.g. 20.5S = -20.5)
%       LONG  (1xn, in decimal degrees, from 0 to 360, e.g. 98.5W in the eastern Pacific = 261.5E)
%       PRES  (mxn, dbar, from shallow to deep, e.g. 10, 20, 30 ... These have to line up aLONG a fixed nominal depth axis.)
%       TEMP  (mxn, in-situ IPTS-90)
%       SAL   (mxn, PSS-78)
%       PTMP  (mxn, potential temperature referenced to zero pressure, use SAL in PSS-78 and in-situ TEMP in IPTS-90 for calculation, e.g. sw_ptmp.m)
%       PROFILE_NO (1xn, this goes from 1 to n. PROFILE_NO is the same as CYCLE_NO in the Argo files.)
%       Extra spaces & Bad data with NaN
% -----------------------------------
%   HISTORY
% 04/12/2006   : C.Coatanoan: - creation
% 21/06/2007   : N.David   : - Add Selection of float, Pb of downward profile
%  07/2009 : C.Lagadec : - use of matlab 2009 for reading netcdf files
%  07/2015 : C.Cabanes : - read mono-cycle files/use of libargo tools/reduce high vertical sampling
%  04/2018 : C.Cabanes : - possibility to downmoad data from ftp.ifremer.fr (wget call)
%  06/2018: c.Cabanes  : - replace wget call by matlab function ftp. email as an optional  input
% 
%  tested with matlab  8.3.0.532 (R2014a)
%
%  EXTERNAL LIB
%  package +libargo:  addpath('../../../dm_floats/lib/')
%  seawater:  addpath('../../../dm_floats/lib/seawater_330_its90/')
%
%  CONFIGURATION file: config.txt;
%==================================================

function create_float_source(flt_name, varargin )

n=length(varargin);

if n/2~=floor(n/2)
    error('check the imput arguments')
end

f=varargin(1:2:end);
c=varargin(2:2:end);
s = cell2struct(c,f,2);

if ischar(flt_name)==0
flt_name      = num2str(flt_name);
end

float_name      = str2mat(flt_name);

%---------------------------------------------------------------
% in/out directories
C=load_configuration('config.txt');
float_netcdf_directory= C.DIR_FTP;    % input files directory
float_matfile_directory = C.DIR_OUT;   % output files directory

root_in=[ float_netcdf_directory '/' flt_name '/profiles/'];
root_out= [float_matfile_directory '/'];

if exist(root_out)==0
    mkdir(root_out)
end

%---------------------------------------------------------------
% output file
mat_filename=[root_out float_name '.mat'];

if exist(mat_filename,'file')
    display(['MAT FILE already exists for float: ' flt_name])
    display('TIP: to update this file, first delete it')
    display(mat_filename)
else
    %---------------------------------------------------------------
    % NETCDF INPUT FILES:
    % load data from ftp 
    if isfield(s,'email')==1
       display('Loading data from ftp://ftp.ifremer.fr  wait...')
       ftpobj = ftp('ftp.ifremer.fr','anonymous',s.email,'System','UNIX') % change UNIX to WINDOWS if needed
       cd(ftpobj,'ifremer/argo/dac/')
        isload=0;
        daclist={'aoml','bodc','coriolis','csio','csiro','incois','jma','kma','kordi','meds','nmdis'};
        %daclist={'coriolis'};
        % check around all dacs
        for i=1:length(daclist)
           try
                
                cd(ftpobj,[daclist{i} '/' flt_name])
                cd(ftpobj,'profiles')
                mkdir(root_in)
                mget(ftpobj,'R*.nc',root_in)  %load R files
                mget(ftpobj,'D*.nc',root_in)  %load D files
                isload=isload+1;
            end  
        end
        if isload==1
        display('End Loading data from ftp://ftp.ifremer.fr')
        else
        error('Error when loading data from ftp://ftp.ifremer.fr')
        end
        close(ftpobj)    
    end
    if exist([root_in ],'dir')==0
              error(['The float NETCDF file directory :' root_in  ' does not exist' ])
    end  
    
    display(['MAT FILE is created for float : ' flt_name]);
    display('________________________________________')
    display ('SOURCE FILE')
    display('________________________________________')
    
    %---------------------------------------------------------------
    %  Select the mono_cycle files : take only the "core" files i.e. remove B and M files from the full list of files.

    list=dir([root_in '*.nc']);
    filenames={list.name};
    ischarcellB = strfind(filenames,'B');
    ischarcellM = strfind(filenames,'M');
    if ~isempty(ischarcellB)||~isempty(ischarcellM) % remove B and M files
        core_files = filenames(cellfun(@isempty,ischarcellB)&cellfun(@isempty,ischarcellM));
    end
    
    % Do not take descending profiles
    ischarcellD = strfind(core_files,'D.nc');
    
    if ~isempty(ischarcellD)
        core_Asc_files = core_files(cellfun(@isempty,ischarcellD));
    end
    
    % sort file names following the cycle number
    clear num_cy num_cy_num
    for k=1:length(core_Asc_files)
        [poub,num_cy(k)] = strtok(core_Asc_files(k),'_');
        num_cy(k) = strrep(num_cy(k),'_','');
        num_cy(k) = strrep(num_cy(k),'.nc','');
        num_cy_num(k) = str2double(num_cy{k});
    end
    [cy_sort,isort]=sort(num_cy_num);
    
    core_Asc_files=core_Asc_files(isort);
    
    %---------------------------------------------------------------
    % read files, selecting the following variables
    Param.direction.name='DIRECTION';
    Param.longitude.name='LONGITUDE';
    Param.latitude.name='LATITUDE';
    Param.position_qc.name='POSITION_QC';
    Param.juld.name='JULD';
    Param.juld_qc.name='JULD_QC';
    Param.direction.name='DIRECTION';
    Param.cycle_number.name='CYCLE_NUMBER';
    Param.vertical_sampling_scheme.name='VERTICAL_SAMPLING_SCHEME';
    Param.psal.name='PSAL';
    Param.temp.name='TEMP';
    Param.pres.name='PRES';
    Param.psal_qc.name='PSAL_QC';
    Param.temp_qc.name='TEMP_QC';
    Param.pres_qc.name='PRES_QC';
    Param.pres_adjusted.name='PRES_ADJUSTED';
    Param.pres_adjusted_qc.name='PRES_ADJUSTED_QC';
    Param.psal_adjusted.name='PSAL_ADJUSTED';
    Param.temp_adjusted.name='TEMP_ADJUSTED';
    Param.psal_adjusted_qc.name='PSAL_ADJUSTED_QC';
    Param.temp_adjusted_qc.name='TEMP_ADJUSTED_QC';
    
    %keyboard
    FLm=[];
    DIMm=[];
    isreduced=1; %max one level every 10db, if 0 keep the original vertical sampling
    for k=1:length(core_Asc_files)
        
        [FL,DIM,Globatt] = libargo.read_netcdf_allthefile([root_in   core_Asc_files{k}],Param);
        
        if  DIM.n_prof.dimlength>1
            is_primary=libargo.findstr_tab(FL.vertical_sampling_scheme.data,'Primary sampling');
            if sum(is_primary)>1
            warning(['Float ' core_Asc_files{k} 'more than one primary sampling!!']) % found one case. It is now corrected
            is_primary=is_primary(1);
            end
            [FL,DIM] = libargo.extract_profile_dim(FL,DIM,'N_PROF',is_primary);
        end
        
        %if DIM.n_levels.dimlength>300 %  23/08/2019 this condition is
        %removed since it can sometimes result in data gap when all
        %pressure measurements are put at the same index levels (see line
        %437 of this code)
        %keyboard
       if isreduced==1   
            Fi=libargo.replace_fill_bynan(FL);
            thepres=floor(Fi.pres.data/10);     % 23/08/2019 max one level every 10db (floor instead of round => less gaps)
           [up,ip]=unique(thepres,'legacy');    % 23/08/2019 'legacy': take the deepest level on the 10db layer
            if length(up)< length(thepres)
            display(['Reduce vertical sampling - max 1 level every 10db -(' num2str(DIM.n_levels.dimlength) ' to ' num2str(length(ip)) ')'])
            end
            [FL,DIM] = libargo.extract_profile_dim(FL,DIM,'N_LEVELS',ip);
            FL = libargo.check_FirstDimArray_is(FL,'N_PROF');
        end
        
        [FLm,DIMm]=libargo.cat_profile_dim(FLm,FL,DIMm,DIM,'N_PROF');
    end
    
    %---------------------------------------------------------------
    %  prepare output file
    
    direction = FLm.direction.data';
    % get data for calibration :
    % Julian day (UTC) of the station relative to REFERENCE_DATE_TIME,
    % Quality on DATE and TIME
    jul      = FLm.juld.data';
    jul_qc   = FLm.juld_qc.data';
    
    % Float cycle number, Latitude and longitude of the station, best estimate
    PROFILE_NO      = FLm.cycle_number.data';
    LAT             = FLm.latitude.data';
    LONG            = FLm.longitude.data';
    
    % PRES, PSAL, TMP in situ T90 scale
    PRESINI   = FLm.pres.data';
    SALINI    = FLm.psal.data';
    TEMPINI   = FLm.temp.data';
    if isfield(s,'force')==1&&strcmp(s.force,'adjusted')
       PRESINI   = FLm.pres_adjusted.data';
       SALINI    = FLm.psal_adjusted.data';
       TEMPINI   = FLm.temp_adjusted.data';
    end
    % Quality Flags (P,S,T,position)
    pres_qc  = FLm.pres_qc.data';
    psal_qc  = FLm.psal_qc.data';
    temp_qc  = FLm.temp_qc.data';
    if isfield(s,'force')==1&&strcmp(s.force,'adjusted')
       pres_qc  = FLm.pres_adjusted_qc.data';
       psal_qc  = FLm.psal_adjusted_qc.data';
       temp_qc  = FLm.temp_adjusted_qc.data';
    end
    
    pos_qc   = FLm.position_qc.data';
    
    if isfield(s,'force')==0 % take into account the adjusted pressure if needed
        PRESINI_ADJUSTED  = FLm.pres_adjusted.data';
        
        select = PRESINI~=99999 & PRESINI_ADJUSTED~=99999;
        thediff = zeros(size(PRESINI));
        thediff(select) = PRESINI_ADJUSTED(select)-PRESINI(select);
        
        if mean(libargo.meanoutnan(thediff))~=0 && ~isfield(s,'force') % if PRES_ADJUSTED is different from PRES 
            ij=find(thediff~=0 & ~isnan(thediff));
            % compute conductivity from the salinity and raw pressure
            cndr = sw_cndr(SALINI(ij),TEMPINI(ij),PRESINI(ij));
            PRESINI = PRESINI_ADJUSTED;
            pres_qc  = FLm.pres_adjusted_qc.data';
            
            % recompute the salinity from conductivity and adjusted pressure
            sal = sw_salt(cndr,TEMPINI(ij),PRESINI(ij));
            sal(isnan(sal))=NaN;
            SALINI(ij)=sal;
            disp(' ')
            disp(['INPUT: PRES_ADJUSTED, raw PSAL calibrated in pressure and TEMP'])
            disp(' ')
        else
            % presini and presadjusted are equal or data mode is R
            disp(' ')
            if isfield(s,'force')==0
            disp(['INPUT: raw PRES TEMP and PSAL'])
            end
            disp(' ')
        end
    else
        if(strcmp(s.force,'adjusted'))
            disp(' ')
            disp(['INPUT: PRES_ADJUSTED and TEMP_ADJUSTED and PSAL_ADJUSTED'])
            elseif(strcmp(s.force,'raw'))
            disp(['INPUT: raw PRES TEMP and PSAL'])
            else
            error('unknown force option ')
        end
            disp(' ')
    end
    %keyboard
    %i=find(PRESINI==2047);
    %    if length(i) > 1
    %         PRESINI(i(2)) = 2050;
    %    end
    
    % only take ascending profiles
    iu = find(direction=='A');
    jul = jul(iu);
    jul_qc = jul_qc(iu);
    PROFILE_NO = PROFILE_NO(iu);
    LAT = LAT(iu);
    LONG = LONG(iu);
    
    PRESINI = PRESINI(:,iu);
    pres_qc = pres_qc (:,iu);
    
    SALINI = SALINI(:,iu);
    psal_qc = psal_qc (:,iu);
    
    TEMPINI = TEMPINI(:,iu);
    temp_qc = temp_qc(:,iu);
    
    pos_qc = pos_qc(iu);
    
    
    disp(['Number of ascending profiles:' num2str(length(PROFILE_NO))])
    
    clear direction
    
    % Potential Temperature relative to a pressure of zero
    PTMPINI = sw_ptmp(SALINI,TEMPINI,PRESINI,0);
    
    
    
    %---------------------------------------------------------------
    % PUT DATE IN THE RIGHT FORMAT (decimal year)
    % cc 26/09/2019 corrected to deal with dates that can be FillValue 
    
    fillvalue = FLm.juld.FillValue_;
    
    date_greg   = libargo.greg_0h(jul+libargo.jul_0h(1950,01,01));
    date_greg (jul==fillvalue)= NaN; %cc 
    dates_str   = [];
    [d1 d2]     = size(date_greg);
    dates=NaN.*ones(d1,1);

    for j=1:d1;
        if(isnan(date_greg(j,:))==0)
            %dates_str = [num2str(date_greg(j,1)) num2str(datestr(date_greg(j,:),5)) num2str(datestr(date_greg(j,:),7)) num2str(datestr(date_greg(j,:),'HH')) num2str(datestr(date_greg(j,:),'MM')) num2str(datestr(date_greg(j,:),'SS'))];
            dates_str =datestr(date_greg(j,:),'yyyymmddHHMMSS');
            % dates_str = [dates_str ; dates_st];
            
            
            yr    = str2num(dates_str(1:4));
            mo    = str2num(dates_str(5:6));
            day   = str2num(dates_str(7:8));
            hr    = str2num(dates_str(9:10));
            minut = str2num(dates_str(11:12));
            if(mo<1|mo>12|day<1|day>31)
                dates(j)=yr;
            else
                dates(j)=yr+libargo.cal2dec(mo,day,hr,minut)./365;
            end
        else
            dates(j)=NaN;
        end
        
    end
    
    %---------------------------------------------------------------------------
    % Modify the detection of flag
    % Nicolas DAVID - 13/07/07
    
    for I = 1:length(jul)
        if (str2num(jul_qc(I)) > 3)
            dates(I)=NaN;
        end;
    end;
    %---------------------------------------------------------------------------
    % transposition and double
    DATES =dates';
    %LAT   = LAT';
    %LONG  = LONG';
    %PROFILE_NO = double(PROFILE_NO');
    PROFILE_NO = double(PROFILE_NO);
    %---------------------------------------------------------------
    % POSITION
    
    fillvalue = FLm.latitude.FillValue_;
    ilat      = find(LAT==fillvalue);
    fillvalue = FLm.longitude.FillValue_;
    ilon      = find(LONG==fillvalue);
    
    LAT(ilat)  = NaN;
    LONG(ilon) = NaN;
    
    jlon       = find(LONG<0);
    LONG(jlon) = LONG(jlon)+360;
    
    
    %---------------------------------------------------------------------------
    % Modify the detection of flag
    % Nicolas DAVID - 13/07/07 test: if (str2num(pos_qc(I)) > 3 )
    % Virginie THIERRY - 11/01/08 test: if (str2num(pos_qc(I)) == 4 )
    % (flag can be set to 5 = modified)
    
    % C. Lagadec - 24/11/10 : suppression du test sur le QC_POSITION
    % afin de pouvoir utiliser l'interface de correction des Netcdfde Patrice Bellec
    %for I = 1:length(LAT)
    %    if (str2num(pos_qc(I)) == 4 )
    %        LAT(I) = NaN;
    %        LONG(I)= NaN;
    %    end;
    %end;
    %---------------------------------------------------------------------------
    
    %---------------------------------------------------------------
    % MEASUREMENTS PRES-TEMP-PSAL
    
    qc = zeros(size(TEMPINI));
    
    for I = 1:length(TEMPINI(:))
        if ( str2num(pres_qc(I)) < 3 & str2num(temp_qc(I)) < 4 & str2num(psal_qc(I)) < 4 )
            qc(I) = 1;
        end
    end
    
    % Exclude dummies
    I = find( SALINI  > 50  | SALINI  <   0 | ...
        PTMPINI > 50  | PTMPINI < -10 | ...
        PRESINI >6000 | PRESINI <   0);
    qc(I) = 0;
    
    for J = 1:length(qc(:));
        if qc(J)==0;
            PRESINI(J)=NaN;
            TEMPINI(J)=NaN;
            SALINI(J) =NaN;
            PTMPINI(J)=NaN;
        end;
    end;
    
    
    % --------------------------------------------------------------
    % Virginie THIERRY - 11/01/2008
    % all pressure measurements at the same index levels
    
    tabnpt=NaN*ones(size(PROFILE_NO,2),1);
    for J = 1:size(PROFILE_NO,2)
        presvec=PRESINI(find(isfinite(PRESINI(:,J))),J);
        if isempty(presvec) ~=1
            [indlev,val]=find(PRESINI(:,J)==presvec(end));
            tabnpt(J)=indlev;
        end
    end
    
    [indlevmax,cyclevmax]=max(tabnpt);
    
    vecpresref=PRESINI(:,cyclevmax);
    
    PRES = NaN*ones(size(PRESINI));
    TEMP = NaN*ones(size(PRESINI));
    PTMP = NaN*ones(size(PRESINI));
    SAL  = NaN*ones(size(PRESINI));
    PRESREF = vecpresref*ones(1,size(PRESINI,2));
    
    tabindex1=NaN*ones(size(PRESINI));
    tabindex2=NaN*ones(size(PRESINI));
    
    for J=1:size(PROFILE_NO,2)
        
        if J == cyclevmax
            PRES(:,J)   = PRESINI(:,J);
            TEMP(:,J)   = TEMPINI(:,J);
            PTMP(:,J)   = PTMPINI(:,J);
            SAL(:,J)    = SALINI(:,J);
            tabindex1(1:indlevmax,J) = [1:indlevmax];
            tabindex2(1:indlevmax,J) = [1:indlevmax];
        else
            presvec = PRESINI(find(isfinite(PRESINI(:,J))),J);
            tempvec = TEMPINI(find(isfinite(PRESINI(:,J))),J);
            ptmpvec = PTMPINI(find(isfinite(PRESINI(:,J))),J);
            salvec  = SALINI(find(isfinite(PRESINI(:,J))),J);
            
            npres=length(presvec);
            for jk=1:npres
                absdiff=abs(vecpresref-presvec(jk));
                vmin=min(absdiff);
                [indmin]=find(absdiff==vmin);
                if length(indmin)==2
                    indlev=indmin(2);
                else
                    indlev=indmin;
                end
                
                tabindex1(indlev,J) = jk;
                tabindex2(jk,J)     = indlev;
                
                PRES(indlev,J)   = presvec(jk);
                TEMP(indlev,J)   = tempvec(jk);
                PTMP(indlev,J)   = ptmpvec(jk);
                SAL(indlev,J)    = salvec(jk);
                PRESREF(indlev,J)= presvec(jk);
            end
        end
    end
    
    PRES  = double(PRES);
    TEMP  = double(TEMP);
    PTMP  = double(PTMP);
    SAL   = double(SAL);
    
    
    %---------------------------------------------------------------
    % WRITE MAT FILE
    
    
    save(mat_filename,'DATES','LAT','LONG','PRES','TEMP','SAL','PTMP','PROFILE_NO')
end
display('________________________________________')
