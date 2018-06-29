function Test=count_valid(Co,onechamp)
% -========================================================
%   USAGE : Test=count_valid(Co,onechamp)
%   PURPOSE : count the number of valid profiles (valid=> at least one level ~= fillvalue or nan) 
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
%            : modified (yyyy) byxxx
%   CALLED SUBROUTINES: none
% ========================================================


Test=[];
if isfield(Co,'fillisnan')
    if Co.fillisnan==1
        Co = libargo.replace_nan_byfill(Co);
    end
end

Co = libargo.check_FirstDimArray_is(Co,'N_PROF');

if isfield(Co.(onechamp),'data')
    if isempty(Co.(onechamp).data)==0
        if length(Co.(onechamp).dim)==2 && strcmp(Co.(onechamp).dim{1},'N_PROF') && strcmp(Co.(onechamp).dim{2},'N_LEVELS')
            
            Test= logical(zeros(size(Co.(onechamp).data,1),1));
            if isempty(Co.(onechamp).FillValue_)==0
                Test= sum(Co.(onechamp).data~=Co.(onechamp).FillValue_,2);
            end
        end
    end
end
