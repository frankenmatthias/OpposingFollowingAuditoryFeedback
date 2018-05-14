function dat = oppfoll2_read_pitchdata(fname)
%
% input 'fname' should be path to Table of Real file (Praat output)
%
%
%
% MKF, 2017


    fid = fopen(fname);
    for i = 1:8
        line = fgetl(fid);
        
    end
    fclose(fid);
    line = line(13:end);
    dat = sscanf(line, '%f');
    
end