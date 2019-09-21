function mkfig_standalone(stats,options,filename_ID)


% req options fields:
% options.behavioral_file_list -- valence: all, pos, neu, neg
% options.subjects, exclusions
% options.roi_list

% load roi stats

%%
% mkfig config
config.label_beh = {'Positive','Neutral','Negative'};
config.label_roi = {'HpcL','HpcR','AmyL','AmyR','PhcL','PhcR','ThalL','ThalR'};%

config.collist = hsv(50);
config.col = config.collist([1 4 8 28 ],:);

config.sublist = setdiff(options.subjects,options.exclusions);

config.hemisort = [ 1:2:8 2:2:8 ];
config.label_roi = config.label_roi(config.hemisort);


%% 1. Accuracy
config.data = stats.accuracy_mean(:,config.hemisort,:);
config.y_range = [.4 .7+eps];

doFig(options,config)
plot([0 100],[.5 .5],'--k','linewidth',2)
print('-dpdf',fullfile(options.save_dir,['classAcc_' filename_ID '_' datestr(now,29) '.pdf']))%this is where the save name is

%% 2. Fscore
config.data = stats.Fscore_mean(:,config.hemisort,:);
config.y_range = [.4 .6+eps];

doFig(options,config)
print('-dpdf',fullfile(options.save_dir,['classFscore_' filename_ID '_' datestr(now,29) '.pdf']))%this is where the save name is
    