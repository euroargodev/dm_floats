% -========================================================
%   USAGE : [thetitle]=plot_profile_with_flag(S,ParamX,ParamY,profile_number)
%   PURPOSE : plot d'un profil PSAL ou TEMP avec les flags associes
% -----------------------------------
%   INPUT :
%     S   (structure)  - float data (multiprofile or single)
%     ParamX (char)     - parametre à tracer ('psal' ou 'temp')
%     ParamY (char)     - parametre à utiliser pour l'axe Y ('pres' ou 'temp')
%     profile_number  (integer) numero de profil (peut etre different de numero de cycle)
% 
% Note:
%	Ceux sont les QC flags de ParamX qui sont utilises.
% 
% -----------------------------------
%   HISTORY  : created (2009) ccabanes
%            : Revised: 2014-05-14 (G. Maze) 
% 				Fix a bug due to use of 'replace_fill_bynan' without libargo package
% 				Fix help line to show ParamX,ParamY in place of Param 
%   CALLED SUBROUTINES: replace_fill_bynan
% ========================================================

function [thetitle]=plot_profile_with_flag(S,ParamX,ParamY,profile_number)

% verifie que la premiere dimension de tous les tableaux est N_PROF (rearrange sinon)
S = libargo.check_FirstDimArray_is(S,'N_PROF');

if isfield (S, 'fillisnan')
    if S.fillisnan==0
        S = libargo.replace_fill_bynan(S);
    end
else
    S = libargo.replace_fill_bynan(S);
end
thetitle=[];

ParamX = lower(ParamX);
ParamY = lower(ParamY);
nprof  = profile_number;


if isfield(S,ParamX)  % abscisse
    if isfield(S.(ParamX),'data')
        subX=S.(ParamX).data(nprof,:);
      
        if isfield(S,ParamY)  % abscisse
            if isfield(S.(ParamY),'data')
                level = S.(ParamY).data(nprof,:);

                plot(subX,level ,'b','LineWidth',3) ;
                
                hold on
                grid on
                
                xlabel([upper(ParamX)],'interpreter','none')
                ylabel([upper(ParamY)],'interpreter','none')
                
                if isempty(findstr(ParamY,'pres'))==0
                    set(gca,'Ydir','reverse')
                end
                
                % colore les flags
                
                if isfield(S, [ParamX '_qc'])
                    
                    if isfield(S.([ParamX '_qc']),'ischar2num')
                        if S.([ParamX '_qc']).ischar2num~=1
                            warning('Flag values are characters, should be numeric for plotting purpose, you can use format_flags_char2num.m ')
                        end
                    else
                        warning('Flag values are characters, should be numeric for plotting purpose, you can use format_flags_char2num.m ')
                    end
                    
                    if isfield(S.([ParamX '_qc']),'data')
                        
                        the_qc = S.([ParamX '_qc']).data(nprof,:);
                        
                        sub2=subX;
                        sub2(the_qc~=1)=NaN;
                        plot(sub2,level ,'g+','LineWidth',3) ;
                        
                        sub2=subX;
                        sub2(the_qc~=2)=NaN;
                        plot(sub2,level ,'y+','LineWidth',3) ;
                        
                        sub2=subX;
                        sub2(the_qc~=3)=NaN;
                        plot(sub2,level ,'m+','LineWidth',3) ;
                        
                        sub2=subX;
                        sub2(the_qc~=4)=NaN;
                        plot(sub2,level ,'r+','LineWidth',3) ;
                        
                        sub2=subX;
                        sub2(the_qc==1|the_qc==2|the_qc==3|the_qc==4)=NaN;
                        plot(sub2,level ,'b+','LineWidth',3) ;
                    end
                end
                
                
            end
        end
    end
    
    % titre du plot (numero de flotteur, date, longitude, latitude, cycle, ) si on a les infos
    
    thetitle = [' '];
    info1  = {'platform_number','juld','longitude','latitude','cycle_number','direction','pi_name','data_centre'};
    info2  = {'Platform: ', ', ', ', lon: ',', lat: ',', cycle: ' ,'', ', PI: ', ', '};
    
    
    
    for k=1:length(info1)
        if isfield(S,info1{k})
            if isfield(S.(info1{k}), 'data')
                if isequal(info1{k},'juld')
                    % transforme la date juld > jour dd/mm/yyyy
                    thedate = datestr( (S.juld.data(nprof,:) + datenum('19500101','yyyymmdd')),'dd/mm/yyyy');
                    
                    thetitle = [thetitle info2{k}  thedate  ];
                else
                    thetitle = [thetitle info2{k}  strtrim(num2str(S.(info1{k}).data(nprof,:)))  ];
                end
                
            end
        end
    end
    
    %title(thetitle,'interpreter','none')
    
end

return