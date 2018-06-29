function Test=shiftEW(Co,onechamp,shift)
% -========================================================
%   USAGE : [Test]=shiftEW(Co,onechamp,shift)
%   PURPOSE : permute longitude [0->360] to [-180->180] if shift ='grwch'
%                               or [-180->180] to[0->360] if shift='pacif'
% -----------------------------------
%   INPUT :
%     Co   (structure)  float structure
%    onechamp  (char)   ex 'longitude'
%    shift      (char)  'grwch' or 'pacif' 
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


Test=Co;

if isfield(Co,onechamp)
    if isfield(Co.(onechamp),'data')
        if isempty(Co.(onechamp).data)==0
            if strcmp(shift,'pacif')
                lon=Co.(onechamp).data;
                junk=find(lon<0);
                lon(junk)=360+Co.(onechamp).data(junk);
                Co.(onechamp).data=lon;
                Co.shift='pacif';
            end
            if strcmp(shift,'pacif_atl')
                lon=Co.(onechamp).data;
                junk=find(lon<0);
                lon(junk)=360+Co.(onechamp).data(junk);
                junk=find(lon>=0&lon<180);
                lon(junk)=360+Co.(onechamp).data(junk);
                Co.(onechamp).data=lon;
                Co.shift='pacif_atl';
            end
            if strcmp(shift,'grwch')
                lon=Co.(onechamp).data;
                junk=find(lon>180);
                lon(junk)=-(360-Co.(onechamp).data(junk));
                Co.(onechamp).data=lon;
                Co.shift='grwch';
            end
        end
    end
end
Test=Co;
