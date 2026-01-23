function [y, T, residual, g1] = static_2(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(4, 1);
  residual(1)=(y(1)+y(4))-(y(3));
  residual(2)=(y(4)+y(2)*(1-params(3)))-(y(2)*(1+x(3))*(1+x(2)));
  T(1)=y(1)^(-1);
  T(2)=y(5)^(1-params(2));
  T(3)=1+params(2)*y(2)^(params(2)-1)*T(2)-params(3);
  residual(3)=((1+x(3))*T(1))-(T(1)*params(1)*T(3));
  T(4)=x(1)^(1-params(2));
  residual(4)=(y(3))-(y(2)^params(2)*T(4));
  T(5)=getPowerDeriv(y(1),(-1),1);
if nargout > 3
    g1_v = NaN(9, 1);
g1_v(1)=1;
g1_v(2)=(1+x(3))*T(5)-T(3)*params(1)*T(5);
g1_v(3)=1;
g1_v(4)=1;
g1_v(5)=1-params(3)-(1+x(3))*(1+x(2));
g1_v(6)=(-(T(1)*params(1)*T(2)*params(2)*getPowerDeriv(y(2),params(2)-1,1)));
g1_v(7)=(-(T(4)*getPowerDeriv(y(2),params(2),1)));
g1_v(8)=(-1);
g1_v(9)=1;
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 4, 4);
end
end
