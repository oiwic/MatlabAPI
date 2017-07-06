function data = loadSettings(spath, fields)
% load settings
% examples:
% s = qes.util.loadSettings('F:\program\qes_settings',{'_hardware','hwsettings1','ustcadda','ad_boards'})
% s = qes.util.loadSettings('F:\program\qes_settings',{'_hardware','hwsettings1','ustcadda','ad_boards','ADC2'})
% s = qes.util.loadSettings('F:\program\qes_settings',{'_hardware','hwsettings1','ustcadda','ad_boards','ADC2','records','demod_freq'})

% Copyright 2016 Yulin Wu, USTC
% mail4ywu@gmail.com/mail4ywu@icloud.com

    data = [];
    if nargin == 1 || isempty(fields)
        fields = {};
    end
    if ~iscell(fields)
        if ~ischar(fields)
            error('loadSettings:invalidInput','fileds should be a cell array of char strings or a char string.');
        else
            fields = {fields};
        end
    end
    if ~isdir(spath)
        error('loadSettings:invalidInput','%s is not a valid directory.', spath);
    end
    if ~exist(spath,'dir')
        error('loadSettings:NotFound','directory: %s not found.', spath);
    end
    numFields = numel(fields);
    fileinfo = dir(spath);
    numFiles = numel(fileinfo);
    for ii = 1:numFiles;
        if strcmp(fileinfo(ii).name,'.') || strcmp(fileinfo(ii).name,'..')
            if ii == numFiles && ~isempty(fields)
                error('loadSettings:notFound','no such field found in settings.');
            end
            continue;
        end
        if isempty(fields) % load all
            if fileinfo(ii).isdir
                try
                    data.(fileinfo(ii).name) = qes.util.loadSettings(fullfile(spath,fileinfo(ii).name));
                catch
                end
            elseif length(fileinfo(ii).name) < 5 || ~strcmp(fileinfo(ii).name(end-2:end),'key')
                continue;
            else
                cidx = strfind(fileinfo(ii).name(1:end-4),'@');
                nidx = strfind(fileinfo(ii).name(1:end-4),'=');
                if isempty(cidx) && isempty(nidx)
                    fieldname = fileinfo(ii).name(1:end-4);
                    if isvarname(fieldname)
                        try
                            data_ = qes.util.loadJson(fullfile(spath,fileinfo(ii).name));
                            if isfield(data_,fieldname)
                                data.(fieldname) = data_.(fieldname);
                            end
                        catch
                        end
                    end
                elseif ~isempty(cidx) && cidx(end) > 1
                    fieldname = fileinfo(ii).name(1:cidx(end)-1);
                    if isvarname(fieldname)
                        data.(fieldname) = fileinfo(ii).name(cidx(end)+1:end-4);
                    end
                elseif ~isempty(nidx) && nidx(end) > 1
                    fieldname = fileinfo(ii).name(1:nidx(end)-1);
                    if isvarname(fieldname)
                        dstr = strtrim(fileinfo(ii).name(nidx(end)+1:end-4));
                        isboolean = false;
                        if ~isempty(strfind(dstr,'true')) || ~isempty(strfind(dstr,'false')) ||...
                              ~isempty(strfind(dstr,'True')) || ~isempty(strfind(dstr,'False'))  
                            isboolean = true;
                            dstr = regexprep(dstr,'[tT]rue','1');
                            dstr = regexprep(dstr,'[fF]alse','0');
                        end
                        data_ = cellfun(@str2double,strsplit(dstr,','));
                        if isboolean
                            data_ = logical(data_);
                        end       
                        data.(fieldname) = data_;
                    end
                end
            end
        else % load a specific field
            data = struct();
            if fileinfo(ii).isdir && strcmp(fileinfo(ii).name,fields{1})
                fields(1) = [];
                data = qes.util.loadSettings(fullfile(spath,fileinfo(ii).name),fields);
                return;
            end
            if fileinfo(ii).isdir || length(fileinfo(ii).name) < 5 || ~strcmp(fileinfo(ii).name(end-2:end),'key')
                if ii == numFiles
                    error('loadSettings:notFound','no such field found in settings.');
                end
                continue;
            end
            if strcmp(fileinfo(ii).name(1:end-4),fields{1})
                jdata = qes.util.loadJson(fullfile(spath,fileinfo(ii).name));
                for jj = 1:numFields
                    if ~isfield(jdata,fields{jj})
                        error('loadSettings:notFound','no such field found in settings.');
                    end
                    if jj == numFields
                        data = jdata.(fields{jj});
                        if iscell(data) && numel(data) == 1
                            data = data{1};
                        end
                        return;
                    else
                        jdata = jdata.(fields{jj});
                        if iscell(jdata) && numel(jdata) == 1
                            jdata = jdata{1};
                        end
                    end
                end
            elseif numFields == 1
                ln_field = numel(fields{1});
                if length(fileinfo(ii).name)-3 >= ln_field &&...
                        strcmp(fileinfo(ii).name(1:ln_field),fields{1})
                    switch fileinfo(ii).name(ln_field+1)
                        case '@'
                            data = fileinfo(ii).name(ln_field+2:end-4);
                            return;
                        case '='
                            dstr = strtrim(fileinfo(ii).name(ln_field+2:end-4));
                            isboolean = false;
                            if ~isempty(strfind(dstr,'true')) || ~isempty(strfind(dstr,'false')) ||...
                                  ~isempty(strfind(dstr,'True')) || ~isempty(strfind(dstr,'False'))  
                                isboolean = true;
                                dstr = regexprep(dstr,'[tT]rue','1');
                                dstr = regexprep(dstr,'[fF]alse','0');
                            end
                            data = cellfun(@str2double,strsplit(dstr,','));
                            if isboolean
                                data = logical(data);
                            end
                            return;
                    end
                end
            end
        end
        if ii == numFiles && ~isempty(fields)
            error('loadSettings:notFound','no such field found in settings.');
        end
    end
end