function [liste_profile_files,liste_floats_files] = select_floats_from_index(index_data,varargin)
% -========================================================
%   USAGE : [liste_profile_files,liste_floats_files] = select_floats_from_index(index_data,varargin)
%   PURPOSE : select floats in a region from the index_file  '/home4/begmeil/coriolis_diffusion/ftp/co0508/ar_index_global_prof.txt')
% -----------------------------------
%   INPUT :
%    index_data   (structure) results from reading the index file :
%
%     % lit le fichier
%     fr=fopen([index_file_name])
%     file,date,latitude,longitude,ocean,profiler_type,institution,date_update
%     index_data = textscan(fr,'%s%s%f%f%s%s%s%s' , 'delimiter' , ',' ,'commentStyle','#');
%     fclose(fr);
%
%   OPTIONNAL INPUT :
%    'lonmin' (float) longitude min  can be [-180 180] or [0 360]
%    'lonmax' (float) longitude max  (same interval as lonmin)
%    'latmin' (float) latitude min
%    'latmax' (float) latitude max
%     'ocean' (cell of char) 'A' 'M' 'P' or 'I'  ex: {'A','P'} , 'M' is for Mediterranee, 'A' is Atlantic (without Med)
%     'datemin' (char)  date min 'yyyymmdd'  ex '20000101'
%     'datemax' (char)  date max 'yyyymmdd'  ex '20121231'
%     'type'    (cell of char)       type of float ex: {'845' '846'};
%     'exclude_type' (cell of char)  excluded type of float  ex: {'852'} solo fsi floats;
%     'centre'   (cell of char)  'AO' or 'IF' or 'BO' ... ex {'AO', 'IF'};
%     'data_mode' (char)         'R' or 'D'
% -----------------------------------
%   OUTPUT :
%     liste_profile_files   (char 1xn_prof)  file name of the selected profiles
%     liste_floats_files    (char) 1xn_float) file name of the selected floats (with at least one cycle in the selected area)
% -----------------------------------
%   HISTORY  : created (2012) ccabanes
%            : rev.1 (13/12/2016) ccabanes : make it compatible with the revision of read_index_prof.m (detailed index format with 16 col)
%            : rev.2 (13/12/2016) ccabanes : bug correction for longitude selection
%            : rev.3 (13/12/2016) ccabanes : add the possibility to select Mediterranee (M)
%   CALLED SUBROUTINES: none
% ========================================================

n=length(varargin)

if n/2~=floor(n/2)
    error('check the imput arguments')
end

f=varargin(1:2:end)
c=varargin(2:2:end)
s = cell2struct(c,f,2);



thefield = fieldnames(s);

select= logical(ones(length(index_data{1}),1));

disp([ '----- Total number of profiles : ' ,num2str(sum(select))])


allfloats.longitude.data=index_data{4};
allfloats.latitude.data=index_data{3};

allfloats.longitude.data(allfloats.longitude.data==99999)=NaN;
allfloats.latitude.data(allfloats.latitude.data==99999)=NaN;

allfloats.ocean.data=index_data{5}; % limites pour Med: TESTS TR J-P.Rannou                                                    % rev.3
ik = (allfloats.latitude.data<=40&allfloats.latitude.data>=30&allfloats.longitude.data>=-5&allfloats.longitude.data<=40);      %  |
allfloats.ocean.data(ik)={'M'};                                                                                                %  |
ik = (allfloats.latitude.data<=45&allfloats.latitude.data>=40&allfloats.longitude.data>=0&allfloats.longitude.data<=25);       %  |
allfloats.ocean.data(ik)={'M'};                                                                                                %  |
ik = (allfloats.latitude.data<=41&allfloats.latitude.data>=40&allfloats.longitude.data>=25&allfloats.longitude.data<=30);      %  |
allfloats.ocean.data(ik)={'M'};                                                                                                %  |
ik = (allfloats.latitude.data<=36.6&allfloats.latitude.data>=35.2&allfloats.longitude.data>=-5.4&allfloats.longitude.data<=-5);%  |
allfloats.ocean.data(ik)={'M'};                                                                                                %  |

for k=1:length(thefield)
    

    
    if strcmp(thefield{k},'lonmin')==1
        
         if (s.lonmin< 180)     % rev.2
            shift='grwch';      %  |
        end                     %  |
        if (s.lonmin>=180)      %  |
            shift='pacif';      %  |
        end                     %  |
        

        allfloats = libargo.shiftEW(allfloats,'longitude',shift);
        select=   select& allfloats.longitude.data>=s.lonmin;
    end
    
    if strcmp(thefield{k},'lonmax')==1
        if (s.lonmax>180)
            shift='pacif';
%        else                   % rev.2
%            shift='grwch';     %  |
        end
        allfloats = libargo.shiftEW(allfloats,'longitude',shift);
        
        select=   select & allfloats.longitude.data<=s.lonmax;
    end
    
    
    if strcmp(thefield{k},'latmin')==1
        select=   select & (allfloats.latitude.data>=s.latmin);
    end
    
    if strcmp(thefield{k},'latmax')==1
        select=   select & (allfloats.latitude.data<=s.latmax);
    end
    
    
    if strcmp(thefield{k},'ocean')==1
        %allfloats.ocean.data=index_data{5};                                    %rev. 3
        select=   select & ismember(allfloats.ocean.data,s.ocean);
    end
    
    if strcmp(thefield{k},'datemin')==1
        
        %allfloats.date.data=datenum(index_data{2},'yyyymmddHHMMSS'); % rev.1
        allfloats.date.data=index_data{2}; % rev.1
        select=   select & allfloats.date.data >= datenum(s.datemin,'yyyymmdd');
    end
    
    if strcmp(thefield{k},'datemax')==1
        
        %allfloats.date.data=datenum(index_data{2},'yyyymmddHHMMSS'); % rev.1
        allfloats.date.data=index_data{2}; % rev.1
        select=   select & allfloats.date.data <= datenum(s.datemax,'yyyymmdd');
    end
    
    if strcmp(thefield{k},'type')==1
        
        allfloats.type.data=index_data{6};
        
        select=   select & ismember(allfloats.type.data ,s.type);
    end
    if strcmp(thefield{k},'exclude_type')==1

        allfloats.type.data=index_data{6};
        
        select=   select & ~ismember(allfloats.type.data ,s.exclude_type);
    end
    
    if strcmp(thefield{k},'centre')==1
        
        allfloats.centre.data=index_data{7};
        
        select=   select & ismember(allfloats.centre.data, s.centre);
    end
    
    if strcmp(thefield{k},'data_mode')==1
        
        ischarcell = strfind(index_data{1},['/' s.data_mode] );
        ischar=~cellfun('isempty',ischarcell);
        
        select=   select & ischar;
    end
    disp(['& ' thefield{k} '  - number of profiles selected: ' ,num2str(sum(select))])
end

liste_profile_files = index_data{1}(select);

liste_floats_files=[];

for k=1:length(liste_profile_files)
    d=liste_profile_files{k};
    [t,r]=strtok(d,'/');
    [n,junk]=strtok(r,'/');
    thedac=t;
    numfloat=n;
    liste_floats_files{k}=[thedac '/' n '/' n '_prof.nc'];
end

liste_floats_files=unique(liste_floats_files)';

disp([' ___________________________________'])
disp(['  - number of floats selected: ' ,num2str(length(liste_floats_files))])



