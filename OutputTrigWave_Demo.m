da = USTCDAC('10.0.2.5',80);
da.Open();
da.Init();
da.SetIsMaster(1);
da.SetTrigSel(3);%3 sma£¬0 rj45

da.StartStop(15);
waveobj = waveform();
data = waveobj.generate_squr();
seq = waveobj.generate_trig_seq(length(data),0);
num = 0;
while(1)
    for k = 1:4
        da.WriteWave(k,0,[data,ones(1,16)*32768]);
        da.WriteSeq(k,0,seq);
    end
    da.CheckStatus();
    da.SendIntTrig();
    num = num + 1;
    disp(num);
end