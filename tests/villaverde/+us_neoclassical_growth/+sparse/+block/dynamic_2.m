function [y, T, residual, g1] = dynamic_2(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(3, 1);
  T(1)=x(1)^(1-params(2));
  y(8)=y(7)^params(2)*T(1);
  residual(1)=(y(6)+y(9))-(y(8));
  residual(2)=(y(9)+(1-params(3))*y(2))-(y(7)*(1+x(3))*(1+x(2)));
  T(2)=params(1)*y(11)^(-1);
  T(3)=y(15)^(1-params(2));
  T(4)=1+params(2)*y(7)^(params(2)-1)*T(3)-params(3);
  residual(3)=((1+x(3))*y(6)^(-1))-(T(2)*T(4));
if nargout > 3
    g1_v = NaN(9, 1);
g1_v(1)=1-params(3);
g1_v(2)=1;
g1_v(3)=1;
g1_v(4)=(-(T(1)*getPowerDeriv(y(7),params(2),1)));
g1_v(5)=(-((1+x(3))*(1+x(2))));
g1_v(6)=(-(T(2)*T(3)*params(2)*getPowerDeriv(y(7),params(2)-1,1)));
g1_v(7)=1;
g1_v(8)=(1+x(3))*getPowerDeriv(y(6),(-1),1);
g1_v(9)=(-(T(4)*params(1)*getPowerDeriv(y(11),(-1),1)));
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 3, 9);
end
end
