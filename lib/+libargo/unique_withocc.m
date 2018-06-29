function [u,occ]=unique_withocc(A)
% -========================================================
%   USAGE : [u,occ]=unique_withocc(A)
%   PURPOSE : find unique value, with number of occurence (occ)
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

[u,i,j]=unique(A);

occ=zeros(1,max(j));

for k=1:max(j)
    occ(k)=sum(j==k);
end

% classe par occurence decroissante

[occsort,is]=sort(occ,'descend');

u=u(is);
occ=occsort;