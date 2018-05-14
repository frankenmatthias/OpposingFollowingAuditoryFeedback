function f0series_new = oppfoll2_interpolate_pitch(f0series, max_samples)
%
% Interpolates missing pitch samples, with maximal max_samples in a row
% (default = 1);
%
%
%
%
% MKF, 2017


firstgoodsmpl = find(f0series~=0,1);
lastgoodsmpl = find(f0series~=0,1,'last');
f0series_new = f0series;
if lastgoodsmpl > firstgoodsmpl
    for i = firstgoodsmpl:lastgoodsmpl
        
        if f0series_new(i)==0
            last = find(f0series_new(firstgoodsmpl:i)~=0,1,'last')+(firstgoodsmpl-1);
            next = find(f0series_new(i:lastgoodsmpl)~=0,1,'first')+(i-1);
            if (next-last)<=(max_samples+1)
                f0series_new((last+1):(next-1)) = interp1([0 (next-last)*0.001],[f0series_new(last) f0series(next)], [1:((next-last)-1)]*0.001);
            end
        end
    end
end

if 0
    figure;
    plot(f0series, 'b');
    hold on
    plot(f0series_new, 'r');
end