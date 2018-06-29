function [Co]=replace_fill_bynan(Co,fillvalName)
% -========================================================
%    USAGE : [Co]=replace_fill_bynan2(Co)
%            [Co]=replace_fill_bynan2(Co,fillvalName)
%   EXAMPLE  [Co]=replace_fill_bynan2(Co,'FillValue_')
%   PURPOSE : Replace fill value by NaN if the variable is numeric (usefull for plotting purpose)
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
%            : rev.1 (13/12/2016) ccabanes : 
%   CALLED SUBROUTINES: none
% ========================================================

if nargin==1
    fillvalName='FillValue_';
end
champs = fieldnames(Co);    %champs={'psal','psalqc','psalad',....}
Nbfields = length(champs);
gotoend=0;
if isfield(Co, 'fillisnan')
    if Co.fillisnan==1
%        gotoend=1;
    end
end

if gotoend==0
    for k=1:Nbfields            % boucle sur toutes les variables
        oneChamp=champs{k};
        if isfield(Co.(oneChamp),'data')
            if isempty(Co.(oneChamp).data)==0    % test si la variable n'est pas vide
                if isnumeric(Co.(oneChamp).data)==1   % test si la variable est un tableau numerique
                    
                    %if isempty(Co.(oneChamp).(fillvalName))==0   % test si il y a une fillvalue pour cette variable
                    if isfield(Co.(oneChamp), [fillvalName])==1
                        if isempty(Co.(oneChamp).(fillvalName))==0
                            selec_fill = ( Co.(oneChamp).data == Co.(oneChamp).(fillvalName));
                            
                            if isfloat(Co.(oneChamp).data)==1                                      % rev.1
                               Co.(oneChamp).data(selec_fill) = NaN;                               %  |
                            end                                                                    %  |
                            if Co.(oneChamp).type==4 % si c'est un entier                          %  |
                            %la fonction NaN nest pas definie pour les entiers => renvoie 0, on convertit donc le champ en single(float). 
                            %La conversion inverse (int32) est faite dans la fonction replace_nan_byfill.m)
                               Co.(oneChamp).data = single(Co.(oneChamp).data);                    %  |
                               Co.(oneChamp).(fillvalName) = single(Co.(oneChamp).(fillvalName));  %  |
                               Co.(oneChamp).data(selec_fill) = NaN;                               %  |
                            end
                            Co.fillisnan=1;
                        else
                            warning(['Did not find a fillvalue attribute for ' oneChamp])
                        end
                    else
                        warning(['Did not find a fillvalue attribute for ' oneChamp])
                    end
                end
            end
        end
    end
end


