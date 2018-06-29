function [NB]=sumel(ARR)
% -========================================================
%   USAGE : [NB]=sumel(ARR)
%   PURPOSE : make the sum of all element of an array over all dims
% -----------------------------------
%   INPUT :
%     ARR   (array)  -comments-
% -----------------------------------
%   OUTPUT :
%     NB   (scalar)  -comments-

% -----------------------------------
%   HISTORY  : created (2009) ccabanes
%   CALLED SUBROUTINES: none
% ========================================================

NB=sum(reshape(ARR,[1,numel(ARR)]));
