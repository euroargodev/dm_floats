%   MAIN_test_routine.m
%   PURPOSE : test des routines de la Lib
% -----------------------------------
% -----------------------------------
%   HISTORY  : created (2009) ccabanes
%            : modified (2013) by ccabanes
%   CALLED SUBROUTINES:
% ========================================================

function MAIN_test_routine

clear all
close all



% Lit l'index et selectionne des profils ou flotteurs

index_file_name='/home1/triagoz/matlab/outils_matlab/argo_lpo/+libargo/ar_index_global_prof_tst.txt';
%file,date,latitude,longitude,ocean,profiler_type,institution,date_update
index_data = libargo.read_index_prof(index_file_name);

[liste_profile_files,liste_floats_files] = libargo.select_floats_from_index(index_data,'lonmin',-70, 'lonmax', 10, 'latmin',30, 'latmax', 70 ,'ocean','A','exclude_type',{'852'},'data_mode','D');



% Lit un fichier Argo multiprofil
%--------------------------------------------------------------------------------------------
floatname = '5902269';
dacname = 'coriolis';

DIRFTP = '/home4/begmeil/coriolis_diffusion/ftp/co0508/dac/';

FILENAME = [DIRFTP dacname '/' floatname '/' floatname '_prof.nc'];


% lit le fichier en entier
FL = libargo.read_netcdf_allthefile(FILENAME);

% on peut aussi recuperer les dimensions et les attributs globaux
[FL,Dim,Globatt]=libargo.read_netcdf_allthefile(FILENAME);


% lit seulement quelques paramètres:
% (ici ont lit PSAL, TEMP, PRES et PSAL_QC TEMP_QC et PRES_QC :)
Param.psal.name = 'PSAL';
Param.temp.name = 'TEMP';
Param.pres.name = 'PRES';
Param.psal_qc.name = 'PSAL_QC';
Param.temp_qc.name = 'TEMP_QC';
Param.pres_qc.name = 'PRES_QC';

FL2 = libargo.read_netcdf_allthefile(FILENAME,Param);
% ou
[FL2, Dim2] = libargo.read_netcdf_allthefile(FILENAME,Param);



FL_sauv=FL;

%
% Remplace les valeurs = valeur à defaut par des NaN (si valeurs par defaut sont numériques)
%--------------------------------------------------------------------------------------------
FL = libargo.replace_fill_bynan(FL);
% FL2.psal.data contient des NAN
FL.psal.data
% FL2.psal_qc.data ne contient pas des NAN (valeur par default non numeriques)
FL.psal_qc.data

% revient en arrière
FL = libargo.replace_nan_byfill(FL);

isequal(FL,FL_sauv)


% Formate les quality flags chaine char -> tableau numerique
%--------------------------------------------------------------------------------------------
FL = libargo.format_flags_char2num(FL);


FL = libargo.replace_fill_bynan(FL);
% FL.psal.data contient des NAN
FL.psal.data
% FL.psal_qc.data  contient  des NAN
FL.psal_qc.data


% Verifie si chaque profil de salinité a au moins une valeur differente de FillValue (ou NaN) sur la verticale
%--------------------------------------------------------------------------------------------
isallFillValue = libargo.check_isfillval_prof(FL,'psal');
sauv = FL.psal.data(10,:);
FL.psal.data(10,:) = NaN;
isallFillValue = libargo.check_isfillval_prof(FL,'psal');

FL.psal.data(10,:) = sauv;

% compte le nombre de niveau differents de FillValue (ou NaN) sur la verticale pour chaque profils
count = libargo.count_valid(FL,'psal');


% Remplace les donnees TR par les donnees  adjusted si elles existent
%--------------------------------------------------------------------------------------------
% pour les parametres pres temp et psal

FL_best = libargo.construct_best_param(FL,{'psal','pres','temp'})

% On peut tracer les diags  pour le profil no 2
%--------------------------------------------------------------------------------------------

% ex: plot P,T et P,S avec les valeurs des flags en couleur


nprof=2;

figure

subplot(1,2,1)
thetitle = libargo.plot_profile_with_flag(FL,'temp','pres',nprof);

subplot(1,2,2)
libargo.plot_profile_with_flag(FL,'psal','pres',nprof);

title(thetitle)


% ex: trajectoire du flotteur sur une carte avec bathy
% par defaut , on trace en couleur le numero de cycle  le long de la trajectoire

libargo.plot_traj_atlantique(FL)

% tracer les salinites du premier niveau le long de la trajectoire
[thetitle] = libargo.plot_traj_atlantique(FL, FL.psal.data(:,1))

[thetitle] = [' Salinity of the first level (' thetitle ')' ];title(thetitle);

% Enleve ou extrait un profil du fichier multiprofil
%--------------------------------------------------------------------------------------------

% enleve le premier profil nprof= 1
Dim.n_prof

[FL_ex,Dim_ex] = libargo.remove_profile_dim(FL,Dim,'N_PROF',1);

Dim_ex.n_prof


% extrait le profil nprof= 3

[FL_ex,Dim_ex] = libargo.extract_profile_dim(FL,Dim,'N_PROF',3);


% extrait les profils nprof=[3:10];
[FL_ex,Dim_ex] = libargo.extract_profile_dim(FL,Dim,'N_PROF',[3:10]);

% extrait le premier niveau vertical n_levels=1 de chaque profil;
[FL_surf,Dim_surf] = libargo.extract_profile_dim(FL,Dim,'N_LEVELS',[1]);

% Cree un nouveau  fichier netcdf à partir des profils extraits
%--------------------------------------------------------------------------------------------

% verifie que la premiere dimension des tableaux est N_HISTORY

FL_ex = libargo.check_FirstDimArray_is(FL_ex,'N_HISTORY')

% cree le fichier netcdf
libargo.create_netcdf_allthefile(FL_ex,Dim_ex,'toto.nc',Globatt)
%ou
libargo.create_netcdf_allthefile(FL_ex,Dim_ex,'toto.nc') % sans les attributs globaux


% Concatene deux fichiers
%--------------------------------------------------------------------------------------------
[FL1,Dim1] = libargo.read_netcdf_allthefile([DIRFTP 'coriolis/5902269/profiles/D5902269_001.nc']);
[FL2,Dim2] = libargo.read_netcdf_allthefile([DIRFTP 'coriolis/5902269/profiles/D5902269_002.nc']);


[FL12,Dim12]=libargo.cat_profile_dim(FL1,FL2,Dim1,Dim2,'N_PROF'); % on concatene selon la dimension N_PROF

% verifie que la premiere dimension des tableaux est bien N_HISTORY

FL12 = libargo.check_FirstDimArray_is(FL12,'N_HISTORY')

% cree le fichier netcdf
libargo.create_netcdf_allthefile(FL12,Dim12,'toto.nc',Globatt)



% AUTRES FONCTIONS




% retrouve l'historique des modifications de flags pour les fichiers simple profil (dans les variables HISTORY) et l'ecrit de façon plus lisible
%%--------------------------------------------------------------------------------------------

libargo.print_history([DIRFTP 'coriolis/5902269/profiles/D5902269_001.nc'])


% trace les pressions de surface pour un flotteur
%%--------------------------------------------------------------------------------------------

[F] = libargo.plot_surface_pres('5902269','coriolis',DIRFTP)

end % end fonction









