function backup_jobcode(driverfile,options)
%creates a zip file of the driver, and the following directiories:
%
%classifier_functions, helper_functions, searchlight_functions,
%stat_functions, and script_functions 
%
%saves the zip backup to the current results folder. 
%
%this backs up a lot of code which is not used in a given analysis, but it
%should be all the code needed to reproduce any job from this toolbox 

driverfile = which(driverfile);

code2save = {driverfile,options.classifier_function_dir,options.helper_function_dir,...
    options.searchlight_function_dir,options.stat_function_dir,options.script_function_dir};

zipname = ['code4' options.name];
zipname = fullfile(options.save_dir,zipname);

zip(zipname,code2save)

