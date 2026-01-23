function [T_order, T] = static_resid_tt(y, x, params, T_order, T)
if T_order >= 0
    return
end
T_order = 0;
if size(T, 1) < 5
    T = [T; NaN(5 - size(T, 1), 1)];
end
T(1) = x(1)^(1-params(2));
T(2) = y(1)^(-1);
T(3) = params(2)*y(2)^(params(2)-1);
T(4) = y(5)^(1-params(2));
T(5) = 1+T(3)*T(4)-params(3);
end
