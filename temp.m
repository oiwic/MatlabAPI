%% temp1
data1 = (1+sin((1:32)/32*2*pi))*32767;
data2 =zeros(1,32);
data2(17:32) = 65535;

da = USTCDAC('10.0.1.219',80);
da.Open();
seq = USTCADDA.GenerateContinusSeq(32);
da.WriteSeq(1,0,seq);
da.StartStop(1);
for k = 1:1
    da.WriteWave(0,0,data1);
    pause(1);
    da.WriteWave(0,0,data2);
    pause(1);
end

%% temp2
data2 =zeros(1,32);
data2(17:32) = 65535;

da = USTCDAC('10.0.1.219',80);
da.Open();
da.SetIsMaster(1);
seq = USTCADDA.GenerateTrigSeq(32,0);
da.WriteSeq(1,0,seq);
da.WriteWave(1,0,data2);
da.SetLoop(1,1,1,1);
da.StartStop(1);
da.SendIntTrig();
