ad = USTCADC('68-05-CA-47-45-9A','00-00-00-00-00-00');
ad.Open();
ad.Init();
ad.SetMode(1);
ad.SetSampleDepth(6000);
ad.SetTrigCount(2000);

da = USTCDAC('10.0.2.5',80);
da.Open();
da.Init();
da.SetIsMaster(1);
da.SetTrigSel(3);
%% 随机生成测试频点
frequency = [250e6,200e6,100e6,76.9e6,50e6,20e6,12.5e6,10e6,8e6,4e6,2e6,1e6];
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
subplot(2,1,1);
bar(testtable);
%% 生成测试波形
waveobj = waveform();
waveI = zeros(1,8000);
waveQ = zeros(1,8000);
for k= 1:length(testfreq)
    waveobj.frequency = testfreq(k);
    x = (1:length(waveI))*frequency(testfreq(k))/2e9*2*pi;
    waveI = waveI + 32767.5*cos(x);
    waveQ = waveQ + 32767.5*sin(x);
end
waveI = waveI/length(testfreq) + 32767.5;
waveQ = waveQ/length(testfreq) + 32767.5;
%% 发送波形
da.StartStop(240);
da.SetTrigCount(2000);
seq = waveobj.generate_trig_seq(length(waveI),0);
da.WriteWave(3,0,waveI);
da.WriteWave(4,0,waveQ);
da.WriteSeq(3,0,seq);
da.WriteSeq(4,0,seq);
da.StartStop(15);
da.CheckStatus();
%% 设置解模频率
ad.SetWindowWidth(4000);
ad.SetWindowStart(8);
for k = 1:12
    if(testtable(k)~=0)
        ad.SetDemoFre(frequency(k));
        ad.CommitDemodSet(k-1);
    else
        ad.SetDemoFre(500e6);
        ad.CommitDemodSet(k-1);
    end
end
ad.EnableADC();
da.SendIntTrig();
[ret,I,Q] = ad.RecvData();
subplot(2,1,2);
bar(sqrt(mean(I,2).^2 + mean(Q,2).^2));
ad.Close();
da.Close();
