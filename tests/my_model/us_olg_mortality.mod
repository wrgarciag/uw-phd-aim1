% OLG Model for U.S. Economy with 50% Premature Mortality Reduction
% Simplified to 5 generations, calibrated to U.S. data

% Define endogenous variables
var 
    c_1 c_2 c_3 c_4 c_5    % Consumption (1-5)
    l_1 l_2 l_3            % Labor supply (6-8)
    a_1 a_2 a_3 a_4 a_5    % Assets (9-13)
    h_1 h_2 h_3 h_4 h_5    % Health status (14-18)
    K L Y C I              % Capital, Labor, Output, Cons, Inv (19-23)
    G T B                  % Govt spending, Taxes, Debt (24-26)
    r w                    % Interest rate, Wage (27-28)
    U;                     % Aggregate utility (29)

% Define parameters
parameters 
    beta delta alpha sigma psi phi 
    s_1 s_2 s_3 s_4 s_5    
    s_new_1 s_new_2 s_new_3 s_new_4 s_new_5 
    epsilon_1 epsilon_2 epsilon_3 
    g_h A N_1 N_2 N_3 N_4 N_5 
    tau_k tau_l pension;

% Calibration
beta = 0.96;
delta = 0.08;
alpha = 0.33;
sigma = 2;
psi = 0.5;      % Leisure preference
phi = 0.3;      % Health utility weight
A = 1;
g_h = 0.05;

% Baseline survival probabilities
s_1 = 0.999; s_2 = 0.995; s_3 = 0.98; s_4 = 0.90; s_5 = 0.60;
% 50% premature mortality reduction
s_new_1 = 0.9995; s_new_2 = 0.9975; s_new_3 = 0.99; s_new_4 = 0.90; s_new_5 = 0.60;

epsilon_1 = 0.7; epsilon_2 = 0.9; epsilon_3 = 1.0;

tau_k = 0.2; tau_l = 0.25; pension = 0.05;

N_1 = 0.2; N_2 = 0.2; N_3 = 0.2; N_4 = 0.2; N_5 = 0.2;

% Model equations
model;
  % 1. Household optimization
  c_1^(-sigma) = beta * s_1 * (1 + r*(1-tau_k)) * c_2^(-sigma);
  c_2^(-sigma) = beta * s_2 * (1 + r*(1-tau_k)) * c_3^(-sigma);
  c_3^(-sigma) = beta * s_3 * (1 + r*(1-tau_k)) * c_4^(-sigma);
  c_4^(-sigma) = beta * s_4 * (1 + r*(1-tau_k)) * c_5^(-sigma);

  % Labor supply
  psi/(1-l_1) = c_1^(-sigma) * w * epsilon_1 * (1-tau_l);
  psi/(1-l_2) = c_2^(-sigma) * w * epsilon_2 * (1-tau_l);
  psi/(1-l_3) = c_3^(-sigma) * w * epsilon_3 * (1-tau_l);

  % Budget constraints
  a_2 = (1 + r*(1-tau_k))*a_1 + w*epsilon_1*l_1*(1-tau_l) - c_1;
  a_3 = (1 + r*(1-tau_k))*a_2 + w*epsilon_2*l_2*(1-tau_l) - c_2;
  a_4 = (1 + r*(1-tau_k))*a_3 + w*epsilon_3*l_3*(1-tau_l) - c_3;
  a_5 = (1 + r*(1-tau_k))*a_4 + pension - c_4;
  c_5 = (1 + r*(1-tau_k))*a_5 + pension;

  % 2. Health dynamics
  h_1 = 1;
  h_2 = h_1 * s_1^0.1;
  h_3 = h_2 * s_2^0.1;
  h_4 = h_3 * s_3^0.1;
  h_5 = h_4 * s_4^0.1;

  % 3. Production
  Y = A * K^alpha * L^(1-alpha);
  r = alpha * A * (K/L)^(alpha-1) - delta;
  w = (1-alpha)*A*(K/L)^alpha;
  L = N_1*epsilon_1*l_1 + N_2*epsilon_2*l_2 + N_3*epsilon_3*l_3;
  K = N_1*a_1 + N_2*a_2 + N_3*a_3 + N_4*a_4 + N_5*a_5;
  C = N_1*c_1 + N_2*c_2 + N_3*c_3 + N_4*c_4 + N_5*c_5;

  % 4. Government budget
  G = g_h*(N_1+N_2+N_3+N_4+N_5) + pension*(N_4+N_5);
  T = tau_k*r*K + tau_l*w*L;
  B = G - T;

  % 5. Market clearing
  Y = C + I + G;
  I = delta*K;

  % 6. Utility aggregation
  U = N_1*((c_1^(1-sigma))/(1-sigma) + psi*log(1-l_1) + phi*log(h_1)) +
      N_2*((c_2^(1-sigma))/(1-sigma) + psi*log(1-l_2) + phi*log(h_2)) +
      N_3*((c_3^(1-sigma))/(1-sigma) + psi*log(1-l_3) + phi*log(h_3)) +
      N_4*((c_4^(1-sigma))/(1-sigma) + phi*log(h_4)) +
      N_5*((c_5^(1-sigma))/(1-sigma) + phi*log(h_5));
end;

% Initial guesses for steady state
initval;
  K = 2.5;
  L = 0.6;
  r = 0.04;
  w = 1.2;
  c_1 = 0.4;
  c_2 = 0.5;
  c_3 = 0.6;
  c_4 = 0.5;
  c_5 = 0.4;
  l_1 = 0.4;
  l_2 = 0.4;
  l_3 = 0.4;
  a_1 = 0;
  a_2 = 0.3;
  a_3 = 0.6;
  a_4 = 0.4;
  a_5 = 0;
  h_1 = 1;
  h_2 = 0.999;
  h_3 = 0.995;
  h_4 = 0.98;
  h_5 = 0.90;
  Y = 1.0;
  C = 0.5;
  I = 0.2;
  G = 0.15;
  T = 0.15;
  B = 0;
  U = -2;
end;

% Compute baseline steady state
steady(maxit=1000, tol=1e-8);

% Store baseline states
Y_baseline = oo_.steady_state(21);
U_baseline = oo_.steady_state(29);
B_baseline = oo_.steady_state(26);

% Check model
check;

% Simulate 50% mortality reduction
set_param_value('s_1', s_new_1);
set_param_value('s_2', s_new_2);
set_param_value('s_3', s_new_3);
set_param_value('s_4', s_new_4);
set_param_value('s_5', s_new_5);

% Compute new steady state
steady(maxit=1000, tol=1e-8);

% Display results
disp('Baseline vs. New Steady State');
disp(['Output: ', num2str(Y_baseline), ' vs. ', num2str(oo_.steady_state(21))]);
disp(['Welfare: ', num2str(U_baseline), ' vs. ', num2str(oo_.steady_state(29))]);
disp(['Debt: ', num2str(B_baseline), ' vs. ', num2str(oo_.steady_state(26))]);








