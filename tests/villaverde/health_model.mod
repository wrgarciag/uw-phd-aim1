// Dynare model for Atolia, Papageorgiou, and Turnovsky (2019)
// "Taxation and Public Health Investment: Policy Choices and Tradeoffs"
// Deterministic model for steady state and transitional dynamics
// File: health_model.mod

// Declare variables
var c l h k m lambda mu L e y p w r T;
varexo g; // Only g is exogenous for the policy experiment

// Declare parameters
parameters alpha beta gamma psi_l psi_h A B theta_0 sigma delta_k delta_m n;
parameters tau_k tau_w tau_c s g_bar;

// Calibration (based on typical US economy values and paper's indications)
alpha = 0.33;       // Capital share in final output
beta = 0.05;        // Health productivity elasticity (benchmark)
gamma = 0.5;        // Health capital share in health production
psi_l = 1.0;        // Utility weight on leisure
psi_h = 0.5;        // Utility weight on health
A = 1.0;            // TFP in final output
B = 1.0;            // TFP in health production
theta_0 = 0.04;     // Base time preference rate
sigma = 1.0;        // Health impact on time preference (reduced for stability)
delta_k = 0.08;     // Depreciation rate of physical capital
delta_m = 0.08;     // Depreciation rate of health capital
n = 0.01;           // Population growth rate
tau_k = 0.30;       // Capital tax rate
tau_w = 0.224;      // Labor tax rate (from paper)
tau_c = 0.05;       // Consumption tax rate
s = 0.64;           // Health subsidy rate (from paper)
g_bar = 0.03;       // Health investment as fraction of GDP (initial)

// Model block
model;
// Utility marginal conditions
c^(-1) = lambda * (1 + tau_c);                                        // (4a) Marginal utility of consumption
psi_l * l^(-1) = lambda * (1 - tau_w) * w;                            // (4b') Marginal utility of leisure
((1 - s) / (1 - tau_w)) * psi_l * l^(-1) = (psi_h * h^(-1) - mu * sigma) * (1 - gamma) * B * m^gamma * e^(-gamma); // (4c') Health investment condition

// Production: final output
y = A * k^alpha * L^(1 - alpha) * h^beta;                             // (6) Output production function
r = alpha * A * k^(alpha - 1) * L^(1 - alpha) * h^beta;              // (7a) Return to capital
w = (1 - alpha) * A * k^alpha * L^(-alpha) * h^beta;                 // (7b) Wage rate

// Production: health services
h = B * m^gamma * e^(1 - gamma);                                     // (7c) Health production function
p * (1 - gamma) * B * m^gamma * e^(-gamma) = w;                      // (7d) Health sector labor demand

// Labor market clearing
L + e = 1 - l;                                                       // (10) Labor allocation

// Capital accumulation
k(+1) - k = (1 - g) * y - c - (n + delta_k) * k;                     // (11) Physical capital dynamics

// Health capital accumulation
m(+1) - m = g * y - (n + delta_m) * m;                               // (9) Health capital dynamics

// Co-state dynamics
lambda(+1) / lambda = 1 + theta_0 - sigma * h + n + delta_k - r * (1 - tau_k); // (4d') Euler equation for lambda
mu(+1) / mu = 1 + theta_0 - sigma * h + (log(c) + psi_l * log(l) + psi_h * log(h)) / mu; // (4e') Euler equation for mu

// Government budget constraint (lump-sum tax adjusts residually)
T = g * y + s * p * h - tau_k * r * k - tau_w * w * (L + e) - tau_c * c - p * (h - (1 - gamma) * B * m^gamma * e^(1 - gamma));
end;

// Steady-state block (analytical solution, each variable assigned once)
steady_state_model;
// Guess key variables
h = 0.4;      // Health stock
l = 0.33;     // Leisure (1/3 of time endowment)
lambda = 1.5; // Shadow price of capital
L = 0.55;     // Labor in final goods (initial guess)

// (13h) Capital return condition
r = (theta_0 - sigma * h + n + delta_k) / (1 - tau_k);

// (13a) Marginal utility of consumption
c = ((1 + tau_c) * lambda)^(-1);

// (13b) Marginal utility of leisure
w = psi_l * l^(-1) / (lambda * (1 - tau_w));

// (7b) Solve for capital
k = ((w / ((1 - alpha) * A * L^(-alpha) * h^beta))^(1/alpha))^(1/(1-alpha));

// (13g) Health capital accumulation
m = (g_bar * A * k^alpha * L^(1 - alpha) * h^beta) / (n + delta_m);

// (13d) Health production
e = (h / (B * m^gamma))^(1/(1 - gamma));

// (7d) Health sector labor demand
p = w / ((1 - gamma) * B * m^gamma * e^(-gamma));

// (10) Labor market clearing (adjust L)
L = 1 - l - e;

// (6) Output
y = A * k^alpha * L^(1 - alpha) * h^beta;

// (13c) Health investment condition
mu = (psi_h * h^(-1) - ((1 - s) / (1 - tau_w)) * psi_l * l^(-1) / ((1 - gamma) * B * m^gamma * e^(-gamma))) / sigma;

// Government budget (T adjusts residually)
T = g_bar * y + s * p * h - tau_k * r * k - tau_w * w * (L + e) - tau_c * c - p * (h - (1 - gamma) * B * m^gamma * e^(1 - gamma));
end;

// Initial values (fallback if steady_state_model fails)
initval;
c = 0.7;        // Consumption
l = 0.33;       // Leisure
h = 0.4;        // Health stock
k = 8;          // Physical capital
m = 1.5;        // Health capital
lambda = 1.5;   // Shadow price of capital
mu = -8;        // Shadow price of time preference
L = 0.55;       // Labor in final goods
e = 0.12;       // Labor in health sector
y = 0.9;        // Output
p = 1.2;        // Price of health services
w = 1.1;        // Wage
r = 0.04;       // Return to capital
T = 0.1;        // Lump-sum tax
g = g_bar;
end;

// Compute steady state
steady(maxit=1000);

// Check residuals and eigenvalues
check;

// Policy experiment: Increase g from 3% to 4% of GDP
shocks;
var g;
periods 1:100;
values 0.04;
end;

// Simulate transitional dynamics
perfect_foresight_setup(periods=200);
perfect_foresight_solver;

// Plot results
rplot c l h k m y;










