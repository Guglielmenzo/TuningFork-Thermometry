function [f_drive, state] = Tracker_VNA(state, lock, p)
    
    if isEmpty(state)
        init(p);
    else
        state = update(state,lock,p);
    end
    f_drive = state.f_list(state.k)
    
end

function init(state, p)
    state.f0 = p.f0_nom;                                 % Nominal resonant frequency 
    state.width = 250;                                   % Complete guess
    state.n = 25;                                        % Number of frequency points 
    state.k = 1;                                         % Current position in the sweep
    state.count = 0;                                     % Number of sweeps completed
    state.f_list = state.f0 + (-12:12) * state.width/4;  % List of all swept frequencies
    state.n_settle = ceil(5/(pi*state.width)/p.T_block); % 5 time constants
    state.A_list   = zeros(1, state.n);                  % List of amplitudes
    state.phi_list = zeros(1, state.n);                  % List of phases
    state.gain  = p.G(end);                              % Picks which gain to start on
    state.X_sum = 0;  state.Y_sum = 0;                   % Running sums for X and Y
    
end 

function update(state, lock, p)
    state.k = state.k + 1;                               % Current position in the sweep
    state.count = state.count + 1;                       % Number of sweeps completed
end