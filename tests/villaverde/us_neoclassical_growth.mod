var c k y i;
varexo l n g;

parameters beta theta delta;

beta = 0.944;  // Discount factor to match 7.7% return to capital
theta = 0.39;  // Capital share
delta = 0.04;  // Depreciation rate

model;
// Production function (normalized)
y = k^theta * l^(1-theta);

// Resource constraint
c + i = y;

// Capital accumulation
i + (1-delta)*k(-1) = (1+g)*(1+n)*k;

// Euler equation
c^(-1) * (1+g) = beta * c(+1)^(-1) * (theta * k^(theta-1) * l(+1)^(1-theta) + 1-delta);
end;

initval;
l = 0.67; // Initial working-age ratio (1991)
n = 0.0094; // Population growth rate (1991)
g = 0.0165; // Technology growth rate
k = ((1/beta * (1+g) - (1-delta))/(theta * l^(1-theta)))^(1/(theta-1)); // Steady-state capital
y = k^theta * l^(1-theta); // Steady-state output
i = ((1+g)*(1+n) - (1-delta)) * k; // Steady-state investment
c = y - i; // Steady-state consumption
end;

steady;
check;

endval;
l = 0.65; // Final working-age ratio (2019)
n = 0.0070; // Population growth rate (2019)
g = 0.0165; // Same technology growth rate
k = ((1/beta * (1+g) - (1-delta))/(theta * l^(1-theta)))^(1/(theta-1)); // Steady-state capital
y = k^theta * l^(1-theta); // Steady-state output
i = ((1+g)*(1+n) - (1-delta)) * k; // Steady-state investment
c = y - i; // Steady-state consumption
end;

steady;
check;

// Exogenous variables evolution (linear transition for l and n)
shocks;
var l;
periods 1:28;
values (linspace(0.67, 0.65, 28));
var n;
periods 1:28;
values (linspace(0.0094, 0.0070, 28));
var g;
periods 1:28;
values 0.0165;
end;

perfect_foresight_setup(periods=28);
perfect_foresight_solver(maxit=100, stack_solve_algo=0);

rplot c k y i;