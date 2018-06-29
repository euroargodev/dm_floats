%_____________________________________________________________________________________________________
%   USAGE create_netcdf_allthefile(VARS,DIMS,ficout,CONFIG,verbose)
%%
%   PURPOSE: Create a netcdf file containing variables in VARI
%
%-----------------------------
%  INPOUT :
%
%   DIMS (structure)  -
%       with required fields for each dim : .name        (string)           Dim.n_prof.name = 'N_PROF'     name of the dimension
%                                           .dimlength   (scalar)           Dim.n_prof.dimlength = 88      length of the dimension
%  VARS (structure)
%        with required fields for each variable:
%                               .name        (string)                       S.temp.name = 'TEMPERATURE' name of the variable
%                               .dim         (cell array of string)         S.temp.dim  = {'N_PROF','N_LEVEL'}
%                               .data        (array)                        S.temp.data =  n_prof x n_level value of temperature
%
%        ficout (string) -  output file name-
%
%        CONFIG (structure)   OPTIONNAL contains global attribute you want to put in the netcdf file
%         with required fields : .name        (string)                        CONFIG.
%
%-----------------------------
%  OUTPUT :
%   none
%-----------------------------
%  HISTORY :created mai 2007 ccabanes
%           revision oct2008, fev2009 ccabanes
%           addaptee pour matlab 2008b, avril 2010 ccabanes
%______________________________________________________________
function create_netcdf_allthefile(VARS,DIMS,ficout,CONFIG,verbose)


if nargin<=3
    CONFIG=[];
    verbose=0;
end

if nargin==4
    if isstruct(CONFIG)==1
        verbose=0;
    else
        verbose=CONFIG;
        CONFIG=[];
    end
end


% ATTENTION : matlab(ou fortran F) et C gere differemment les dimensions
% C: X(t,z,y,x), unlimitted est la 1 ere dimension
% Matlab: X(x,y,z,t) unlimitted est la derniere dimension
% si on fait ncdump d'un fichier netcdf, les dimensions sont ordonnees selon C
% la librairie netcdf de matlab inverse l'ordre des dimensions quand elle lit un fichier netcdf
% pour l'ecriture il faut que la variable soit ordonnee selon Fortran (i.e unlimitted est la derniere dimension)


% VARS.dimorder='C' indique que les dimensions sont ordonnees selon C (i.e unlimitted est la 1 ere dimension);
% VARS.dimorder='F' si unlimitted est la derniere dimension

%

VARS.obj='ObsInSitu';
% trouve le nom de la dimension unlimitted
REC=[];
if isstruct(VARS)==1
    if isfield(VARS,'recdim')
        if isempty(VARS.recdim)==0
            REC = VARS.recdim;
            REC_length = DIMS.(lower(REC)).dimlength;
        end
    end
end

if isfield(VARS,'dimorder')==0 % si rien n'est precise
    if isempty(REC)==0
        VARS = libargo.check_FirstDimArray_is(VARS,REC);
    end
    VARS.dimorder = 'C';
end


if strcmp(VARS.dimorder,'F')
    isneedflip=0;
    if isempty(REC)==0
        VARS = libargo.check_LastDimArray_is(VARS,REC); % verifie et permute si necessaire
    end
else
    isneedflip=1;
    if isempty(REC)==0
        VARS = libargo.check_FirstDimArray_is(VARS,REC); % verifie et permute si necessaire
    end
end

% verifie que les NaN sont remplaces par la valeur fillvalue
VARS=libargo.replace_nan_byfill(VARS);

% transforme en cellules
if isstruct(VARS)==1
    VARS=struct2cell(VARS);
end
if isstruct(DIMS)==1
    DIMS=struct2cell(DIMS);
end

NBDIMS=length(DIMS);
NBVARS=length(VARS);

disp(['writting ' num2str(NBVARS), ' variable(s)  in the file....'])
disp(ficout)



ncid = netcdf.create(ficout,'clobber');


% DEFINITION des  Global attributes:
%----------------------------------------------------------------------

% Check in CONFIG if the fields exist

if isempty(CONFIG)==0
    if isstruct(CONFIG)==1
        CONFIG=struct2cell(CONFIG);
    end
    NBATT=length(CONFIG);
    for k=1:NBATT
        netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),CONFIG{k}.name, CONFIG{k}.att)
        
        if verbose==1
            %            disp(['Global attribute : ' expre])
        end
    end
end


memo=whos('VARS'); % look for the memory space needed to store VARI -> memo.bytes



% DEFINITION des DIMENSIONS
%----------------------------------------------------------------------
for k=1:NBDIMS
    if isfield(DIMS{k},'name')==0
        disp(' ')
        keyboard
        disp(['Dimension : ' DIMS{k}])
        error ('ERROR:  Should give a name  in Dim.name ')
    end
    if isfield(DIMS{k},'dimlength')==0
        disp(' ')
        disp(['Dimension : ' DIMS{k}])
        error ('ERROR: Should give a length  in Dim.dimlength ')
    end
    
    if isfield(DIMS{k},'dimlength')==1
        if isempty(REC)==0
            if strcmp(DIMS{k}.name,REC)==1   % si c'est la dimension unlimitted
                dimID(k) = netcdf.defDim(ncid,DIMS{k}.name,netcdf.getConstant('NC_UNLIMITED'));
            else
                dimID(k) = netcdf.defDim(ncid,DIMS{k}.name,DIMS{k}.dimlength);
            end
        else
            dimID(k) = netcdf.defDim(ncid,DIMS{k}.name,DIMS{k}.dimlength);
        end
    end
    
    if verbose==1
        if isfield(DIMS{k},'name')
            disp(' ')
            disp(['Dimension............',DIMS{k}.name])
        end
    end
end


% DEFINITION des VARIABLES et de leur ATTRIBUTS
%----------------------------------------------------------------------

for k=1:NBVARS
    
    missval=[]; %
    
    
    if verbose==1
        if isfield(VARS{k},'name')
            disp(' ')
            disp(['............',VARS{k}.name])
        end
    end
    
    % Collecte les infos necessaires pour la suite si c'est une variable
    % ------------------------------------------------------------------
    if isfield(VARS{k},'data')==1 % si c'est une variable (doit contenir un champ .data)
        
        if isfield(VARS{k},'name')==0
            disp([ 'Variable ............:',VARS{k}])
            error ('ERROR: should give a name  in Var.name to all variables')
        end
        if isfield(VARS{k},'dim')==0
            disp([ 'Variable ............:',VARS{k}.name])
            error ('ERROR: should give a dim  in Var.dim to all variables')
        end
        
        % the dimension of the variable
        extract_dim = VARS{k}.dim;
        
        % screen output, cherche l'attribut FillValue_ si non standard
        if isfield(CONFIG,'missval')
            missval=CONFIG.missval;
        end
        if isfield(VARS{k},'FillValue_')
            missval=VARS{k}.FillValue_;
        end
        if isfield(VARS{k},'fillval')
            missval=VARS{k}.fillval;
        end
        
        if isfloat(VARS{k}.data)|isinteger(VARS{k}.data) % les variables sont float ou integer
            
            % check for infinite value
            if isempty(find(isinf(VARS{k}.data)))==0
                VARS{k}.data(isinf(VARS{k}.data))=NaN;
                warning(['infinite value found in ' VARS{k}.name ' :stored as missing_value in the netcdf file']);
            end
            % s'il n'y a  pas de missval, on en cree une
            % if isempty(VARI{k}.data(isnan(VARI{k}.data)))==0
            %if isempty(missval)
            %    missval=99999;
            %end
            % end
            
            dataTYP = netcdf.getConstant('float');
            if isa(VARS{k}.data,'double'); dataTYP = netcdf.getConstant('double');end;
            if isinteger(VARS{k}.data); dataTYP = netcdf.getConstant('int');end;
            
        end
        
        if ischar(VARS{k}.data)
            dataTYP = netcdf.getConstant('char');
        end
        if isfield(VARS{k},'type')
            dataTYP = VARS{k}.type;
        end
        
        % DEFINITION des VARIABLES
        % ------------------------------------------------------------------
        
        % cherche quelles sont les dimensions des variables => extract_dim et fait correspondre les dimID
        
        siz = length(extract_dim);
        clear alldimid
        
        if isneedflip==1
            theloop = [siz:-1:1];      % permutation des dimensions pour avoir S.dimorder='F'
        else
            theloop = [1:siz];
        end
        
        ij=1;
        for m = theloop
            alldimid(ij) = netcdf.inqDimID(ncid,extract_dim{m});
            ij=ij+1;
        end
        
        varid(k) = netcdf.defVar(ncid,VARS{k}.name,dataTYP,alldimid);
        
        % ECRITURE DES ATTRIBUTS de la variable
        % -------------------------------------------------------------------
        
        % recherche tous les attributs et leur type
        attnames = fieldnames(VARS{k});
        % keyboard
        nbatt= length(attnames);
        jatt=2;
        for iatt=1:nbatt
            if verbose==1
                disp('**********************')
                disp(['attributs: ' attnames{iatt}])
                disp('-----------------')
            end
            theattname = attnames{iatt};
            theattname = strrep(theattname,'FillValue_','_FillValue');
            % Les 5 champs 'data', 'dim', 'type'  'name' et 'ischar2num' ne sont pas des attributs qu'on ecrit dans le fichier
            if ~(strcmp(theattname,'data')==1|strcmp(theattname,'dim')==1|strcmp(theattname,'type')==1|strcmp(theattname,'name')==1|strcmp(theattname,'ischar2num')==1)
                thevalatt = VARS{k}.(attnames{iatt});
                if verbose==1
                    thevalatt
                end
                
                if isempty(thevalatt)==0
                    netcdf.putAtt(ncid,varid(k),theattname,thevalatt);
                end
                
            end
        end
        
    end
    %pause
    
end


%keyboard
% ECRITURE des VARIABLES
%----------------------------------------------------------------------
netcdf.endDef(ncid);
%keyboard
for k=1:NBVARS
    if isfield(VARS{k},'data')==1
        if isempty(VARS{k}.data)==0
            %	    disp( VARS{k}.name)
            %            VARS{k}.dim
            %    	    if strcmp(VARS{k}.name,'DATA_TYPE')
            %    	    keyboard
            %    	    end
            ndim_var = length(VARS{k}.dim);
            vecdim = size(VARS{k}.data);
            
            size(VARS{k}.data);
            %if ndim_var>1
            if isneedflip==1
                VARS{k}.data=permute(VARS{k}.data,[length(size(VARS{k}.data)):-1:1]);
                vecdim=fliplr(vecdim);
            end
            %end
            
            if ndim_var>1
                start_var = zeros(ndim_var,1);
                count_var = vecdim;
            else
                start_var = 0;
                count_var = length(VARS{k}.data);
            end
            
            netcdf.putVar(ncid,varid(k),start_var,count_var,VARS{k}.data);
        end
    end
end

netcdf.close(ncid)

% HELP start, count, stride
%
%  start A vector of size t integers specifying the index in the variable where the first
%        of the data values will be written. The indices are relative to 0, so for example,
%        the first data value of a variable would have index (0, 0, ... , 0). The elements of
%        start correspond, in order, to the variable’s dimensions. Hence, if the variable
%        is a record variable, the first index corresponds to the starting record number
%        for writing the data values.

%  count A vector of size t integers specifying the number of indices selected along each
%        dimension. To write a single value, for example, specify count as (1, 1, ... ,
%        1). The elements of count correspond, in order, to the variable’s dimensions.
%        Hence, if the variable is a record variable, the first element of count corresponds
%        to a count of the number of records to write.

%  stride A vector of ptrdiff t integers that specifies the sampling interval along each di-
%         mension of the netCDF variable. The elements of the stride vector correspond,
%         in order, to the netCDF variable’s dimensions (stride[0] gives the sampling inter-
%         val along the most slowly varying dimension of the netCDF variable). Sampling
%         intervals are specified in type-independent units of elements (a value of 1 selects
%         consecutive elements of the netCDF variable along the corresponding dimen-
%         sion, a value of 2 selects every other element, etc.). A NULL stride argument
%         is treated as (1, 1, ... , 1).
