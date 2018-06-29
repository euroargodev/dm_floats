function y=meanoutnan(x,dim);

%if prod(size(x))==1, y = x; return, end;

if nargin==1, 
  dim = min(find(size(x)~=1));
  if isempty(dim), dim = 1; end
end

if size(x,dim)==1,
  y = x;
else
  if ~isempty(x),
    Mnan=(~isfinite(x));
    coef=sum(~Mnan,dim);
    coef(coef==0)=NaN*coef(coef==0);
    inan=find(Mnan);
    x(inan)=zeros(size(x(inan)));
    y=sum(x,dim)./coef;
  else
    %y = NaN;
    y = [];
  end
end

