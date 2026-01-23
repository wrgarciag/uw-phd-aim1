function [residual, T_order, T] = static_resid(y, x, params, T_order, T)
if nargin < 5
    T_order = -1;
    T = NaN(5, 1);
end
[T_order, T] = us_neoclassical_growth.sparse.static_resid_tt(y, x, params, T_order, T);
residual = NaN(5, 1);
    residual(1) = (y(3)) - (y(2)^params(2)*T(1));
    residual(2) = (y(1)+y(4)) - (y(3));
    residual(3) = (y(4)+y(2)*(1-params(3))) - (y(2)*(1+x(3))*(1+x(2)));
    residual(4) = ((1+x(3))*T(2)) - (T(2)*params(1)*T(5));
    residual(5) = (y(5)) - (x(1));
end
