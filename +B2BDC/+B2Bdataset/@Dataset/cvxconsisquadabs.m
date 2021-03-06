function [y,s] = cvxconsisquadabs(obj,frac)
% Calculate outer bound for consistency measure (in absolute value) of 
% a B2BDC.B2Bdataset.Dataset object through cvx for the case when all
% surrogate models are quadratic functions.
% frac - Fraction of extra constraints used in the optimization
%        0 < frac < 100, if frac == -1, then automatically linear pairs
%        with influence factor greater than 5% of the most influential pair
%        will be included

% Created June 30, 2015    Wenyu Li
% Modified July 12, 2015    Wenyu Li (Extra combination for linear
%                                     constraints added)
  
bds = [[obj.DatasetUnits.Values.LowerBound]' , [obj.DatasetUnits.Values.UpperBound]'];
n_units = obj.DatasetUnits.Length;
n_variable = obj.Variables.Length;
[Qunits, Qx, Qextra, n_extra]  = obj.getInequalQuad(bds,frac);
cvx_begin sdp quiet
cvx_precision('best');
variable lamlb(n_units)
variable lamub(n_units)
variable lamxl(n_variable)
variable lamxu(n_variable)
if n_extra ~= 0
   variable lamextra(4*n_extra)
end
variable ro
cvxconstr = zeros(n_variable+1,n_variable+1);
cvxconstr(1,1) = 1;
cvxconstr = ro*cvxconstr;
for i = 1:n_units
   cvxconstr = cvxconstr + lamub(i)*Qunits{2*i-1}+...
      lamlb(i)*Qunits{2*i};
end
for i = 1:n_variable
   cvxconstr = cvxconstr + lamxu(i)*Qx{2*i-1}+...
      lamxl(i)*Qx{2*i};
end
if n_extra ~= 0
   count = 1;
   for k = 1:n_extra
      cvxconstr = cvxconstr + lamextra(count)*Qextra{count}+...
         lamextra(count+1)*Qextra{count+1} + lamextra(count+2)*Qextra{count+2}+...
         lamextra(count+3)*Qextra{count+3};
      count = count+4;
   end
end
minimize ro
subject to
cvxconstr >= zeros(n_variable+1,n_variable+1);
lamlb >= 0;
lamub >= 0;
lamxl >= 0;
lamxu >= 0;
if n_extra ~= 0
   lamextra >= 0;
end
sum(lamlb)+sum(lamub) == 1;
cvx_end
y = ro;
s.expl = -lamlb;
s.expu = lamub;
s.varl = -lamxl;
s.varu = lamxu;