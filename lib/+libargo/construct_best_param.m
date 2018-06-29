% -========================================================
%   USAGE : [Ci] = construct_best_param(Co,allparam)
%           [Ci] = construct_best_param(Co,allparam,Cp)
%   PURPOSE : replace param by adjusted parameter if they exist for allparam
%             keep param if not
% -----------------------------------
%   INPUT :
%     Ci   (structure)  -float structure-      
%     allparam  (cell of char)  parameters used ex:{'temp','psal','pres'}
%
%   OPTIONNAL INPUT :
%    Cp (structure)  output from a previous call of the function construct_best_param
% -----------------------------------
%   OUTPUT :
%     Ci   (structure)  -structure with the "best" values for param/ param_qc/ param_error in
%     allparam
% -----------------------------------
%   HISTORY  : created (2012) ccabanes
%            : modified (yyyy) byxxx
%   CALLED SUBROUTINES: none
% ========================================================

function [Ci] = construct_best_param(Co,allparam,Cp)

if nargin~=3
    Ci=[];
else
    Ci=Cp;
end

verbose=0;
INITFIRSTDIM=[];
if isfield(Co,'firstdimname')
    INITFIRSTDIM=Co.firstdimname;
else
    INITFIRSTDIM='N_HISTORY';
end

Co = libargo.check_FirstDimArray_is(Co,'N_PROF');

fillval='FillValue_';


isADJprofile=logical(ones(Co.n_prof,1));

% teste si les profils ont des valeurs ajustees pour tous les parametres allparam
% condition: il ne faut pas que les param_adjusted_qc soient  a FillValue
% si ce n'est pas la cas pour au moins un parametre alors isADJprofile=0 pour le profil
for k=1:length(allparam)
    
    param= lower(allparam{k});
    
    if isfield(Co,param)
        
        paramad=[param '_adjusted'];
        paramadqc=[paramad '_qc'];
        paramaderror=[paramad '_error'];
        
        if ~isfield(Co,paramad)
            isADJprofile=logical(zeros(Co.n_prof,1)); % test failed si il manque le parametre ajuste d'un des parametres allparam
            disp(['No adjusted parameter  for ' param])
        end
        
        [Test]=libargo.check_isfillval_prof(Co,paramadqc);
        
        
        if ~isempty(Test.(paramadqc))
            
            isADJprofile = isADJprofile & ~Test.(paramadqc);
        else
            disp(['No adjusted parameter QC for ' param])
            isADJprofile=logical(zeros(Co.n_prof,1)); % test fail si il manque le parametre ajusted_qc d'un des parametres allparam
        end
    else
      warning(['The parameter ' allparam{k} ' does not exist'])
    end
    
end

% verifie si c'est consistant avec le data mode

if isfield(Co,'data_mode')
    isADJfromDmode = Co.data_mode.data=='D'|Co.data_mode.data=='A';
end

if isequal(isADJprofile,isADJfromDmode)==0
    if verbose==1
    disp(' ')
    disp('******** Warning')
    disp(['Number of profiles with adjusted param well filled: ', num2str(sum(isADJprofile))])
    disp(['Number of profiles with data mode = A or D: ', num2str(sum(isADJfromDmode))])
    disp('Adjusted parameters may not be filled consistently with the data mode')
    disp('We require that both adjusted param are well filled and data mode=A or D')
    disp('********')
    end
end
disp(' ')

isADJprofile = isADJprofile&isADJfromDmode;

if sum(isADJprofile)~=0
    texte=[ 'In best: ' num2str(sum(isADJprofile)) ,' profiles are replaced by adjusted profiles for: '];
    if verbose==1
    disp((texte))
    disp(allparam')
    end
    for k=1:length(allparam)
        
        param= lower(allparam{k});
        
        if isfield(Co,param)
            
            paramqc=[param '_qc'];
            paramad=[param '_adjusted'];
            paramadqc=[paramad '_qc'];
            paramaderror=[paramad '_error'];
            
            paramnew=[param '_best'];
            paramnewqc=[param '_best_qc'];
            paramnewerror=[param '_best_error'];
            
            
            Ci.(paramnew)=Co.(paramad);
            Ci.(paramnewqc)=Co.(paramadqc);
            Ci.(paramnewerror)=Co.(paramaderror);
            Ci.(paramnew).name=upper(paramnew);
            Ci.(paramnewqc).name=upper(paramnewqc);
            Ci.(paramnewerror).name=upper(paramnewerror);
            % on prend les parametres TR si pas d'ajustement A ou D
            Ci.(paramnew).data(isADJprofile==0,:) = Co.(param).data(isADJprofile==0,:);
            Ci.(paramnewqc).data(isADJprofile==0,:) = Co.(paramqc).data(isADJprofile==0,:);
        end
        
    end
    
else
    if verbose==1
    disp(' In best: all profiles are RT profiles for :')
    disp(allparam')
    end
    for k=1:length(allparam)
        
        param= lower(allparam{k});
        
        if isfield(Co,param)
            
            paramqc=[param '_qc'];
            paramad=[param '_adjusted'];
            paramadqc=[paramad '_qc'];
            paramaderror=[paramad '_error'];
            
            paramnew=[param '_best'];
            paramnewqc=[param '_best_qc'];
            paramnewerror=[param '_best_error'];
            
            
            Ci.(paramnew)=Co.(param);
            Ci.(paramnewqc)=Co.(paramqc);
            Ci.(paramnew).name=upper(paramnew);
            Ci.(paramnewqc).name=upper(paramnewqc);
            
        end
        
    end
end

Ci.isADJprofile=isADJprofile;

%Co = check_FirstDimArray_is(Co,INITFIRSTDIM);
