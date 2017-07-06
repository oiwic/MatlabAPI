%% ¶Á¼Ä´æÆ÷
da = USTCDAC('10.0.2.2',80);
da.Open();

da.set('isblock',1);

len_row = 60;
len_col = 10;
JESDTx = zeros(len_col,len_row);

for kk = 1:len_col
    for k = 1:4:len_row
        JESDTx(kk,k) = da.ReadReg(2,k-1);
        JESDTx(kk,k) = da.ReadReg(3,k-1);
    end
%     da.InitBoard();
end

da.Close();
