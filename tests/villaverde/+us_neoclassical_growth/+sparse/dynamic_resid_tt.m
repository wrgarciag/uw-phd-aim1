function [T_order, T] = dynamic_resid_tt(y, x, params, steady_state, T_order, T)
if T_order >= 0
    return
end
T_order = 0;
if size(T, 1) < 7
    T = [T; NaN(7 - size(T, 1), 1)];
end
T(1) = y(7)^params(2);
T(2) = x(1)^(1-params(2));
T(3) = y(6)^(-1);
T(4) = params(1)*y(11)^(-1);
T(5) = params(2)*y(7)^(params(2)-1);
T(6) = y(15)^(1-params(2));
T(7) = 1+T(5)*T(6)-params(3);
end
