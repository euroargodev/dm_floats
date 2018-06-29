function [S,Dim,Globatt]=read_netcdf_allthefile(Ficname,VarIN,verbose)
% -========================================================
%   USAGE : [S,Dim,Globatt]=read_netcdf_allthefile(Ficname,verbose)
%   PURPOSE : read all variables and attributes from netcdf files (ObsINSITU)
%           [S,Dim,Globatt]=read_netcdf_allthefile(Ficname,VarIN,verbose)
%           read variables in VarIN only
% -----------------------------------
%   INPUT :
%     Ficname   (string)  name of the file             'filetoread.nc'
%
%   OPTIONNAL INPUT :                                   ex: To read only pression and temperature in the file
%    VarIN  (structure)  name of variables to read       VarIN.pres.name = 'PRES';
%                                                        VarIN.temp.name ='TEMP';
%                        by default read all variables
%    verbose (scalar)    0 (default),  1 print to screen
% -----------------------------------
%   OUTPUT :
%    S (structure)
%        The structure S contains all info found in the netcdf file for the variable (including attributes), plus:
%        S.(lower(varname)).name   (string)   variable name       S.temperature.name = 'TEMPERATURE'
%        S.(lower(varname)).dim    (cell array of string)         S.temperature.dim  = {'N_PROF','N_LEVEL'}
%        S.(lower(varname)).data        (array)                   S.temperature.data =  n_prof x n_level value of temperature
%
%     Dim   (structure)
%        The structure Dim contains dimension info found in the netcdf file
%         Dim.n_prof.name = 'N_PROF'   (name of the dimension)
%         Dim.n_prof.dimlength  = 88   (length of the dimension)
%
%     Globatt  (structure)
%        The structure Globatt contains all the global attributes found in the netcdf file
% -----------------------------------
%   HISTORY  : created (2009) ccabanes
%            : modified (avril 2010) ccabanes for matlab  with native netcdf
%            : rev.1    (13/10/2016) ccabanes: bug correction
%   CALLED SUBROUTINES: none
% ========================================================

if nargin==1
    verbose=0;
    VarIN=[];
end

if nargin==2
    if isstruct(VarIN)==1
        verbose=0;
    else
        verbose=VarIN;
        VarIN=[];
    end
end

% ATTENTION : matlab(ou fortran F) et C gere differemment les dimensions
% C: X(t,z,y,x), unlimitted est la 1 ere dimension
% Matlab: X(x,y,z,t) unlimitted est la derniere dimension
% si on fait ncdump d'un fichier netcdf, les dimensions sont ordonnees selon C
% la librairie netcdf de matlab inverse l'ordre des dimensions
%=> ICI on rearrange les variables chargees pour que les dimensions soient ordonnees selon C (identique a ce qu'on obtient lorsqu'on fait ncdump du fichier)

S.dimorder='C';  % indique que les dimensions sont ordonnees selon C (i.e unlimitted est la 1 ere dimension) dans la structure S
% cette option est preferee car meme ordre des dimensions dans la structure S que ce qui est obtenu en faisant ncdump du fichier

% S.dimorder='F' si unlimitted est la derniere dimension

% Noms possibles pour l'attribute _FillValue (permet de gerer des fichiers qui ne respectent pas tout a fait les convention CF pour cet attribut

poss_fillval_name = {'FillValue','FillValue_','_FillValue','_fillvalue','fillvalue','missing_value'};

% 1. Open the netcdf file
% ---------------------------------------------------------------------------

nc=netcdf.open(Ficname, 'NC_NOWRITE');


% recupere les informations du fichiers
% Nbdims, nombre de dimensions
% Nbfields, nombre de champs
% Nbglob, nombre d'attributs globaux
% theRecdimID, Id de la dimension unlimitted

[Nbdims, Nbfields, Nbglob, theRecdimID] = netcdf.inq(nc);

% recupere toutes les dimensions dans la structure Dim
Dim=[];
for kd=1:Nbdims
    [namedim, dimlen] = netcdf.inqDim(nc,kd-1);
    onedim =lower(namedim);
    Dim.(onedim).name = namedim;
    Dim.(onedim).dimlength = dimlen;
end

% recupere tous les global attributes dans la structure Globatt
Globatt=[];
if nargout==3
    for kd=1:Nbglob
        nameatt = netcdf.inqAttName(nc,netcdf.getConstant('NC_GLOBAL'),kd-1);
        try
        Globatt.(nameatt).att = netcdf.getAtt(nc,netcdf.getConstant('NC_GLOBAL'),nameatt);
        Globatt.(nameatt).name = nameatt;
        catch
        warning('error when loading global attributes: skip')
        end
    end
end
% Determine quelle sont les variables à lire (parametre VarIN de la fonction)

% trouve d'abbord le nom de toutes les variables du fichier netcdf
kread = [1:Nbfields];
for k=kread
    [varname] = netcdf.inqVar(nc,k-1);
    allvar{k}=varname;
end

% compare aux noms contenus dans VarIN pour redefinir kread
inb=0;
if isempty(VarIN)==0
    tempo=fieldnames(VarIN);
    for nb=1:length(tempo)
        if isfield(VarIN.(tempo{nb}),'name')
            inb=inb+1;
            varTOretrieve{inb}=VarIN.(tempo{nb}).name;
        end
    end
    [com,ia,ib]=intersect(allvar,varTOretrieve);
    kread=kread(ia);
end


% 2. Fill the structure S for each variable
% ---------------------------------------------------------------------------

count_alldim=0;

alldim={};       % rev.1

for k=kread      % boucle sur les varaibles a lire dans le fichier
    
    % on recupere les info sur la variable (repere par l'indice)
    varid = netcdf.inqVarID(nc,allvar{k});
    [VarName,xtype,dimids,natts] = netcdf.inqVar(nc,varid);
    
    oneChamp=lower(VarName);
    
    % => initialisation de la structure S :tableau vide
    S.(oneChamp).name=VarName;
    S.(oneChamp).dim=[];
    S.(oneChamp).data=[];
    
    
    
    
    vecdim=[];
    
    % Recherche tous les attributs de la variable
    clear name_att
    for iat=1:natts
        % recupere le nom des attributs de la variable
        attid=iat-1;
        name_att{iat} = netcdf.inqAttName(nc,varid,attid);
        
        % recupere la valeur de l'attribut
        
        % cherche d'abord s'il s'agit de l'attribut _FillValue (ou autre nom non CF parmis poss_fillval_name )
        isthefil=0;
        for ipos=1:length(poss_fillval_name)
            if strcmp(name_att{iat},poss_fillval_name{ipos});
                isthefil=1;
            end
        end
        if isthefil==0
            S.(oneChamp).(name_att{iat}) = netcdf.getAtt(nc,varid,name_att{iat} );
        else
            S.(oneChamp).FillValue_= netcdf.getAtt(nc,varid,name_att{iat} );
        end
    end
    
    if isfield(S.(oneChamp),'long_name')==0
        S.(oneChamp).long_name=[];
    end
    if isfield(S.(oneChamp),'units')==0
        S.(oneChamp).units=[];
    end
    
    % recupere les dimensions
    
    % S.(oneChamp).dim, cellule de caractere contenant le nom des dimensions pour la variable
    S.(oneChamp).dim='';
    
    count_vardim=0;
    
    if strcmp(S.dimorder,'C')
        theloop = [length(dimids):-1:1];      % permutation des dimensions pour avoir S.dimorder='C'
    else
        theloop = [1:length(dimids)];
    end
    
    for idim = theloop
        [thedimname, dimlen] = netcdf.inqDim(nc,dimids(idim));
        
        count_alldim = count_alldim+1;
        count_vardim = count_vardim+1;
        S.(oneChamp).dim{count_vardim} = thedimname;
        vecdim(count_vardim) = dimlen;
        alldim{count_alldim} = thedimname;
    end
    
    % recupere le type  ex 'float' 'string8' ...
    S.(oneChamp).type = xtype;          % ici xtype est un numero auquel correspond un type
    var_type = xtype;                   %NC_BYTE (1), NC_CHAR (2), NC_SHORT(3), NC_INT(4), NC_FLOAT(5), and NC_DOUBLE(6)
    
    % A faire: voir comment utiliser start, count, stride
    start=0;
    count=dimlen;
    stride=1;
    
    
    if sum(vecdim==0)==0
        % recupere le contenu de la variable
        S.(oneChamp).data = (netcdf.getVar(nc,varid));
        
        if length(vecdim)>1
            if strcmp(S.dimorder,'C')
                S.(oneChamp).data=permute(S.(oneChamp).data,[length(size(S.(oneChamp).data)):-1:1]);
            end
        end
        
        % Reshape the S.(oneChamp).data to coincide with vecdim
        
        if sum(vecdim==1)>0 % presence de dimension singleton
            vecdim=[vecdim,1]; % evite un bug si le champ est scalaire
            
            S.(oneChamp).data=reshape(S.(oneChamp).data,vecdim);
        end
    end
    
    %disp(['............',oneChamp])
    %size(S.(oneChamp).data)
    %S.(oneChamp).dim
    %vecdim
    %pause
    if isfield(S.(oneChamp),'units')==0
        S.(oneChamp).units=[];
    end
    if verbose==1
        disp(['............',oneChamp])
    end
end

% Clean not used dimensions for variables that are not retrieved

namedim=fieldnames(Dim);
rmdim=setdiff(namedim,lower(alldim));
for jdim=1:length(rmdim)
    Dim=rmfield(Dim,rmdim{jdim});
end


if isempty(theRecdimID)==0
    if theRecdimID>0
        if isempty(rmdim)==0
            recdimname= netcdf.inqDim(nc, theRecdimID);
            if strcmp(lower(recdimname),rmdim)==0
                S.recdim=recdimname;
            end
        else
            S.recdim=netcdf.inqDim(nc, theRecdimID);
        end
    end
end



S.obj='ObsInSitu';
if isfield(VarIN,'obj')
    S.obj=[S.obj '/' VarIN.obj];
end

S.fillisnan=0;

netcdf.close(nc)

