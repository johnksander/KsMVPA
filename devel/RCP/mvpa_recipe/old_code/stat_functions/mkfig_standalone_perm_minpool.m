fname = 'minpool_pcakmeans_statistics'
res_dir = 'minpool_pcakmeans_results';
%fname = 'minpool_LOSO_statistics'

% get options
%addpath('/home/ksander/MCQD_JohnK/mvpa_recipe')
options = set_options('..result_files/minpool_pcakmeans_results');

% req options fields:
% options.behavioral_file_list -- valence: all, pos, neu, neg
% options.subjects, exclusions
% options.roi_list

% load roi stats
perm = load(fullfile('/home/ksander/MCQD_JohnK/mvpa_recipe/result_files/',res_dir,[fname '.mat']))

%%
% mkfig config
label_beh = {'Positive','Neutral','Negative'};
label_roi = {'HpcL','HpcR','AmyL','AmyR','PhcL','PhcR','ThalL','ThalR'};%

collist = hsv(50);
col = collist([1 4 8 28 ],:);

sublist = setdiff(options.subjects,options.exclusions);

hemisort = [ 1:2:8 2:2:8 ];
label_roi = label_roi(hemisort);

%% 1. Accuracy
data = perm.acc_means(:,hemisort);
perm.acc_ci = perm.acc_ci(:,hemisort,:);
perm.acc_p_values = perm.acc_p_values(:,hemisort);

y_range = [.4 .7+eps];


for roi = 1:numel(label_roi)
    for beh = (1:length(label_beh))+1
        % descriptive stats
        acc_m(roi,beh) = data(beh,roi);
        acc_ci(roi,beh) = perm.acc_ci(2,roi,beh);
        
        % inferential stats
        pval(roi,beh) = perm.acc_p_values(beh,roi);
    end
end


figure    
hold on
for roi = 1:numel(label_roi)
    for beh = (1:length(label_beh))+1
        bar( beh + (roi-1)*(numel(label_beh)+1), acc_m(roi,beh),'facecolor',col(beh,:),'linewidth',2);
    end
end

for beh = (1:length(label_beh))+1
    for roi = 1:numel(label_roi)
        e=errorbar(beh + (roi-1)*(numel(label_beh)+1), acc_m(roi,beh),acc_ci(roi,beh),'k','linewidth',2);
        
        errorbar_tick(e,125);
        if pval(roi,beh)<.05
        text(beh + (roi-1)*(numel(label_beh)+1), acc_m(roi,beh)+acc_ci(roi,beh)+.025,sprintf('%.3f',pval(roi,beh)),'horizontalalignment','center','fontsize',12);
        elseif pval(roi,beh)<.1
        %text(beh + (roi-1)*(numel(label_beh)+1), acc_m(roi,beh)+acc_ci(roi,beh)+.025,sprintf('%.3f',pval(roi,beh)),'horizontalalignment','center','fontsize',6);
        end
    end
end

% draw some lines
plot([0 100],[min(y_range) min(y_range)],'k','linewidth',2)

plot([17 17],[0 max(y_range)-.05],'b','linewidth',2)
% fig properties
axis([ 0 beh+(roi-1)*(numel(label_beh)+1)+1 y_range])
legend(label_beh, 'orientation', 'horizontal')
legend boxoff

set(gca,'YTick',-2:.05:4);
%h=title(ftitle);
%set(h,'fontsize',36);

set(gca,'XTick',((1:numel(label_roi))-1)*(numel(label_beh)+1)+mean(1:numel(label_roi))-1.5);
set(gca,'XTickLabel',label_roi);
set(gca,'TickDir','out');

set(gca,'linewidth',2);
set(gca,'fontsize',24);

orient landscape


plot([0 100],[.5 .5],'--k','linewidth',2)
print('-dpdf',[fname '_classAcc_' datestr(now,29) '.pdf'])%this is where the save name is    