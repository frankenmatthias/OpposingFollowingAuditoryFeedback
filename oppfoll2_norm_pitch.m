function f0data = oppfoll2_norm_pitch(f0data_bl, f0data_woi)
%
% Normalizes pitch by expressing data in f0data_woi in cents, relative to
% average over corresponding trials in f0data_bl.
%
%
%
%
% MKF, 2017

assert(length(f0data_bl.trial) == length(f0data_woi.trial));
ntrials = length(f0data_bl.trial);
f0data = f0data_woi;
for trial=1:ntrials
    
    baseline_average = nanmean(f0data_bl.trial{trial});
    f0data.trial{trial} = 1200 * log2(f0data_woi.trial{trial} ./ baseline_average);
    
end