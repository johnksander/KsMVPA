function behavioral_data = load_behav_data(my_files,options)

behavioral_data = load(my_files{1});
if sum(behavioral_data == 9999) > 0 %replace 9999 placeholders, if present 
        behavioral_data(behavioral_data == 9999) = NaN; 
end



%     case 'vividness'
%         switch options.dataset
%             case 'Del_MCQ'
%                 %Del_MCQ TRfiles include conf data, remove TR times, output Conf,Viv
%                 beh_matrix = [reshape(behavioral_data(:,2), [ ], 1),...
%                     reshape(behavioral_data(:,3), [ ], 1)]; %this sucks, fix it.
%                 beh_matrix(beh_matrix==9999)=NaN;
%             case 'SPM5_Del_MCQ'
%                 %Del_MCQ TRfiles include conf data, remove TR times, output Conf,Viv
%                 beh_matrix = [reshape(behavioral_data(:,2), [ ], 1),...
%                     reshape(behavioral_data(:,3), [ ], 1)]; %this sucks, fix it.
%                 beh_matrix(beh_matrix==9999)=NaN;
%             case 'Aro_MCQ'
%                 %Aro_MCQ TRfiles are NOT in row = TR format, restructure here. Then step 2 below
%                 reformatted_data = NaN(sum(options.scans_per_run),2);
%                 TRs = behavioral_data(behavioral_data(:,1) ~= 9999,1);
%                 reformatted_data(TRs,1) = TRs;
%                 reformatted_data(TRs,2) = behavioral_data(behavioral_data(:,1) ~= 9999,2);
%                 %Aro_MCQ TRfiles don't include conf data, remove TR times, output Viv
%                 beh_matrix = reformatted_data(:,2);
%         end
%     case 'composite_metamemory'
%         beh_matrix = behavioral_data(:,2); %get composite score
%         beh_matrix(beh_matrix == 9999) = NaN;
%     case {'complete_file','pca_metamemory','pca_confviv','summed_confviv','summed_confvivfeel',...
%             'short_delay_complete_file'}
%         beh_matrix = behavioral_data(:,2:end); %get all rating data
%         beh_matrix(beh_matrix == 9999) = NaN;
%



