function [Test]=check_isfillval_prof(Co,onechamp,fillval,Test)
% -========================================================
%   USAGE : [Test]=check_isfillval_prof(Co,onechamp,fillval,Test)
%           [Test]=check_isfillval_prof(Co,onechamp)
%           [Test]=check_isfillval_prof(Co,onechamp,fillval)
%           [Test]=check_isfillval_prof(Co,onechamp,Test)
%   PURPOSE : Determine if all the data in Co are equal to the FillValue
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
%            :  rev.1 (13/12/2016) ccabanes :correction bug
%   CALLED SUBROUTINES: none
% ========================================================

% champs=fieldnames(Co);
% Test qui determine si tous les niveaux sont fillvall pour un parametre donne
% Test=1 si tout les niveaux sont a fillval
% Test=0 autrement (au moins un niveau valide)

Test=[];
if nargin==2
    Test=[];
    fillval='FillValue_';
end

if nargin==3
     if ischar(fillval);              %rev.1
        Test=[];                      %  |
    else                              %  |
        if isstruct(fillval)
        Test=fillval;
        fillval='FillValue_';
        else
        Test=[];
        fillval='FillValue_';
        end
    end
end

if isfield(Co,'fillisnan')
    if Co.fillisnan==1
        Co = libargo.replace_nan_byfill(Co);
    end
end

 Co = libargo.check_FirstDimArray_is(Co,'N_PROF');

 if isfield(Co,onechamp)
     Test.(onechamp)=[];
     if isfield(Co.(onechamp),'data')
         if length(Co.(onechamp).dim)==2 && strcmp(Co.(onechamp).dim{1},'N_PROF') && strcmp(Co.(onechamp).dim{2},'N_LEVELS')
             if isempty(Co.(onechamp).data)==0
                 Test.(onechamp)= logical(ones(size(Co.(onechamp).data,1),1));
                 if isempty(Co.(onechamp).(fillval))==0
                     Test.(onechamp)= sum(Co.(onechamp).data==Co.(onechamp).(fillval),2)==size(Co.(onechamp).data,2);
                 else
                     Test.(onechamp)=[];
                 end
             end
         end
     end
 end
 
 
 
