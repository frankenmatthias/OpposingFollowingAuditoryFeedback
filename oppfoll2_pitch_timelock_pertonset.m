function f0data_locked = oppfoll2_pitch_timelock_pertonset(f0data, subject)
%
% Locks trialdata to perturbation onsets (defined in column 6 and/or 7 of
% the trialinfo matrix)
%
% MKF, 2018

if nargin < 2
    error('Specify subject!');
end
subjinfo = oppfoll2_subjectinfo(subject);
    
onsets = NaN * ones(size(f0data.trialinfo(:,6)));

if size(f0data.trialinfo, 2) == 6
    if exist(fullfile(subjinfo.datadir.project, 'Analysis', 'artifacts', ['pitch_' subjinfo.name '_cfg.mat']), 'file')
        load(fullfile(subjinfo.datadir.project, 'Analysis', 'artifacts', ['pitch_' subjinfo.name '_cfg.mat']));
        onsets(~(isnan(f0data.trialinfo(:,5)))) = cfga.previous.previous.offset;
    else
        f0data.trialinfo = oppfoll2_fakepertonsets(f0data.trialinfo);
        onsets(~(isnan(f0data.trialinfo(:,5)))) = -f0data.trialinfo(:,7)*f0data.fsample;
    end
else
    assert(size(f0data.trialinfo, 2) == 7);
end

cfg=[];
cfg.offset = onsets;
f0data_locked = ft_redefinetrial(cfg, f0data);