function index_data = read_index_prof(index_file_name)
%-========================================================
%   USAGE : index_data = read_index_prof(index_file_name)
%   PURPOSE : read the global prof index named index_file_name.
%
% -----------------------------------
%   INPUT :
%    index_file_name : name of the global prof index file.
% -----------------------------------
% -----------------------------------
%   OUTPUT :
%    index_data : data of the colons of index_file_name.
% -----------------------------------
%   HISTORY  : created (2013) ccabanes
% Revised: 2016-10-14 (G. Maze) Update to the new index format (16 cols) and new value type conversion 
%   CALLED SUBROUTINES: none
% ========================================================
fr=fopen(index_file_name,'r');
% file,date,latitude,longitude,ocean,profiler_type,institution,
% date_update,
% profile_temp_qc,profile_psal_qc,profile_doxy_qc,
% ad_psal_adjustment_mean,ad_psal_adjustment_deviation,
% gdac_date_creation,gdac_date_update,n_levels
index_data = textscan(fr,'%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s' , 'delimiter' , ',' ,'commentStyle','#','Headerlines',9);

% transforme les longitudes latitudes   en double %  
%(il vaut mieux tout lire en %s, cela evite que textscan plante si ce qui est dans 
% le fichier index ne correspond pas a une valeur numerique)
index_data{2} = datenum(index_data{2},'yyyymmddHHMMSS'); % date
index_data{8} = datenum(index_data{8},'yyyymmddHHMMSS'); % date_update
index_data{14} = datenum(index_data{14},'yyyymmddHHMMSS'); % gdac_date_creation
index_data{15} = datenum(index_data{15},'yyyymmddHHMMSS'); % gdac_date_update
index_data{3} = str2double(index_data{3}); % Latitude
index_data{4} = str2double(index_data{4}); % Longitude
fclose(fr);

