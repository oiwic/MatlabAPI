da = USTCDAC('10.0.2.7',80);
da.Open();
da.Init();
da.SetIsMaster(1);
da.SetTrigSel(0);
data  = 1:64000;
seq = waveobj.generate_trig_seq(length(data),0);
for k = 1:4
    da.WriteWave(k,0,[data,ones(1,16)*32768]);
    da.WriteSeq(k,0,seq);
end
da.StartStop(15);
da.CheckStatus();
da.SendIntTrig();