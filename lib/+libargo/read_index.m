function info_index = read_index(fic_index)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Fonction MATLAB permettant de lire un fichier index ARGO.
%
% En entree : nom du fichier index
% En sortie : structure comportant les informations du fichier.
%
% Creation : C. Kermabon le 06/12/2013
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%tic
fid = fopen(fic_index,'r');
if (fid<0)
    fprintf('Fichier %s inexistant\nArret');
    return;
end    
ligne = fgets(fid);
while (strcmp(ligne(1),'#'))
    ligne = fgets(fid);
end
%
% Lecture des parametres associes aux colonnes du fichier.
%
nb_param = length(strfind(ligne,','))+1;
format_lect = '%s ';
for i_ind=1:nb_param-1
    format_lect = strcat(format_lect,'%s ');
end
liste_param = textscan(ligne,format_lect,'delimiter',',');
valeur=textscan(fid,format_lect,Inf,'delimiter',',');
for i_ind =1:nb_param
    chaine = sprintf('info_index.%s=valeur{i_ind};',char(liste_param{i_ind}));
    eval(chaine);
end
fclose(fid);
%toc
end

