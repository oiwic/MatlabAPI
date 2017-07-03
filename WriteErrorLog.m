function WriteErrorLog(msg)
    fid = fopen('ErrorLog.txt','a+');
    str = [datestr(now),' ',msg];
    fseek(fid,0,'eof');
    fprintf(fid,'%s\n',str);
    fclose(fid);
end