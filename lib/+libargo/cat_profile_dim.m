function [Co,Dim]=cat_profile_dim(Coi,Cor,Dimi,Dimr,DIMNAME)
% -========================================================
%   USAGE : [Co,Dim]=cat_profile_dim(Coi,Cor,Dimi,Dimr,DIMNAME)
%   EXAMPLE : [Co,Dim]=cat_profile_dim(Coi,Cor,Dimi,Dimr,'N_PROF')
%   PURPOSE : cat two float structure along one dimension
% -----------------------------------
%   INPUT :
%     Coi (structure)  float structure
%     Cor (structure)  float structure
%     Dimi,Dimr (structure)  dimensions
%     DIMNAME (char)   dimension name ex: 'N_PROF' or 'N_LEVELS'
% -----------------------------------
%   OUTPUT :
%     Co  (structure)  new structure (from Coi and Cor)
%     Dim  (strucutre) new dimension
% -----------------------------------
%   HISTORY  : created (2009) ccabanes
%            : revised (03/062016) ccabanes
%   CALLED SUBROUTINES: none
% ========================================================
if isempty(Coi)& isempty(Dimi)&~isempty(Cor)&~isempty(Dimr)
    Co=Cor;
    Dim=Dimr;
    return
end
if isempty(Cor)& isempty(Dimr)&~isempty(Coi)&~isempty(Dimi)
    Co=Coi;
    Dim=Dimi;
    return
end

if isempty(strfind(Coi.obj,'ObsInSitu'))
    error('replace_profile not define for this type of structure')
else
    
    INITFIRSTDIM=[];
    if isfield(Coi,'firstdimname')
        INITFIRSTDIM=Coi.firstdimname;
    end
    %      keyboard
    Cor = libargo.check_FirstDimArray_is(Cor,DIMNAME);
    Coi = libargo.check_FirstDimArray_is(Coi,DIMNAME);
    
    %keyboard
    champsi = fieldnames(Coi);    %champs={'psal','psalqc','psalad',....}
    champsr = fieldnames(Cor);
    
    % traitement des champs vides dans l'une ou l'autre des structures:
    % on remplit les champs vides dans une des structure par des Fillvalue
    
    % champs vide dans Coi => on remplit Coi par des fillval
    
    Nbfields = length(champsi);
    for k=1:Nbfields
        oneChamp=champsi{k};
        if isfield(Coi.(oneChamp),'data')%& isfield(Cor.(oneChamp),'data')
            if isempty(Coi.(oneChamp).data)
                clear siz
                for l=1:length(Coi.(oneChamp).dim)
                    siz(l)=Dimi.(lower(Coi.(oneChamp).dim{l})).dimlength;
                    if siz(l)==0
                 %       siz(l)=1;  % 03/06/2016
                    end
                end
                siz(length(Coi.(oneChamp).dim)+1)=1;
                if isfield(Coi.(oneChamp),'FillValue_')
                    Coi.(oneChamp).data = repmat(Coi.(oneChamp).FillValue_,siz);
                else
                    oneChamp
                    error('Did not find FillValue for this field')
                end
            end
        end
    end
    % champs vide dans Cor => on remplit Cor par des fillval
    %keyboard
    Nbfields = length(champsr);
    for k=1:Nbfields
        oneChamp=champsr{k};
        if isfield(Cor.(oneChamp),'data')%& isfield(Coi.(oneChamp),'data')
            if isempty(Cor.(oneChamp).data)
                clear siz
                for l=1:length(Cor.(oneChamp).dim)
                    siz(l)=Dimr.(lower(Cor.(oneChamp).dim{l})).dimlength;
                    if siz(l)==0
                 %       siz(l)=1;% 03/06/2016
                    end
                end
                siz(length(Cor.(oneChamp).dim)+1)=1;
                if isfield(Cor.(oneChamp),'FillValue_')
                    Cor.(oneChamp).data = repmat(Cor.(oneChamp).FillValue_,siz);
                else
                    oneChamp
                    error('Did not find FillValue for this field')
                end
            end
        end
    end
    
    
    %keyboard
    % traitement des champs uniques dans une ou autre structure:
    % on remplit les champs inexistants dans une des structures par des Fillvalue
    
    % champs uniquement dans Coi => on remplit Cor par des fillval
    champs_uni = setdiff(champsi,champsr);
    Nbfields = length(champs_uni);
    for k=1:Nbfields
        oneChamp=champs_uni{k};
        if isfield(Coi.(oneChamp),'data')
            Cor.(oneChamp)=Coi.(oneChamp);
            % on remplace Cor.(champs_uni) par un tableau aux bonnes dim, remplie de fillval
            % trouve les dimensions associees:
            clear siz
            for l=1:length(Cor.(oneChamp).dim)
                if isfield(Dimr,lower(Cor.(oneChamp).dim{l}))
                    siz(l)=Dimr.(lower(Cor.(oneChamp).dim{l})).dimlength;
                    if siz(l)==0
                       % siz(l)=1;
                    end
                else
                    siz(l)=Dimi.(lower(Cor.(oneChamp).dim{l})).dimlength;
                    Dimr.(lower(Cor.(oneChamp).dim{l}))=Dimi.(lower(Cor.(oneChamp).dim{l})); % cree la dimension pour Cor si elle n'existe pas
                    if siz(l)==0
                      %  siz(l)=1;
                    end
                end
            end
            siz(length(Coi.(oneChamp).dim)+1)=1;
            if isfield(Cor.(oneChamp),'FillValue_')
                Cor.(oneChamp).data = repmat(Cor.(oneChamp).FillValue_,siz);
            else
                oneChamp
                error('Did not find FillValue for this field')
            end
        end
    end
    
    %champs uniquement dans Cor => on remplit Coi par des fillvalue
    champs_unr = setdiff(champsr,champsi);
    Nbfields = length(champs_unr);
    for k=1:Nbfields
        oneChamp = champs_unr{k};
        if isfield(Cor.(oneChamp),'data')
            Coi.(oneChamp)=Cor.(oneChamp);
            % on remplace Coi.(champs_unr) par un tableau aux bonnes dim, rempli de fillval
            % trouve les dimensions associees:
            clear siz
            for l=1:length(Coi.(oneChamp).dim)
                if isfield(Dimi,lower(Coi.(oneChamp).dim{l}))
                    siz(l)=Dimi.(lower(Coi.(oneChamp).dim{l})).dimlength;
                    %disp('toto')
                    if siz(l)==0
                       % siz(l)=1;
                    end
                else
                    siz(l)=Dimr.(lower(Coi.(oneChamp).dim{l})).dimlength;
                    Dimi.(lower(Coi.(oneChamp).dim{l}))=Dimr.(lower(Coi.(oneChamp).dim{l})); % cree la dimension pour Cor si elle n'existe pas
                    if siz(l)==0
                       % siz(l)=1;
                    end
                end
            end
            siz(length(Coi.(oneChamp).dim)+1)=1;
            
            if isfield(Coi.(oneChamp),'FillValue_')
                %siz
                %size(Coi.(oneChamp).FillValue_)
                Coi.(oneChamp).data = repmat(Coi.(oneChamp).FillValue_,siz);
                %size(Coi.(oneChamp).data)
            else
                oneChamp
                error('Did not find FillValue for this field')
            end
        end
    end
    
    % traitement des champs communs aux deux structures
    champsi = fieldnames(Coi);    %champs={'psal','psalqc','psalad',....}
    champsr = fieldnames(Cor);
    champs=union(champsi,champsr);
    Nbfields = length(champs);
    Co=Coi;
   % keyboard
    for k=1:Nbfields            % boucle sur toutes les variables
        oneChamp=champs{k};
        if isfield(Coi,oneChamp)&isfield(Cor,oneChamp)
            if isfield(Coi.(oneChamp),'data') & isfield(Cor.(oneChamp),'data')
                %if isempty(Coi.(oneChamp).data)==0 & isempty(Cor.(oneChamp).data)==0  % 03/06/2016
                    
                    if sum(strcmp(Coi.(oneChamp).dim ,Cor.(oneChamp).dim))==length(Coi.(oneChamp).dim)  % les champs ont les memes dim names
                        isthedim_i=strcmp(Coi.(oneChamp).dim,DIMNAME);
                        isthedim_r=strcmp(Cor.(oneChamp).dim,DIMNAME);
                        
                        if sum(isthedim_i)==1&sum(isthedim_r)==1 % si on trouve DIMNAME dans les deux champs
                            otherdim_i=(isthedim_i==0);          % on regarde quelles sont les autres dimensions pour le champ i
                            otherdim_r=(isthedim_r==0);          % on regarde quelles sont les autres dimensions pour le champ r
                            clear fullsizei
                            for l=1:length(Coi.(oneChamp).dim)
                            fullsizei(l)=Dimi.(lower(Coi.(oneChamp).dim{l})).dimlength;
                            end
                            %fullsizei = size(Coi.(oneChamp).data); % 03/06/2016
                            
                            sizei = fullsizei(otherdim_i);
                            if isempty(sizei);sizei=1;end;
                            clear fullsizer
                            for l=1:length(Cor.(oneChamp).dim)
                            fullsizer(l)=Dimr.(lower(Cor.(oneChamp).dim{l})).dimlength;
                            end
                            %fullsizer = size(Cor.(oneChamp).data);% 03/06/2016
                            sizer = fullsizer(otherdim_r);
                            if isempty(sizer);sizer=1;end;
                            maxsize=max(sizei,sizer);
                            nbdim_i=length(sizei);
                            nbdim_r=length(sizer);
                            
                            if isequal(sizei,sizer)==1
                                ap='';
                                for m=1:nbdim_i
                                    ap=[ap ',1:sizei(' num2str(m) ')'];
                                end
                                %themax=[fullsizei(1),sizei];
                                if isfield(Coi.(oneChamp),'FillValue_')
                                    %Co.(oneChamp).data=repmat(Coi.(oneChamp).FillValue_,themax);
                                    expre=['Co.(oneChamp).data(:' ap ')=Coi.(oneChamp).data;'];
                                    %expre
                                    eval(expre)
                                else
                                    oneChamp
                                    error('Did not find FillValue for this field')
                                end
                            end
                            if isequal(sizei,maxsize)==0
                                ap='';
                                for m=1:nbdim_i
                                    ap=[ap ',1:sizei(' num2str(m) ')'];
                                end
                                themax=[fullsizei(1),maxsize];
                                if isfield(Coi.(oneChamp),'FillValue_')
                                    Co.(oneChamp).data=repmat(Coi.(oneChamp).FillValue_,themax);
                                    expre=['Co.(oneChamp).data(:' ap ')=Coi.(oneChamp).data;'];
                                    %expre
                                    eval(expre)
                                else
                                    oneChamp
                                    error('Did not find FillValue for this field')
                                end
                            end
                            
                            if isequal(sizer,maxsize)==0
                                ap='';
                                for m=1:nbdim_r
                                    ap=[ap, ',1:sizer(' num2str(m) ')'];
                                end
                                themax=[fullsizer(1),maxsize];
                                tempo = Cor.(oneChamp).data;
                                if isfield(Cor.(oneChamp),'FillValue_')
                                    Cor.(oneChamp).data = repmat(Cor.(oneChamp).FillValue_,themax);
                                    expre=['Cor.(oneChamp).data(:' ap ')=tempo;'];
                                    %expre
                                    eval(expre)
                                    clear tempo
                                else
                                    oneChamp
                                    error('Did not find FillValue for this field')
                                end
                            end
                            
                            nbdim = length(size(Co.(oneChamp).data));
                            iprofiles=size(Co.(oneChamp).data,1)+1;
                            rprofiles=size(Co.(oneChamp).data,1)+size(Cor.(oneChamp).data,1);
                            api='';
                            apr='';
                            if nbdim>1
                                api=repmat(',:',[1,nbdim-1]);
                                apr=repmat(',:',[1,nbdim-1]);
                            end
                            expre=['Co.(oneChamp).data(' num2str(iprofiles) ':' num2str(rprofiles)  api ') = Cor.(oneChamp).data(:' apr ');'];
                            %expre
                            eval(expre)
                            
                        end
                    end
                end
            end
        end
    end
    dimnamei=fieldnames(Dimi);
    dimnamer=fieldnames(Dimr);
    Dim=Dimi;
    for k=1:length(dimnamer)
        
        if sum(strcmp(dimnamei,dimnamer{k}))==1
            if strcmp(dimnamer{k},lower(DIMNAME))==1 % dimension selon laquelle les champs sont concatenes
                Dim.(dimnamer{k}).dimlength=Dimi.(dimnamer{k}).dimlength+Dimr.(dimnamer{k}).dimlength;
            else
                Dim.(dimnamer{k}).dimlength=max(Dimi.(dimnamer{k}).dimlength,Dimr.(dimnamer{k}).dimlength);
                
            end
        else
            Dim.(dimnamer{k})=Dimr.(dimnamer{k});
        end
    end
    Co = libargo.check_FirstDimArray_is(Co,DIMNAME);
    if isempty(INITFIRSTDIM)==0
        Co = libargo.check_FirstDimArray_is(Co,INITFIRSTDIM);
    end
end
