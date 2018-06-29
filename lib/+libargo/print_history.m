function print_history(filename)
% -========================================================
%   USAGE :   print_history(filename) single profile file
%   PURPOSE : Print the history of the QC performed on an Argo profile (history is only available in the profile files (single cycle) but not in the multi-profiles files)
% -----------------------------------
%   INPUT :
%     filename   (string)  - Argo file name-
% -----------------------------------
%   OUTPUT : printed
%
% -----------------------------------
%   HISTORY  : created (2013) ccabanes
%            : modified(15/12/2016) ccabanes : take into account Near surface tests, and several profiles (core, near surface,...) in the file
%   CALLED SUBROUTINES: read_netcdf_allthefile
% ========================================================

% read the netcdf file
[Co,Dim] = libargo.read_netcdf_allthefile(filename);



if Dim.n_prof.dimlength>1
   disp('Multi profile file')
end

for ik=1:Dim.n_prof.dimlength
    profile_number=ik;

    % binary ID for real time QC tests (reference table 11, Argo user manual)
    binID=[2;4;8;16;32;64;128;256;512;1024;2048;4096;8192;16384;32768;65536;131072;261144;524288;1044576;2097152;4194304];

    % name of the real time QC tests (reference table 11, Argo user manual)
    RQC_name={'Platform identification test';'Impossible Date Test';'Impossible Location Test';'Position on Land test';'Impossible Speed test';'Global Range test';'Regional Global Parameter test';'Pressure increasing test';'Spike test';'Top and bottom spike test (obsolete)';'Gradient test';'Digit rollover test';'Stuck value test';'Density inversion test';'Grey list test'; 'Gross salinity or temperature sensor drift test';'Visual qc test';'Frozen profile test';'Deepest pressure test';'Questionable Argos position test';'Near-surface unpumped CTD salinity test'; 'Near-surface mixed air/water test'};
    disp(' ')
    disp(' ')
    disp('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++')
    disp(['PLATFORM NUMBER: ' strtrim(Co.platform_number.data(profile_number,:))])
    disp(['CYCLE NUMBER: ' num2str(Co.cycle_number.data(profile_number)) ' ' Co.direction.data(profile_number)])
    disp(['PROFILE NUMBER: ' num2str(ik) ' ' Co.vertical_sampling_scheme.data(profile_number,:)])
    disp('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++')
    disp(' ')
    disp(' ')

    for k=1:Dim.n_history.dimlength
        
        % HISTORY_DATE
        thedate = (squeeze(Co.history_date.data(k,profile_number,:)))';
        thedatenum(k) = datenum(thedate,'yyyymmddHHMMSS');
        
    end
    [sortdate,isort]=sort(thedatenum);

    for k=[isort]
        
        % HISTORY_DATE
        thedate = (squeeze(Co.history_date.data(k,profile_number,:)))';
        thedatevec = datevec(thedate,'yyyymmddHHMMSS');
        thedatestr = datestr(thedatevec,'dd/mm/yyyy');
        
        
        % HISTORY_SOFTWARE
        software=squeeze(Co.history_software.data(k,profile_number,:))';
        
        if strcmp(strtrim(software),'COAR')
            software= 'COAR (real time tests) ';
        end
        
        if strcmp(strtrim(software),'COOA')
            software= 'COOA (Coriolis Objective Analysis test) ';
        end
        
        if strcmp(strtrim(software),'SCOO')
            software= 'SCOOP ';
        end
        
        
        % HISTORY QC_TEST
        total = hex2dec(squeeze(Co.history_qctest.data(k,profile_number,:))');
        totala= total;
        % find the real time tests corresponding to the hex code
        add=[];
        if strcmp(software,'COAR (real time tests) ')|strcmp(software,'COQC')
            
            ikl=1;
            %keyboard
            while total>0
                % trouve le binID le plus proche
                [soustotal,isort] = sort(total-binID);
                ik = find(soustotal<0);
                soustotal(ik)=NaN;
                [mins,is]=min(soustotal);
                % index des tests concernes
                add(ikl)=isort(is);
                total=total-binID(isort(is));
                ikl=ikl+1;
            end
        end
        % HISTORY_ACTION
        action=squeeze(Co.history_action.data(k,profile_number,:))';
        
        %  traduction of the action codes  (reference table 7, Argo user manual)
        if strcmp(strtrim(action),'QCP$')
            action=' THESE TESTS WERE PERFORMED ';
        end
        
        if strcmp(strtrim(action),'QCF$')
            action= ' THESE TESTS FAILED ';
        end
        
        if strcmp(strtrim(action),'QC')
            action= ' VISUAL QUALITY CONTROL ';
        end
        
        if strcmp(strtrim(action),'CF')
            action= ' FLAG WERE CHANGED ';
        end

        % HISTORY_PARAMETER
        parameter=squeeze(Co.history_parameter.data(k,profile_number,:))';
        previous_value=squeeze(Co.history_previous_value.data(k,profile_number,:))';
        start_pres=squeeze(Co.history_start_pres.data(k,profile_number,:))';
        stop_pres=squeeze(Co.history_stop_pres.data(k,profile_number,:))';
        
        if previous_value==Co.history_previous_value.FillValue_
            previous_value=[];
        end
        if start_pres==Co.history_start_pres.FillValue_
            start_pres=[];
        end
        if stop_pres==Co.history_stop_pres.FillValue_
            stop_pres=[];
        end
        
        
        
        % PRINT ON SCREEN
        
        
        
        disp('---------------------------------------------------')
        disp(['On ' thedatestr ': ' action  ' using the software: ' software] )
        
        
        if isempty(previous_value)==0
            disp([' Action on: ' strtrim(parameter) ', Old flag value: ' num2str(previous_value) ', at pressures: ' num2str(start_pres) ':' num2str(stop_pres)])
        end
        
        %disp(totala)
        for l=1:length(add)
            disp(RQC_name{add(l)})
        end
        
        disp(' ')
        
    end

end