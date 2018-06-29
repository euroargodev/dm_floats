function [Coi,Dimi]=extract_profile_dim(Co,Dim,DIMNAME,iprofiles)
% -========================================================
%   USAGE : [Coi]=extract_profile_dim(Co,Dim,DIMNAME,iprofiles)
%   PURPOSE : extract one or more profiles or one or more levels
% -----------------------------------
%   INPUT :
%     Co   (structure)  float data structure
%    Dim   (structure)  float dimension structure (see read_netcdf_allthefile.m)
%    DIMNAME (char)     dimension name (ex: 'N_PROF' or 'N_LEVELS')
%    iprofiles (1xn)    profile  to extract ex:[1:3,5] or logical[1 1 1 0 1]
% -----------------------------------
%   OUTPUT :
%     Coi   (structure)  -float data structure (extraction)
%     Dim   (structure)   float dimension structure
% -----------------------------------
%   HISTORY  : created (2009) ccabanes
%            : modified (yyyy) byxxx
%   CALLED SUBROUTINES: none
% ========================================================
if isempty(strfind(Co.obj,'ObsInSitu'))
    error('extract_profile not define for this type of structure')
else
    INITFIRSTDIM=[];
    if isfield(Co,'firstdimname')
        INITFIRSTDIM=Co.firstdimname;
    else
        INITFIRSTDIM='N_HISTORY';
    end
    Co = libargo.check_FirstDimArray_is(Co,DIMNAME);
    Coi=Co;
    Dimi=Dim;
    
    champs = fieldnames(Co);    %champs={'psal','psalqc','psalad',....}
    Nbfields = length(champs);
    
    for k=1:Nbfields            % boucle sur toutes les variables
        oneChamp=champs{k};
        if isfield(Co.(oneChamp),'data')
            if isempty(Co.(oneChamp).data)==0
                isthedim=strcmp(Co.(oneChamp).dim,DIMNAME);
                if sum(isthedim)==1
                    nbdim = length(size(Coi.(oneChamp).data));
                    ap='';
                    if nbdim>1
                        ap=repmat(',:',[1,nbdim-1]);
                    end
                    expre=['Coi.(oneChamp).data=Co.(oneChamp).data(iprofiles' ap ');'];
                    eval(expre);
                    %Coi.(oneChamp).data=Co.(oneChamp).data(iprofiles,:);
                end
            end
        end
    end
    dimnamei=fieldnames(Dimi);
    for k=1:length(dimnamei)
        if strcmp(dimnamei{k},lower(DIMNAME))==1 % dimension selon laquelle les champs sont extraits
            if islogical(iprofiles)==0
                Dimi.(dimnamei{k}).dimlength=length(iprofiles);
            else
                Dimi.(dimnamei{k}).dimlength=sum(iprofiles);
            end
        end
    end
    Coi = libargo.check_FirstDimArray_is(Coi,DIMNAME);
    if isempty(INITFIRSTDIM)==0
        Coi = libargo.check_FirstDimArray_is(Coi,INITFIRSTDIM);
    end
end
