function options = set_bigmem_options2linus(options)
%convert bigmem filepaths in options file to linus filpathes

if strcmp(options.dataset,'RCP')
    bigmem_basedir = '/data/netapp/jksander/RCPholly/';
    linus_basedir = '/home/acclab/Desktop/ksander/holly_mvpa/';
else
    bigmem_basedir = '/data/netapp/jksander/';
    linus_basedir = '/home/acclab/Desktop/ksander/';
end

optfields = fieldnames(options);
for idx = 1:numel(optfields)
    
    data = getfield(options,optfields{idx});
    if isstr(data)
        path2fix = strfind(data,bigmem_basedir);
        if ~isempty(path2fix)
            data = strrep(data,bigmem_basedir,linus_basedir);
        end
        options = setfield(options,optfields{idx},data);
    end
end
