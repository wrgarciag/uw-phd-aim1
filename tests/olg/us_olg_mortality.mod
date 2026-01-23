// Overlapping Generations (OLG) Model with CRRA Utility in Dynare
// Solves for steady state and simulates a 50% reduction in young mortality probability

// Declare endogenous variables
var k y w r c_y c_o s psi;

// Declare exogenous variable
varexo mu;

// Parameters
parameters alpha beta n delta theta mu_initial mu_new;
alpha = 0.33;     // Capital share
beta = 0.95;      // Discount factor
n = 0.01;         // Population growth rate
delta = 0.05;     // Depreciation rate
theta = 2.0;      // CRRA coefficient
mu_initial = 0.2; // Initial mortality probability
mu_new = 0.1;     // New mortality probability (50% reduction)

// Model equations
model;
    // Production function (per worker)
    y = k^alpha;
    
    // Wage
    w = (1 - alpha) * y;
    
    // Interest rate
    r = alpha * k^(alpha - 1) - delta;
    
    // Psi (auxiliary variable for savings)
    psi = ((1 - mu) * beta * (1 + r(+1))^(2 - theta))^(1/theta);
    
    // Young consumption
    c_y = w / (1 + psi);
    
    // Savings
    s = w - c_y;
    
    // Old consumption
    c_o = (1 + r) * s(-1);
    
    // Capital accumulation (per worker)
    k = s(-1) / (1 + n);
end;

// Initial steady state
initval;
    mu = mu_initial;
    k = 1.0;
    y = k^alpha;
    w = (1 - alpha) * y;
    r = alpha * k^(alpha - 1) - delta;
    psi = ((1 - mu) * beta * (1 + r)^(2 - theta))^(1/theta);
    c_y = w / (1 + psi);
    s = w - c_y;
    c_o = (1 + r) * s;
end;

// Compute initial steady state with robust solver
steady(solve_algo=4);

// Perfect foresight simulation
perfect_foresight_setup(periods=100);

// Define mortality shock
set_shocks;
    var mu;
    periods 1:100;
    values (mu_new);
end;

// Solve and simulate
perfect_foresight_solver;

// Plot impulse response functions
rplot k y w c_y c_o;

// Save results
save('olg_results.mat', 'k', 'y', 'w', 'c_y', 'c_o');