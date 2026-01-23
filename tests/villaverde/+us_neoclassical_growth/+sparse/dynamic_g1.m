function [g1, T_order, T] = dynamic_g1(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T_order, T)
if nargin < 9
    T_order = -1;
    T = NaN(7, 1);
end
[T_order, T] = us_neoclassical_growth.sparse.dynamic_g1_tt(y, x, params, steady_state, T_order, T);
g1_v = NaN(18, 1);
g1_v(1)=1-params(3);
g1_v(2)=1;
g1_v(3)=(1+x(3))*getPowerDeriv(y(6),(-1),1);
g1_v(4)=(-(T(2)*getPowerDeriv(y(7),params(2),1)));
g1_v(5)=(-((1+x(3))*(1+x(2))));
g1_v(6)=(-(T(4)*T(6)*params(2)*getPowerDeriv(y(7),params(2)-1,1)));
g1_v(7)=1;
g1_v(8)=(-1);
g1_v(9)=1;
g1_v(10)=1;
g1_v(11)=1;
g1_v(12)=(-(T(7)*params(1)*getPowerDeriv(y(11),(-1),1)));
g1_v(13)=(-(T(4)*T(5)*getPowerDeriv(y(15),1-params(2),1)));
g1_v(14)=(-(T(1)*getPowerDeriv(x(1),1-params(2),1)));
g1_v(15)=(-1);
g1_v(16)=(-(y(7)*(1+x(3))));
g1_v(17)=(-(y(7)*(1+x(2))));
g1_v(18)=T(3);
if ~isoctave && matlab_ver_less_than('9.8')
    sparse_rowval = double(sparse_rowval);
    sparse_colval = double(sparse_colval);
end
g1 = sparse(sparse_rowval, sparse_colval, g1_v, 5, 18);
end
