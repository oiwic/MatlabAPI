da = USTCDAC('10.0.2.2',80);
da.Open();
da.Init();
da.SetTrigSel(0);
da.StartStop(15);
waveobj = waveform();
waveobj.amplitude = 0;
waveobj.frequency = 100e6;
data = waveobj.generate_sine();
seq = waveobj.generate_seq(length(data));
num = 0;
for k = 1:4
    da.WriteWave(k,0,data);
    da.WriteSeq(k,0,seq);
end
da.CheckStatus();
da.Close();
