windowstart = 8;
windowlength = 8000;
sampledepth = windowlength + windowstart;
triggercount = 1000;
ad = USTCADC('68-05-CA-47-45-9A','00-00-00-00-00-00');
ad.Open();
ad.Init();
ad.SetMode(1);
ad.SetSampleDepth(sampledepth);
ad.SetTrigCount(triggercount);

da = USTCDAC('10.0.2.5',80);
da.Open();
da.Init();
da.SetIsMaster(1);
da.SetTrigSel(3);

%% 生成并发送测试波形
testfreq = 100e6;
waveobj = waveform();
seq = waveobj.generate_trig_seq(sampledepth*2,0);
waveI = zeros(1,sampledepth*2+16);
waveQ = zeros(1,sampledepth*2+16);
for k= 1:length(testfreq)
    waveobj.frequency = testfreq(k);
    x = (1:length(waveI))*testfreq(k)/2e9*2*pi;
    waveI = waveI + 32767.5*cos(x);
    waveQ = waveQ + 32767.5*sin(x);
end
waveI = waveI/length(testfreq) + 32767.5;
waveQ = waveQ/length(testfreq) + 32767.5;
waveI((sampledepth*2+1):(sampledepth*2+16)) = 32768;
waveQ((sampledepth*2+1):(sampledepth*2+16)) = 32768;
da.SetTrigCount(triggercount);
da.WriteWave(3,0,waveI);
da.WriteWave(4,0,waveQ);
da.WriteSeq(3,0,seq);
da.WriteSeq(4,0,seq);

%% 硬件解模频率
frequency = linspace(99.9,100.1,11)*1e6;
da.StartStop(240);
da.StartStop(15);
da.CheckStatus();
ad.SetWindowWidth(windowlength);
ad.SetWindowStart(windowstart);
for k = 1:length(frequency)
    ad.SetDemoFre(frequency(k));
    ad.CommitDemodSet(k-1);
end
ad.EnableADC();
da.SendIntTrig();
[ret,I,Q] = ad.RecvData();
subplot(2,1,1);
bar(sqrt(mean(I,2).^2 + mean(Q,2).^2)/2^18/windowlength);
%% 软件解模频率
da.StartStop(240);
da.StartStop(15);
ad.SetMode(0);
da.CheckStatus();
dataI = zeros(1,12);
dataQ = zeros(1,12);
for k = 1:length(frequency)
    ad.EnableADC();
    da.SendIntTrig();
    [ret,I,Q] = ad.RecvData();
    t = (1:windowlength)*frequency(k)/1e9*2*pi;
    sine = sin(t');
    cose = cos(t');
    dataI(k) = mean(double(I(:,(1+windowstart):sampledepth))*cose) + mean(double(Q(:,(1+windowstart):sampledepth))*sine);
    dataQ(k) = mean(double(Q(:,(1+windowstart):sampledepth))*cose) - mean(double(I(:,(1+windowstart):sampledepth))*sine);
end
subplot(2,1,2);
bar(sqrt(dataI.^2 + dataQ.^2)/128/windowlength);
%%
ad.Close();
da.Close();

