sampledepth = 4008;
windowstart = 8;
windowlength = 4000;
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
%% 随机选择测试频点
frequency = [252e6,197e6,89e6,76.9e6,54e6,33e6,23e6,13e6,7e6,4.3e6,2.2e6,1e6];
numberrnd = floor(12*rand())+1;
testfreq = sort(floor(rand(1,numberrnd)*12)+1);
for k= 1:numberrnd
    kk = k + 1;
    while(kk <= numberrnd && testfreq(k) == testfreq(kk))
        kk = kk+1;
    end
    testfreq(k+1:kk-1) = NaN;
end
testfreq(isnan(testfreq)) = [];
testtable = zeros(1,12);
testtable(testfreq) = 1;
subplot(3,1,1);
bar(testtable/length(testfreq));
title('DAC输出频率')
ylabel('分量成分')
xlabel('频率索引')
%% 生成并发送测试波形
waveobj = waveform();
seq = waveobj.generate_trig_seq(sampledepth*2,0);
waveI = zeros(1,sampledepth*2);
waveQ = zeros(1,sampledepth*2);
for k= 1:length(testfreq)
    waveobj.frequency = testfreq(k);
    x = (1:length(waveI))*frequency(testfreq(k))/2e9*2*pi;
    waveI = waveI + 32767.5*cos(x);
    waveQ = waveQ + 32767.5*sin(x);
end
waveI = waveI/length(testfreq) + 32767.5;
waveQ = waveQ/length(testfreq) + 32767.5;
waveI = [waveI, zeros(1,16)+32768];
waveQ = [waveQ, zeros(1,16)+32768];
da.SetTrigCount(triggercount);
da.WriteWave(3,0,waveI);
da.WriteWave(4,0,waveQ);
da.WriteSeq(3,0,seq);
da.WriteSeq(4,0,seq);

%% 硬件解模频率
da.StartStop(240);
da.StartStop(15);
da.CheckStatus();
ad.SetWindowWidth(windowlength);
ad.SetWindowStart(windowstart);
for k = 1:12
    ad.SetDemoFre(frequency(k));
    ad.CommitDemodSet(k-1);
end
ad.EnableADC();
da.SendIntTrig();
[ret,I,Q] = ad.RecvData();
subplot(3,1,2);
bar(sqrt(mean(I,2).^2 + mean(Q,2).^2)/2^18/windowlength);% 同傅里叶变换分解到sin和cos不同，这里不需要乘以2
title('硬件解模')
ylabel('分量成分')
xlabel('频率索引')
%% 软件解模频率
da.StartStop(240);
da.StartStop(15);
ad.SetMode(0);
da.CheckStatus();
dataI = zeros(1,12);
dataQ = zeros(1,12);
for k = 1:12
    ad.EnableADC();
    da.SendIntTrig();
    [ret,I,Q] = ad.RecvData();
    t = (0:(windowlength - 1))*frequency(k)/1e9*2*pi;
    sine = sin(t');
    cose = cos(t');
    dataI(k) = mean(double(I(:,(1+windowstart):sampledepth))*cose) + mean(double(Q(:,(1+windowstart):sampledepth))*sine);
    dataQ(k) = mean(double(Q(:,(1+windowstart):sampledepth))*cose) - mean(double(I(:,(1+windowstart):sampledepth))*sine);
end
subplot(3,1,3);
bar(sqrt(dataI.^2 + dataQ.^2)/128/windowlength);
title('软件解模')
ylabel('分量成分')
xlabel('频率索引')
%%
ad.Close();
da.Close();

