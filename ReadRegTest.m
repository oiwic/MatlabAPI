%% ¶Á¼Ä´æÆ÷
da = USTCDAC('10.0.2.2',80);
da.Open();

len_row = 1314;
len_col = 10;
chip = zeros(2,len_col,len_row);

for kk = 1:len_col
    for k = 1:len_row
        chip(1,kk,k) = da.ReadAD9136_1(k-1);
        chip(2,kk,k) = da.ReadAD9136_2(k-1);
    end
%     da.InitBoard();
end

chip = mod(chip,256);
da.Close();
