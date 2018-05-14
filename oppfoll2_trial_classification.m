function oppfoll2_trial_classification(subject, control)
%
% This function attempts to classify single trial data as having either an
% upward or a downward response. The results are saved in a *.mat file.
%
% MKF, 2017



%% parameters
if nargin < 2
    control = false;
end
trialwindow = [-0.2 1];
baselinewindow = [-0.2 0];
responsewindow = [0.07 0.5];

%% Get data

% get subject info
subjinfo = oppfoll2_subjectinfo(subject);

% load f0data
load(fullfile(subjinfo.datadir.project, 'Analysis', 'f0data', [subjinfo.name '.mat']));

%load artifact definitions
load(fullfile(subjinfo.datadir.project, 'Analysis', 'artifacts', ...
    ['pitch_' subjinfo.name '_cfg.mat']));

%% Normalize and get time window

% time-lock to perturbation onset
f0data_po = oppfoll2_pitch_timelock_pertonset(f0data, subject);

%select trials
cfg=[];
cfg.trials = ~(isnan(f0data.trialinfo(:,5))); %reject trials without speech onset
f0data_po2 = ft_redefinetrial(cfg, f0data_po);

% get baseline
cfg=[];
cfg.toilim = trialwindow;
f0data_woi = ft_redefinetrial(cfg, f0data_po2);

% remove linear trend across entire trial
for t = 1:length(f0data_woi.trial)
    f0data_woi.trial{t} = detrend(f0data_woi.trial{t})+mean(f0data_woi.trial{t});
    %f0data_woi.trial{t} = round(-1.5 + f0data_woi.trialinfo(t,1)) * f0data_woi.trial{t};
end

cfg=[];
cfg.toilim = baselinewindow;
f0data_bl = ft_redefinetrial(cfg, f0data_woi);

% normalize relative to baseline (i.e. to cents)
f0data_woi_norm = oppfoll2_norm_pitch(f0data_bl, f0data_woi);

% reject artifacts
cfga.artfctdef.reject = 'complete';
f0data_woi_clean = ft_rejectartifact(cfga, f0data_woi_norm);

cfgp=[];
cfgp.rectify = 'yes';
f0data_woi_clean = ft_preprocessing(cfgp, f0data_woi_clean);

cfg=[];
cfg.trials = f0data_woi_clean.trialinfo(:,2)==1;
tlk_pert = ft_timelockanalysis(cfg, f0data_woi_clean);
cfg.trials = f0data_woi_clean.trialinfo(:,2)==0;
tlk_contr = ft_timelockanalysis(cfg, f0data_woi_clean);

%%

f = figure('Color', 'w');
subplot(3,1,1)
cfg=[];
cfg.interactive='no';
ft_singleplotER(cfg, tlk_contr, tlk_pert);
set(gca, 'YLim', [0 35], 'XLim', [-.2 1]);
%plot(median(cell2mat(f0data_woi_clean.trial(f0data_woi_clean.trialinfo(:,2)==1)')))

window = [find(tlk_pert.time>=0.15, 1):find(tlk_pert.time<=0.4, 1, 'last')];
[~, smpl] = max(tlk_pert.avg(window));
maxtime = tlk_pert.time(smpl+window(1)-1);

hold on
plot([0.06 maxtime],[tlk_pert.avg([find(tlk_pert.time>=0.06,1) smpl+window(1)-1])], '*-k')
title(sprintf('%s -- window: [%0.2f %0.2f]', subject, 0.06, maxtime));
ylabel('Mean of rectified trials');
legend('control', 'perturbed', 'slope', 'Location', 'SouthEast');

%%
cfga.artfctdef.reject = 'complete';
f0data_woi_clean = ft_rejectartifact(cfga, f0data_woi_norm);

if ~control
    perttrials = find(f0data_woi_clean.trialinfo(:,2)==1);
elseif control
    perttrials = find(f0data_woi_clean.trialinfo(:,2)==0); % "fake" pert trials!
end
chpts = NaN*ones(size(perttrials));
zs = NaN*ones(size(perttrials));
down = NaN*ones(size(perttrials));
resp2 = NaN*ones(size(perttrials));

if ~control && exist(sprintf('%s/%s.mat', 'trialclass', subject), 'file')
        load(sprintf('%s/%s.mat', 'trialclass', subject));
elseif control && exist(sprintf('%s/%s_control.mat', 'trialclass', subject), 'file')
        load(sprintf('%s/%s_control.mat', 'trialclass', subject));
else

    slopes=[];
for t = 1:length(perttrials)
    
        foodata = f0data_woi_clean.trial{perttrials(t)};
        footime = f0data_woi_clean.time{perttrials(t)};      
        
        % slope in time window [0.060 0.250]
        window1time = [0.06 maxtime];
        window1 = [find(footime>=window1time(1), 1) find(footime<=window1time(2),1,'last')];
        coeffs = polyfit(footime(window1(1):window1(2)), foodata(window1(1):window1(2)),1);
        if coeffs(1) < 0
            down(t) = 1;
        else
            down(t) = 0;
        end
        slopes(t) = coeffs(1);

        
        % change-point
        woi = [0 0.3];
        [p,m,dir,stat,z] = changePoint(foodata,0,footime,woi);
        resp2(t) = dir;
        zs(t) = z;
        
        if dir ~= 0
        chpts(t) = footime(m);
        
        
        switch resp2(t)
            case 1
                down2 = 1;
            case -1
                down2 = 0;
            case 0
                down2 = NaN;
        end
        
        if down(t) ~= down2
            figure('Color', 'w');
            subplot(2,1,1);
            plot(footime, foodata);
            hold on
            plot(window1time,polyval(coeffs, window1time),'r*-');
            plot([0 0], [-40 40], 'k--');
            plot([0.5 0.5], [-40 40], 'k--');
            set(gca, 'XLim', [-.2 1], 'YLim', [-40 40]);
            title(sprintf('trial %d (down = %d)', t, down(t)));
            
            subplot(2,1,2);
            plot(footime, abs(stat), 'k');
            hold on
            plot(footime, stat, 'b');
            plot(footime(m) , stat(m), 'r*');
            set(gca, 'XLim', [-.2 1]);
            title(sprintf('value = %0.0f at %0.3fs (down = %d)', stat(m), footime(m), down2));
            
            userinput = questdlg('category?','Trial Categorization','Down','Up','No Response','Down');
            switch userinput
                case 'Down'
                    resp2(t) = 1;
                case 'Up'
                    resp2(t) = -1;
                case 'No Response'
                    resp2(t) = 0;
            end
            close
        end
        else
            chpts(t) = NaN;
        end
end

if ~ control
    save(sprintf('%s/%s.mat', 'trialclass', subject), 'resp2', 'down', 'perttrials');
elseif control
    controltrials = perttrials;
    resp2_control = resp2;
    save(sprintf('%s/%s_control.mat', 'trialclass', subject), 'resp2_control', 'down', 'controltrials');
end

cfg=[];
cfg.trials = find(f0data_woi_clean.trialinfo(:,2)==0);
tlk_contr = ft_timelockanalysis(cfg, f0data_woi_clean);
cfg.trials = perttrials(down==1);
tlk_oppos = ft_timelockanalysis(cfg, f0data_woi_clean);
cfg.trials = perttrials(down==0);
tlk_foll = ft_timelockanalysis(cfg, f0data_woi_clean);

subplot(3,1,2);
cfg=[];
cfg.interactive='no';
ft_singleplotER(cfg, tlk_contr, tlk_foll, tlk_oppos);
set(gca, 'YLim', [-25 25], 'XLim', [-.2 1]);
title(sprintf('slope -- %d down out of %d', length(perttrials(down==1)), length(perttrials)));
hold on
plot([0 0], [-25 25], 'k--');
plot([.5 .5], [-25 25], 'k--');
legend('control', 'up', 'down', 'Location', 'EastOutside');
ylabel('Mean F0 deviation (cents)');

cfg=[];
cfg.trials = find(f0data_woi_clean.trialinfo(:,2)==0);
tlk_contr = ft_timelockanalysis(cfg, f0data_woi_clean);
cfg.trials = perttrials(resp2==1);
tlk_oppos2 = ft_timelockanalysis(cfg, f0data_woi_clean);
cfg.trials = perttrials(resp2==-1);
tlk_foll2 = ft_timelockanalysis(cfg, f0data_woi_clean);


subplot(3,3,[7 8]);
cfg=[];
cfg.interactive='no';
ft_singleplotER(cfg, tlk_contr, tlk_foll2, tlk_oppos2);
set(gca, 'YLim', [-25 25], 'XLim', [-.2 1]);
title(sprintf('change-point -- %d down out of %d (%d null)', length(perttrials(resp2==1)), length(perttrials), length(perttrials(resp2==0))));
hold on
plot([0 0], [-25 25], 'k--');
plot([.5 .5], [-25 25], 'k--');
%legend('control', 'follow', 'oppose', 'Location', 'SouthEast');
ylabel('Mean F0 deviation (cents)');

subplot(3,3,9);
hist(chpts);
xlabel('change-points');
set(gca, 'XLim', woi);

drawnow
if ~control
print(f, sprintf('%s/%s-summary-slopes', 'testplots', subject), '-djpeg');
elseif control
    print(f, sprintf('%s/%s-summary-slopes_control', 'testplots', subject), '-djpeg');
end

end