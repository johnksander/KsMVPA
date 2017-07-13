function [collapsed_data] = collapse_behdata4regress_whiten(behavioral_data,options)

        behdata4regwhitening = cell(size(behavioral_data));
        for idx = 1:numel(behdata4regwhitening)
            behdata4regwhitening{idx} = behavioral_data{idx}(:,options.which_behavior);
        end 
        behdata4regwhitening = horzcat(behdata4regwhitening'); %use ratings for ALL valence (i.e. every trial) for regression whitening
        behdata4regwhitening = cell2mat(behdata4regwhitening);
        collapsed_data = min(behdata4regwhitening,[],2);


