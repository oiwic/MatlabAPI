%% ¶Á¼Ä´æÆ÷
da = USTCDAC('10.0.2.7',80);
da.Open();
da.set('isblock',1);

len_row = 60;
len_col = 10;
chip = zeros(len_col,len_row);

for kk = 1:len_col
    for k = 1:4:len_row
        chip(1,k) = da.ReadReg(2,k-1);
        chip(2,k) = da.ReadReg(3,k-1);
        if(chip(1,k)~=chip(2,k))
            disp(k);
        end
    end
    da.InitBoard();
    pause(1);
end

da.Close();
