function options = reset_optpaths(options,targ)
%convert bigmem filepaths in options file to woodstock/hpc/whatever.
%this function is sort of incomplete, fill out functionality as needed


%all possible basedirs 
basedir.harvard = '/users/ksander/RCP/KsMVPA_h';
basedir.bender = '/Users/ksander/Desktop/work/KsMVPA_github/devel/RCP';
basedir.hpc = '/work/jksander/RCP/KsMVPA_h';
basedir.woodstock = '/home/acclab/Desktop/ksander/holly_mvpa/KsMVPA_h';
%options.linus = same as woodstock

if strcmp(options.dataset,'RCP')
    targ_dir = basedir.(targ);
    altdirs = rmfield(basedir,targ);
    altdirs = struct2cell(altdirs);
else
    error('config for your project')
end


optfields = fieldnames(options);
for idx = 1:numel(optfields)
    
    data = getfield(options,optfields{idx});
    if isstr(data)
        for p = 1:numel(altdirs)
            path2fix = strfind(data,altdirs{p});
            if ~isempty(path2fix)
                data = strrep(data,altdirs{p},targ_dir);
                options = setfield(options,optfields{idx},data);
            end
        end
    end
end

