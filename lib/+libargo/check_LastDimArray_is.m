function [Co]=check_LastDimArray_is(Co,DIMNAME)
% -========================================================
%  [Co]=LastDimArray(Co,DIMNAME)
%   PURPOSE : check that the last dimension of all the array in the
%   structure Co are the same and DIMNANE
%   and change dimension order if necessary
% -----------------------------------
%   INPUT :
%     Co   (structure)  float structure
%     DIMNAME   (char)  dimension name ex: 'N_PROF'
% -----------------------------------
%   OUTPUT :
%     Co   (strucure)  -float structure with the DIMNAME dimension in the last place for all
%     the arrays
%     Co.lastdimname    ex: Co.firstdimname='N_PROF';
% -----------------------------------
%   HISTORY  : created (2009) ccabanes
%            : modified (yyyy) byxxx
%   CALLED SUBROUTINES: none
% ========================================================


lowname=lower(DIMNAME);


gotoend=0;
if isfield(Co,'firstdimname')
    if strcmp(Co.firstdimname,DIMNAME)==1
        gotoend=1;
    end
end

champs = fieldnames(Co);    %champs={'psal','psalqc','psalad',....}
Nbfields = length(champs);
testonechange=0;
Co.(lowname)=0;
for k=1:Nbfields            % boucle sur toutes les variables
    oneChamp=champs{k};
    if isfield(Co.(oneChamp),'data')
        %if isempty(Co.(oneChamp).data)==0
        if isfield(Co.(oneChamp),'dim')
            isthedim=strcmp(Co.(oneChamp).dim,DIMNAME);
            if sum(isthedim)==1
                testonechange=1;
                if gotoend==0
                    vecdim=[1:length(isthedim)];
                    
                    %vecdim(1)=vecdim(isthedim);
                    %vecdim(isthedim)=1;
                    %oneChamp
                    % shift circulaire plutot
                    %keyboard
                    vecdim_sauv = vecdim;
                    vecdim = circshift(vecdim,[1,vecdim(isthedim)-1]);
                    
                    %sauv=Co.(oneChamp).dim{1};
                    %Co.(oneChamp).dim{1}=DIMNAME;
                    %Co.(oneChamp).dim{isthedim}=sauv;
                    Co.(oneChamp).dim = circshift(Co.(oneChamp).dim,[1,vecdim_sauv(isthedim)-1]);
                    
                    if length(vecdim)>1
                        Co.(oneChamp).data=permute(Co.(oneChamp).data,vecdim);
                    else
                        if size(Co.(oneChamp).data,2)>1
                            Co.(oneChamp).data=Co.(oneChamp).data';
                        end
                    end
                    
                    % Sauvegarde la premiere dimension
                    if isempty(Co.(oneChamp).data)==0
                        Co.(lowname)=size(Co.(oneChamp).data,1);
                    end
                else
                    lowname=lower(DIMNAME);
                    if isempty(Co.(oneChamp).data)==0
                        Co.(lowname)=size(Co.(oneChamp).data,1);
                    end
                end
            end
        end
        %else
        %disp(oneChamp)
        %
        %end
    end
end


if testonechange==0
    %disp(['Does not find this dimension: ',DIMNAME])
    
else
    Co.lastdimname=DIMNAME;
    if isfield(Co,'firstdimname')
       Co=rmfield(Co,'firstdimname')
    end
end