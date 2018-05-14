function f0data = oppfoll2_pitch2ft(subject, block)
%
% Loads pitch data from Table Of Real files and formats so it is readable
% by fieldtrip functions for later processing (http://www.fieldtriptoolbox.org/).
%
% Output contains among others a trialinfo field with columns: Condition, TrialType, ToneFq,
% TrialNum, Speechonset(in s), and Pertonset(in s).
%
% MKF, 2017

subjinfo = oppfoll2_subjectinfo(subject);

if nargin < 2
    block = 'rand1';
end

load(fullfile(subjinfo.datadir.behav, 'expt.mat')); %load expt info

filenames = oppfoll2_sort_filenames(fullfile(subjinfo.datadir.behav, block, 'rep1\'));


f0data = struct;
f0data.label = {'pitch'};
f0data.fsample = 1000;

for t = 1:size(filenames, 1)
    filename = deblank(filenames{t,:});
    load(fullfile(subjinfo.datadir.behav, block, 'rep1', filename));
    
    pitchfname = fullfile(subjinfo.datadir.behav, block, 'rep1', [filename(1:(end-4)) '.TableOfReal']);
    
    fprintf('Reading data from %s...\n', pitchfname);
    f0data.trial{1,t} = oppfoll2_read_pitchdata(pitchfname)';
    
    % interpolate for single missing samples
    f0data.trial{1,t} = oppfoll2_interpolate_pitch(f0data.trial{1,t}, 1);
    
    f0data.time{1,t} = [0:0.001:(0.001*(length(f0data.trial{1,t})-1))];
    if t==1
        f0data.sampleinfo(t,1:2) = [1 length(f0data.trial{1,t})];
    else
        f0data.sampleinfo(t,1:2) = [1 length(f0data.trial{1,t})] + f0data.sampleinfo((t-1),2);
    end
    
    % trialinfo
    speechonset = find(data.dataOut.ost_stat>=2,1) / data.dataOut.params.sr * data.dataOut.params.frameLen;
    if isempty(speechonset)
        speechonset = NaN;
    end
    pertonset = NaN;
    if isequal(data.trialType, 'pert')
        pertonset = (find(data.dataOut.ost_stat>=3,1)) / data.dataOut.params.sr * data.dataOut.params.frameLen;
        if isempty(pertonset)
            pertonset = NaN;
        end
    end
    
    if isequal(data.phase, 'rand1')
        b=subjinfo.group;
    elseif isequal(data.phase, 'rand2')
        b=-subjinfo.group+3;
    else
        b=0;
    end
    if isequal(data.trialType, 'pert')
        tt=1;
    else
        tt=0;
    end
    f0data.trialinfo(t,1:6) = [b,  tt, data.stimfq, data.trialNum, speechonset, pertonset];
    
end
