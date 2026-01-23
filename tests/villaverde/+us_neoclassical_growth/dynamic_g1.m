function g1 = dynamic_g1(T, y, x, params, steady_state, it_, T_flag)
% function g1 = dynamic_g1(T, y, x, params, steady_state, it_, T_flag)
%
% File created by Dynare Preprocessor from .mod file
%
% Inputs:
%   T             [#temp variables by 1]     double   vector of temporary terms to be filled by function
%   y             [#dynamic variables by 1]  double   vector of endogenous variables in the order stored
%                                                     in M_.lead_lag_incidence; see the Manual
%   x             [nperiods by M_.exo_nbr]   double   matrix of exogenous variables (in declaration order)
%                                                     for all simulation periods
%   steady_state  [M_.endo_nbr by 1]         double   vector of steady state values
%   params        [M_.param_nbr by 1]        double   vector of parameter values in declaration order
%   it_           scalar                     double   time period for exogenous variables for which
%                                                     to evaluate the model
%   T_flag        boolean                    boolean  flag saying whether or not to calculate temporary terms
%
% Output:
%   g1
%

if T_flag
    T = us_neoclassical_growth.dynamic_g1_tt(T, y, x, params, steady_state, it_);
end
g1 = zeros(5, 11);
g1(1,3)=(-(T(2)*getPowerDeriv(y(3),params(2),1)));
g1(1,4)=1;
g1(1,9)=(-(T(1)*getPowerDeriv(x(it_, 1),1-params(2),1)));
g1(2,2)=1;
g1(2,4)=(-1);
g1(2,5)=1;
g1(3,1)=1-params(3);
g1(3,3)=(-((1+x(it_, 3))*(1+x(it_, 2))));
g1(3,5)=1;
g1(3,10)=(-(y(3)*(1+x(it_, 3))));
g1(3,11)=(-(y(3)*(1+x(it_, 2))));
g1(4,2)=(1+x(it_, 3))*getPowerDeriv(y(2),(-1),1);
g1(4,7)=(-(T(7)*params(1)*getPowerDeriv(y(7),(-1),1)));
g1(4,3)=(-(T(4)*T(6)*params(2)*getPowerDeriv(y(3),params(2)-1,1)));
g1(4,11)=T(3);
g1(4,8)=(-(T(4)*T(5)*getPowerDeriv(y(8),1-params(2),1)));
g1(5,9)=(-1);
g1(5,6)=1;

end
