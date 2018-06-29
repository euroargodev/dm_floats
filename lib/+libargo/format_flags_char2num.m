function Pr = format_flags_char2num(Co);
% -========================================================
%   USAGE : Pr = format_flags_char2num(Co);
%   PURPOSE : change flag char strings to numerical vectors
%             ex '11111441111 ' -> [1 1 1 1 1 4 4 1 1 1 1 999]
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


fillval='FillValue_';

champs = fieldnames(Co);    %champs={'psal','psalqc','psalad',....}
Nbfields = length(champs);

Pr=Co;


for k=1:Nbfields            % boucle sur toutes les variables
    oneChamp=champs{k};
    
    if isempty(findstr(oneChamp,'_qc'))==0            % test si il y a 'qc' dans le nom du champ
        
        if isempty(Pr.(oneChamp).data)==0            % test si le champ est rempli
            
            Pr.(oneChamp).ischar2num=0;  % variable logique qui identifie
            % si le tableau de flag a ete transforme char-> num (=1) ou non (=0)
            
            
            if ischar(Pr.(oneChamp).type)==1
                if strcmp(Pr.(oneChamp).type, 'char')==1
                    thisiscar=1;
                else
                    thisiscar=0;
                end
            else
                if Pr.(oneChamp).type==2
                    thisiscar=1;
                else
                    thisiscar=0;
                end
            end
            
            if thisiscar==1      % test si c'est une chaine de caractère
                
                if length(size(Pr.(oneChamp).data))>2       % test si c'est un tableau de 2 dim
                    %warning('Does not accept array of dim >2')
                else
                    
                    % test si le tableau de flag est alphanumerique charactere ie '0' '1' '2' ...'9' seulement
                    % (les fillvalues ne sont pas prisent en compte, elles peuvent ne pas etre alphanumeriques ex ' ')
                    
                    poubflag = Pr.(oneChamp).data;  % tableau temporaire
                    poubflag(poubflag==Pr.(oneChamp).(fillval))='0'; % On remplace les fillvalue par un caratere alphanumerique ('0') pour le test seulement.
                    poubflag(isstrprop(poubflag,'cntrl'))='0';
                    isalphanum = libargo.sumel(isstrprop(poubflag,'digit')) == numel(poubflag); %=1 si tableau alphanumerique
                    clear poubflag
                    
                    
                    if isalphanum==1  % test si tableau alphanumerique
                        
                        
                        % on transforme le tableau de flag en tableau numerique
                        Pr.(oneChamp)=rmfield(Pr.(oneChamp),'data');
                        Pr.(oneChamp).data=single(999*ones(size(Co.(oneChamp).data))); % fillval numeriques
                        Pr.(oneChamp).type=5; % single precision
                        Pr.(oneChamp).(fillval)=single(999);
                        size1=size(Pr.(oneChamp).data,1);
                        %keyboard
                        %size1
                        %oneChamp
                        for i=1:size1                              % boucle sur chaque profil
                            
                            flagstr=Co.(oneChamp).data(i,:)' ;
                            isnofill=(flagstr ~= Co.(oneChamp).(fillval)&~isstrprop(flagstr,'cntrl'))';
                            flagnum=str2num(flagstr(isnofill))';
                            if sum(isnofill)~=0
                                
                                Pr.(oneChamp).data(i,isnofill)=single(flagnum);
                                
                            end
                        end
                        Pr.(oneChamp).ischar2num=1;
                        Co.(oneChamp).ischar2num=1;
                        Pr.(oneChamp) = orderfields(Pr.(oneChamp),Co.(oneChamp)); % ordonne les champs comme dans la structure initiale
                        
                    end
                end
            end
        end
    end
end
