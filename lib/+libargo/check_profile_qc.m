function [Co,GlobQC,ValnumQC]=check_profile_qc(Co,param,fillval)
% -========================================================
%   USAGE : [Co]=check_profile_qc(Co); % check all param_qc
%           [Co]=check_profile_qc(Co,param); % check only param_qc
%           [Co,GlobQC,ValnumQC]=check_globqc_prof(Co,param,fillval)
%   PURPOSE : short description of the function here
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


ValnumQC=[];
GlobQC=[];

if nargin<=2
    fillval='FillValue_';
end
if nargin==1
    fillval='FillValue_';
    thefields = fieldnames(Co);
    ischarcell = strfind(thefields,'_adjusted_qc');
    ischar=~cellfun('isempty',ischarcell);
    param = strrep(thefields(ischar),'_adjusted_qc','');
else
   param = lower(param);
end

INITFIRSTDIM=[];
if isfield(Co,'firstdimname')
    INITFIRSTDIM=Co.firstdimname;
else
    INITFIRSTDIM='N_HISTORY';
end
Co = libargo.check_FirstDimArray_is(Co,'N_PROF');
%keyboard
for k=1:length(param)
    onechamp = param{k};
    Co_best = libargo.construct_best_param(Co,{onechamp},[]);
    Co_best = libargo.format_flags_char2num(Co_best);
    
    if isfield (Co_best, [onechamp '_best_qc'])
    
        qc = Co_best.([onechamp '_best_qc']).data;

        if isempty(Co_best.([onechamp '_best_qc']).(fillval))==0

            isfill=(qc==Co_best.([onechamp '_best_qc']).(fillval)|qc==9);
        else
            isfill=(qc==9);
        end
        
        qc(qc==1|qc==2|qc==5|qc==8)=1;
        qc(qc==3|qc==4|qc==0)=2;
        A=sum(qc==1,2);
        B=sum(~isfill,2);
        nf=B~=0;
        ValnumQC=999*ones(size(qc,1),1);
        GlobQC=repmat(' ',[size(qc,1),1]);
        
        ValnumQC(nf)=A(nf)./B(nf);
        
        GlobQC(ValnumQC==0)='F';
        GlobQC(ValnumQC>0)='E';
        GlobQC(ValnumQC>=0.25)='D';
        GlobQC(ValnumQC>=0.5)='C';
        GlobQC(ValnumQC>=0.75)='B';
        GlobQC(ValnumQC==1)='A';
        GlobQC(ValnumQC==999)=' ';
        
        Co.(['profile_' onechamp '_qc']).data = GlobQC;
        
   end
end

Co = libargo.check_FirstDimArray_is(Co,INITFIRSTDIM);

