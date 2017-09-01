%% Test Speed
da = USTCDAC('10.0.2.7',80);
da.Open();
tic
for k = 1:4
    for kk = 1:4
        da.WriteWave(kk,0,zeros(1,20000)+32768);
%         da.WriteSeq(kk,0,zeros(1,16384)+32768);
    end
end
da.CheckStatus();
toc