function [p,m,s,D,z] = changePoint(data, doplot, time, woi)
%
% Castellan change-point test
% data is time series
% m is sample number of change-point
% p is associated p-value (H0 = no change in time series)
%
% see Siegel, S. and Castellan, N.J., Jr. (1988). Nonparametric Statistics
% for the Behavioral Sciences. (2nd Edition). New York: McGraw-Hill.
% Section 4.6.3, pp. 67 - 70. 
%
if nargin<4
    if nargin < 3
        time = 1:length(data);
        if nargin < 2
            doplot = 0;
        end
    end
    woi = [time(1) time(end)];
end

woisamples = [find(time>=woi(1),1), find(time<=woi(2),1,'last')];

N = length(data);
[~, ~, ranks] = unique(data);


W = cumsum(ranks);
D = 2*W - (1:N)'*(N+1);

Ddiff = diff(abs(D(woisamples(1):woisamples(2))));
Ddiffdiff = diff(Ddiff);
icrossings = crossing(Ddiff);
icrossings = icrossings([Ddiffdiff(icrossings)<0]);
icrossings = [icrossings icrossings+1] + woisamples(1) - 1;


[~, m] = max(abs(D(icrossings)));
m = icrossings(m);
if isempty(m)
    m = NaN;
    z=NaN;
    p=NaN;
    s=0;
    return;
end

n = N - m;

if W(m) > m*(N + 1)/2
    h = -1/2;
else
    h=1/2;
end    
    
z = (W(m) + h - m*(N+1)/2) / (sqrt(m*n*(N+1)/12));
p = 1-normcdf(abs(z));

s = sign(D(m));

if doplot
    figure('Color', 'w');
    subplot(2,1,1);
    plot(time,data);
    hold on
    plot([0 0], [-25 25], 'k');
    plot([.5 .5], [-25 25], 'k');
    plot(time(m), 0, 'r*');
    subplot(2,1,2);
    plot(time,D, 'k');
    hold on
    plot(time,abs(D), 'r');
    title(sprintf('Change-Point = %0.3f', time(m)));
end
end