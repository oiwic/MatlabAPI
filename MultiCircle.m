ad = USTCADC('68-05-CA-47-45-9A','00-00-00-00-00-00');
ad.Open();
ad.Init();
ad.SetMode(1);
ad.SetSampleDepth(4008);
ad.SetTrigCount(100);

da = USTCDAC('10.0.2.5',80);
da.Open();
da.Init();
da.SetIsMaster(1);
da.SetTrigSel(3);
%% 生产复合频率波形
waveobj = waveform();
% frequency = [252e6,193e6,87e6,76.9e6,55e6,33e6,23e6,13e6,7e6,4.3e6,2.2e6,0.9e6];
frequency = [250e6,200e6,100e6,76.9e6,50e6,20e6,12.5e6,10e6,8e6,4e6,2e6,1e6];
numrnd = floor(12*rand());
index = floor(12*rand(1,numrnd))+1;
% frequency = frequency(index);%注释后，使用12个频点
phase_count = 100;
ad.SetWindowWidth(4000);
ad.SetWindowStart(8);
for k = 1:length(frequency)
    ad.SetDemoFre(frequency(k));
    ad.CommitDemodSet(k-1);
end
dataI = zeros(length(frequency),phase_count);
dataQ = zeros(length(frequency),phase_count);
for kk = 1:phase_count
    waveI = zeros(1,8000+16);
    waveQ = zeros(1,8000+16);
    seq = waveobj.generate_trig_seq(length(waveI),0);
    phi = (kk-1)/phase_count*2*pi;
    for k= 1:length(frequency)
        waveobj.frequency = frequency(k);
        x = (1:length(waveI))*frequency(k)/2e9*2*pi;
        waveI = waveI + 32767.5*cos(x+phi);
        waveQ = waveQ + 32767.5*sin(x+phi);
    end
    waveI = waveI/length(frequency) + 32767.5;
    waveQ = waveQ/length(frequency) + 32767.5;
    waveI(8001:8016) = 32768;
    waveQ(8001:8016) = 32768;
    da.WriteWave(3,0,waveI);
    da.WriteWave(4,0,waveQ);
    da.WriteSeq(3,0,seq);
    da.WriteSeq(4,0,seq);
    da.StartStop(15);
    da.CheckStatus();
    ad.EnableADC();
    da.SendIntTrig();
    [ret,I,Q] = ad.RecvData();
    for k = 1:length(frequency)
        dataI(k,kk) = mean(I(k,:));
        dataQ(k,kk) = mean(Q(k,:));
        scatter(dataI(k,1:kk),dataQ(k,1:kk));hold on;
    end
    legend(num2str(frequency'/1e6));
    pause(0.1);
    hold off;
end
ad.Close();
da.Close();