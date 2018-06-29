function [Co]=replace_nan_by_fill(Co,fillvalName)
% -========================================================
%   USAGE : [Co]=replace_nan_by_fill(Co)
%           [Co]=replace_nan_by_fill(Co,fillvalName)
%
%   PURPOSE : Replace NaN value by fill if the variable is numeric (usefull before creating a file )
% -----------------------------------
%   INPUT :
%     IN1   (class)  -comments-
%             additional description
%     IN2   (class)  -comments-
%
%   OPTIONNAL INPUT :
%    OPTION1  (class)  -comments-
% -----------------------------------
%   OUTPUT :
%     OUT1   (class)  -comments-
%             additional description
%     OUT2   (class)  -comments-
%             additional description
% -----------------------------------
%   HISTORY  : created (2009) ccabanes
%            : rev.1 (15/12/2016) ccabanes
%   CALLED SUBROUTINES: none
% ========================================================

if nargin==1
    fillvalName='FillValue_';
end
champs = fieldnames(Co);    %champs={'psal','psalqc','psalad',....}
Nbfields = length(champs);
gotoend=0;
if isfield(Co, 'fillisnan')
    if Co.fillisnan==0
%        gotoend=1;
    end
end

if gotoend==0
    for k=1:Nbfields            % boucle sur toutes les variables
        
        oneChamp=champs{k};
        if isfield(Co.(oneChamp),'data')
            if isempty(Co.(oneChamp).data)==0    % test si la variable n'est pas vide
                
                if isnumeric(Co.(oneChamp).data)==1   % test si la variable est un tableau numerique
                    
                    if isempty(Co.(oneChamp).(fillvalName))==0   % test si il y a une fillvalue pour cette variable
                        
                        selec_fill = isnan( Co.(oneChamp).data);
                        %keyboard
                        if isfloat(Co.(oneChamp).data)==1                                              % rev1.
                        Co.(oneChamp).data(selec_fill) = Co.(oneChamp).(fillvalName);                  %  |
                        end                                                                            %  |
                        if Co.(oneChamp).type==4                                                       %  |
                        % si le type initial est "entier": % si c'est un entier (int32) : la fonction NaN nest pas definie pour les entiers => renvoie 0
                        % on a donc convertit  le champ en single(float) avec la fonction replace_fill_bynan.m  La conversion inverse (int32) est faite ici.
                            Co.(oneChamp).data = int32(Co.(oneChamp).data);                            %  |
                            Co.(oneChamp).(fillvalName) = int32(Co.(oneChamp).(fillvalName));          %  |
                            Co.(oneChamp).data(selec_fill) = Co.(oneChamp).(fillvalName);              %  |
                        end
                        Co.fillisnan=0;
                    else
                        warning([oneChamp ': Did not find a fillvalue attribute'])
                    end
                end
            end
        end
    end
end
