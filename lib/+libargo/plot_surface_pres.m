% -========================================================
%   USAGE : [F]=plot_surface_pres(plat_name,dac,dirftp)
%   PURPOSE : plot the surface pressure from the tech file
% -----------------------------------
%   INPUT :
%     plat_name   (char)  float number
%     dac (char)          dac name    ex: 'coriolis'
%     dirftp (char)       full path   ex: '/home4/begmeil/coriolis_diffusion/ftp/co0508/dac/'
% -----------------------------------
%   OUTPUT :
%    F   (structure)
%   HISTORY  : created (2012) ccabanes
%            : modified (yyyy) byxxx
% ========================================================


function [F]=plot_surface_pres(plat_name,dac,dirftp)


dacdir=[dirftp,dac '/'];


NcVar.cycle_number.name='CYCLE_NUMBER';
NcVar.technical_parameter_name.name='TECHNICAL_PARAMETER_NAME';
NcVar.technical_parameter_value.name='TECHNICAL_PARAMETER_VALUE';
NcVar.platform_number.name='PLATFORM_NUMBER';
NcVar.format_version.name='FORMAT_VERSION';


% liste de tous les flotteurs du Dac
ff=dir(dacdir);

% trouve tous les noms de parametres techniques
nfin=0;
unique_techparam={};

plat_name=strtrim(plat_name);

filetec_name=[dacdir,plat_name,'/', plat_name '_tech.nc'];
filemet_name=[dacdir,plat_name,'/', plat_name '_meta.nc'];
fileprf_name=[dacdir,plat_name,'/', plat_name '_prof.nc'];

% Lecture du fichier meta

if exist(filemet_name)==2 % si fichier meta existe
    MET = libargo.read_netcdf_allthefile(filemet_name);
    %keyboard
    if isfield(MET,'platform_model')
    F.plat_model = strtrim(MET.platform_model.data');
    elseif isfield(MET,'platform_type')
    F.plat_model = strtrim(MET.platform_type.data');
    end
    isbug = isstrprop(F.plat_model,'cntrl');
    F.plat_model = F.plat_model(~isbug);
    F.launch_date = (MET.launch_date.data');
    F.launch_date = strtrim(F.launch_date);
    isbug = isstrprop(F.launch_date,'cntrl');
    F.launch_date = F.launch_date(~isbug);
    
    if isfield(MET,'inst_reference')==1
        F.inst_reference=strtrim(MET.inst_reference.data');
        isbug=isstrprop(F.inst_reference,'cntrl');
        F.inst_reference=F.inst_reference(~isbug);
    end
    
    if isfield(MET,'wmo_inst_type')==1
        F.wmo_tpe=strtrim(MET.wmo_inst_type.data');
        isbug=isstrprop(F.wmo_tpe,'cntrl');
        F.wmo_tpe=F.wmo_tpe(~isbug);
    end
    
    if isfield(MET,'pi_name')==1
        F.pi_name=strtrim(MET.pi_name.data');
        isbug=isstrprop(F.pi_name,'cntrl');
        F.pi_name=F.pi_name(~isbug);
    end
    
    if isfield(MET,'project_name')==1
        F.project_name=strtrim(MET.project_name.data');
        isbug=isstrprop(F.project_name,'cntrl');
        F.project_name=F.project_name(~isbug);
    end
    
else
    
    disp([strtrim(plat_name) ' :no meta file'])
    
end

% Lecture du fichier profil

if exist(fileprf_name)==2
    Ncprf.cycle_number.name='CYCLE_NUMBER';
    Ncprf.pres.name='PRES';
    PRF = libargo.read_netcdf_allthefile(fileprf_name,Ncprf);
    if isfield(PRF,'cycle_number')
        F.cycle_profile = PRF.cycle_number.data;
        F.first_level_pres =PRF.pres.data(:,1);
    else
        F.cycle_profile = [];
    end
else
    disp([strtrim(plat_name) ' :no profile file'])
end

% Lecture du fichier tech

if ~(exist(filetec_name)==2)
    disp([strtrim(plat_name) ' :no tech file'])
else
    
    TECH = libargo.read_netcdf_allthefile(filetec_name,NcVar);
    
    if isfield(TECH, 'format_version')==1
        format_version = strtrim(TECH.format_version.data');
        format_version_num = str2num(format_version);
        disp([strtrim(plat_name) ' : technical file format:' format_version])
    end
    
    if isfield(TECH,'technical_parameter_name')==0
        
        disp([strtrim(plat_name) ' : no technical_parameter_name'])
        
    else
        thetechparam = TECH.technical_parameter_name.data;
        
        if isfield(TECH,'technical_parameter_value')==0
            
            disp([strtrim(plat_name) ' : no technical_parameter_value'])
            
        else
            thetechvalue = TECH.technical_parameter_value.data;
            
            if format_version_num >= 2.3
                
                if  isfield(TECH,'cycle_number')==0
                    
                    disp([strtrim(plat_name)  ' : no cycle_number'])
                    
                else
                    cycle = TECH.cycle_number.data;
                    
                    if length(size(thetechparam))>2|isstr(thetechparam)==0
                        
                        disp([strtrim(plat_name) ' : no good format for PRES_SurfaceOffset'])
                        
                    else
                        
                        celltech = cellstr(thetechparam);
                        is_pres_cell = strfind(celltech,  'PRES_SurfaceOffset');
                        is_pres = ~cellfun('isempty',is_pres_cell);
                        unique_techparam=unique(celltech(is_pres));
                        
                        if length(unique_techparam)~=0
                            F.surface_pres = NaN*zeros(sum(is_pres),1);
                            F.cycle_fromtech=NaN*zeros(sum(is_pres),1);
                            if length(unique_techparam)>1
                                disp([strtrim(plat_name) ' : Several tech names for the surface pressure!!'])
                                unique_techparam
                            end
                            for p=1:length(unique_techparam)
                                
                                ischarcell = strfind(celltech,unique_techparam{p} );
                                isachar = ~cellfun('isempty',ischarcell);
                                thestr = thetechvalue(isachar,:);
                                celltechval=cellstr(thestr);
                                isnotempty_str = ~cellfun('isempty',celltechval);
                                
                                
                                F.surface_pres(isnotempty_str)=str2double(cellstr(thestr(isnotempty_str,:)));
                                F.cycle_fromtech(isnotempty_str)=cycle(isachar);
                                F.techparam=unique_techparam{p};
                                disp(['length(cycle from tech file): ' num2str(length(F.cycle_fromtech))])
                                
                            end
                            
                        end
                    end
                end
                
            elseif format_version_num<=2.2
                
                cycle = [1:size(TECH.technical_parameter_value.data,1)];
                
                if length(cycle)~=0
                    
                    for kcy=cycle
                        celltech = cellstr(squeeze(thetechparam(kcy,:,:)));
                        is_pres_cell1 = strfind(celltech,'PRES_SurfaceOffset');
                        is_pres_cell2=strfind(celltech,  'PRESSURE_OFFSET_');
                        is_pres_cell3=strfind(celltech,  'Surface_Pressure_');
                        is_pres = ~cellfun('isempty',is_pres_cell1)|~cellfun('isempty',is_pres_cell2)|~cellfun('isempty',is_pres_cell3);
                        unique_techparam=unique(celltech(is_pres));
                        if length(unique_techparam)~=0
                            
                            F.surface_pres = NaN*zeros(sum(is_pres),1);
                            
                            for p=1:length(unique_techparam)
                                ischarcell = strfind(celltech,unique_techparam{p} );
                                isachar = ~cellfun('isempty',ischarcell);
                                thestr = permute(thetechvalue(kcy,isachar,:),[1,3,2]);
                                celltechval=cellstr(thestr);
                                isnotempty_str = ~cellfun('isempty',celltechval);
                                
                                F.surface_pres(isnotempty_str)=str2double(cellstr(thestr(isnotempty_str,:)));
                                F.cycle_fromtech=kcy;
                                
                            end
                        end
                    end
                end
                
            else
                
                
                
            end
            
        end
    end
end




% Plot de la pression de surface
figure
hold on
subplot(2,1,1)

plot(F.cycle_fromtech ,F.surface_pres,'-+')

title(['Surface Pressure Offset for float ', plat_name, strtrim(F.techparam)],'interpreter','none')
xlabel('Cycle number')
box on
grid on

subplot(2,1,2)
plot(F.cycle_profile ,PRF.pres.data(:,1),'-+r')
title(['Pressure of the profile level closest to the surface'])
xlabel('Cycle number')
ylabel(PRF.pres.units)
box on
grid on


