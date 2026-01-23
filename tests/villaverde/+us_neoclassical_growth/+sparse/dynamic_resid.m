function [residual, T_order, T] = dynamic_resid(y, x, params, steady_state, T_order, T)
if nargin < 6
    T_order = -1;
    T = NaN(7, 1);
end
[T_order, T] = us_neoclassical_growth.sparse.dynamic_resid_tt(y, x, params, steady_state, T_order, T);
residual = NaN(5, 1);
    residual(1) = (y(8)) - (T(1)*T(2));
    residual(2) = (y(6)+y(9)) - (y(8));
    residual(3) = (y(9)+(1-params(3))*y(2)) - (y(7)*(1+x(3))*(1+x(2)));
    residual(4) = ((1+x(3))*T(3)) - (T(4)*T(7));
    residual(5) = (y(10)) - (x(1));
end
