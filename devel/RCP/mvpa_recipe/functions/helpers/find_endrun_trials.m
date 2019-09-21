function trials2cut = find_endrun_trials(options)
%find trials with onsets occuring at N TRs from the end of a run (options.remove_endrun_trials)


if options.remove_endrun_trials > 0
    
    switch options.rawdata_type
        case 'LSS_eHDR'
            
            trials2cut = cell(1,numel(options.subjects));
            badtrials = cumsum(options.scans_per_run);
            badtrials = [(badtrials - (options.remove_endrun_trials -1)) badtrials];
            for subject_idx = 1:numel(options.subjects)
                
                %get all stimuli in regular TR file format (all scans)
                TR_Fname = ['ESWS_allstim_' num2str(options.subjects(subject_idx)) '.txt']; %hardcoded/force allstim here to get every trial
                my_files = prepare_fp(options,options.TRfile_dir,TR_Fname);
                beh_matrix = load_behav_data(my_files,options);
                curr_trials = find(~isnan(beh_matrix));
                for idx = 1:numel(options.scans_per_run)
                    curr_trials(curr_trials >= badtrials(idx,1) & curr_trials <= badtrials(idx,2)) = NaN;
                end
                trials2cut{subject_idx} = isnan(curr_trials);
            end
            trials2cut = cell2mat(trials2cut);
            
        otherwise %it's the raw data
            
            trials2cut = make_runindex(options);
            badtrials = cumsum(options.scans_per_run);
            badtrials = [(badtrials - (options.remove_endrun_trials -1)) badtrials];
            for idx = 1:numel(options.scans_per_run)
                trials2cut(badtrials(idx,1):badtrials(idx,2)) = NaN;
            end
            trials2cut = isnan(trials2cut);
            trials2cut = repmat(trials2cut,1,numel(options.subjects));
            
    end
    
    
else
    trials2cut = [];
    
end
