ad1 = USTCADC(1,'00-00-00-00-00-00');
ad1.Open();
ad1.Init();
ad1.SetMode(0);
ad1.SetSampleDepth(2000);
ad1.ForceTrig();
[ret1,I1,Q1] = ad1.RecvData();
ad1.Close()

subplot(2,1,1);plot(I1);
subplot(2,1,2);plot(Q1);