function [isfound]=findstr_tab(tab,car)
% -========================================================
%   USAGE : [isfound]=findstr_tab(TAB,car)
%   PURPOSE : find a string in an array of string of cell array
% -----------------------------------
%   INPUT :
%     TAB   (array of string)  -N*N_string
%           (or cell array of string)  N*1
%     car    string to find 
% -----------------------------------
%   OUTPUT :
%     isfound   (logical)  N*1
%             0 if car is not found, 1 otherwise
%   HISTORY  : created (2009) ccabanes
%            : modified (yyyy) byxxx 
%   CALLED SUBROUTINES: none
% ========================================================

if iscell(tab)==0 
    % transforme en cell
    tabcell=cellstr(tab);
else
    tabcell=tab;
end
% on cherche la chaine de caratere
ischarcell = strfind(tabcell,car );

% on cherche ou la cell ischarcell n'est pas vide
isfound=~cellfun('isempty',ischarcell);

    
