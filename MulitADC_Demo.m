ad1 = USTCADC(1,'00-00-00-00-00-01');
ad2 = USTCADC(1,'00-00-00-00-00-02');
ad1.Open();
ad2.Open();

ad1.Init();
ad2.Init();

ad1.SetMode(0);
ad2.SetMode(0);
ad1.SetSampleDepth(2000);
ad2.SetSampleDepth(2000);

ad1.ForceTrig();
ad2.ForceTrig();

[ret1,I1,Q1] = ad1.RecvData();
[ret2,I2,Q2] = ad2.RecvData();
ad1.Close();
ad2.Close();

subplot(2,2,1);plot(I1);
subplot(2,2,2);plot(Q1);
subplot(2,2,3);plot(I2);
subplot(2,2,4);plot(Q2);
