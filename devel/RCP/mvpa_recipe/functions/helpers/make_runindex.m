function [run_index] = make_runindex(varargin)

%this function is kinda borked, you should really pass subject number
%instead of an index if you want to load files like this...

func_options = varargin{1};
switch func_options.dataset
    
    case 'RCP'
        switch func_options.rawdata_type
            
            case 'unsmoothed_raw'
                
                subject_idx = varargin{2};
                %func_options.behavioral_measure = 'allstim'; %force allstim here to get every trial
                TR_Fname = ['RCP_' num2str(func_options.subjects(subject_idx)) '.txt']; %hardcoded, get every trial
                my_files = prepare_fp(func_options,func_options.TRfile_dir,TR_Fname);
                beh_matrix = load_behav_data(my_files,func_options);
                %trials = find(~isnan(beh_matrix));
                run_index = beh_matrix(1:2:end,3); %this file is upsampled from 2 sec tr to 1 second entries
        end
    otherwise
        
        scans_per_run = func_options.scans_per_run;
        run_index = NaN(sum(scans_per_run),1);
        for idx = 1:numel(scans_per_run)
            run_index( (((idx - 1) * scans_per_run(idx)) + 1):(scans_per_run(idx) * idx) ) = idx;
        end
        
        switch func_options.dataset
            
            
            case 'ESWS'
                
                switch func_options.rawdata_type
                    
                    case 'estimatedHDR_spm'
                        
                        subject_idx = varargin{2};
                        func_options.behavioral_measure = 'allstim'; %force allstim here to get every trial
                        TR_Fname = ['ESWS_allstim_' num2str(func_options.subjects(subject_idx)) '.txt']; %hardcoded
                        my_files = prepare_fp(func_options,func_options.TRfile_dir,TR_Fname);
                        beh_matrix = load_behav_data(my_files,func_options);
                        trials = find(~isnan(beh_matrix));
                        run_index = run_index(trials);
                        
                    case 'LSS_eHDR'
                        %there's always 54 trials per run
                        trials_per_run = func_options.trials_per_run;
                        run_index = NaN(sum(trials_per_run),1);
                        for idx = 1:numel(trials_per_run)
                            run_index( (((idx - 1) * trials_per_run(idx)) + 1):(trials_per_run(idx) * idx) ) = idx;
                        end
                        
                        %                 subject_idx = varargin{2};
                        %                 func_options.behavioral_measure = 'allstim'; %force allstim here to get every trial
                        %                 TR_Fname = ['ESWS_allstim_' num2str(func_options.subjects(subject_idx)) '.txt']; %hardcoded
                        %                 my_files = prepare_fp(func_options,func_options.TRfile_dir,TR_Fname);
                        %                 beh_matrix = load_behav_data(my_files,func_options);
                        %                 trials = find(~isnan(beh_matrix));
                        %                 run_index = run_index(trials);
                        
                    case 'SPMbm'
                        
                        run_index = [1:numel(scans_per_run)]'; %note, this is very short sighted.
                        
                end
        end
end
