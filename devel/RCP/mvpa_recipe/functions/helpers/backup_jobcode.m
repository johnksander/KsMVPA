function backup_jobcode(driverfile,options)
%creates a zip file of the driver, and the following directiories:
%
%classifier_functions, helper_functions, searchlight_functions,
%SRM functions, and script_functions (are all in one directory now)
%
%saves the zip backup to the current results folder. 
%
%this backs up a lot of code which is not used in a given analysis, but it
%should be all the code needed to reproduce any job from this toolbox 

driverfile = which(driverfile);

code2save = {driverfile,fullfile(options.script_dir,'functions')};

zipname = ['code4' options.name];
zipname = fullfile(options.save_dir,zipname);

zip(zipname,code2save)

