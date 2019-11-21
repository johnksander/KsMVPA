clear
clc
format compact

profdir = '/users/ksander/parprofiles/';

Cinds = 3:7;
for idx = 1:numel(Cinds)
    Ci = Cinds(idx);
    prof_name = sprintf('prof_%i',Ci);
    
    prof_loc = fullfile(profdir,prof_name);
    if ~isdir(prof_loc),mkdir(prof_loc);end
    
    c = parcluster('local');
    c.JobStorageLocation = prof_loc;
    saveAsProfile(c,prof_name);
    
    clear c
    
end

