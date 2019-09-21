function jk_mkfig_from_perm(options)

%fname = 'minpool_roi_nofs'; %save fig name


%statoutput_file = 'minpool_roi_nofs_perm_statistics';
%statoutput_file = 'fixed_mrp_statistics';

fontsz = 24; %fontsize
signum_fontsz = 16;
% fname = 'minpool_pcakmeans_statistics'
% res_dir = 'minpool_pcakmeans_results';
% %fname = 'minpool_LOSO_statistics'

% get options
%addpath('/home/ksander/MCQD_JohnK/mvpa_recipe')
%options = set_options('..result_files/minpool_pcakmeans_results');

% req options fields:
% options.behavioral_file_list -- valence: all, pos, neu, neg
% options.subjects, exclusions
% options.roi_list

% load roi stats
% perm = load(fullfile('/home/ksander/MCQD_JohnK/mvpa_recipe/result_files/',res_dir,[fname '.mat']))
perm = load(fullfile(options.save_dir,options.permstats_fname))


%%
% mkfig config
label_beh = {'Positive','Neutral','Negative'};
label_roi = {'Hipp','Hipp', 'Amyg', 'Amyg', 'PhG', 'PhG'};

collist = hsv(50);
col = collist([4 8 28 ],:);

sublist = setdiff(options.subjects,options.exclusions);

hemisort = [1:2:6 2:2:6];
label_roi = label_roi(hemisort);

%% 1. Accuracy
data = perm.acc_means(:,hemisort);
perm.acc_ci = perm.acc_ci(:,hemisort,:);
perm.acc_p_values = perm.acc_p_values(:,hemisort);

y_range = [.45 .65+eps];


for roi = 1:numel(label_roi)
    for beh = (1:length(label_beh))
        % descriptive stats
        acc_m(roi,beh) = data(beh,roi);
        acc_ci(roi,beh) = perm.acc_ci(2,roi,beh);
        
        % inferential stats
        pval(roi,beh) = perm.acc_p_values(beh,roi);
    end
end

hold off
close all

figure    
hold on
set(gca,'fontweight','b');
for roi = 1:numel(label_roi)
    for beh = (1:length(label_beh))
        bar( beh + (roi-1)*(numel(label_beh) +1 ), acc_m(roi,beh),'facecolor',col(beh,:),'linewidth',2);
    end
end

for beh = (1:length(label_beh))
    for roi = 1:numel(label_roi)
        e=errorbar(beh + (roi-1)*(numel(label_beh)  +1), acc_m(roi,beh),acc_ci(roi,beh),'k','linewidth',2);
        
        errorbar_tick(e,125);
        if pval(roi,beh)<.05
        text(beh + (roi-1)*(numel(label_beh)  +1), acc_m(roi,beh)+acc_ci(roi,beh)+.01,sprintf('%.3f',pval(roi,beh)),'horizontalalignment','center','fontsize',signum_fontsz);
        elseif pval(roi,beh)<.1
        text(beh + (roi-1)*(numel(label_beh)  +1), acc_m(roi,beh)+acc_ci(roi,beh)+.01,sprintf('%.3f',pval(roi,beh)),'horizontalalignment','center','fontsize',(signum_fontsz - 4));
        end
    end
end

% draw some lines
plot([0 100],[min(y_range) min(y_range)],'k','linewidth',2) %adds a line to the bottom?

latline = ((numel(label_roi) * (numel(label_beh) + 1) ) / 2) ;
plot([latline latline],[0 max(y_range)-.025],'linewidth',2,'color',[.5 .5 .5])
% fig properties
axis([ 0 beh+(roi-1)*(numel(label_beh)+1)+1 y_range])
legend(label_beh, 'orientation', 'horizontal','location','northoutside')
legend boxoff

%set(gca,'YTick',-2:.05:4);   %commented out b/c it was chopping off top .65 tick mark
%h=title(ftitle);
%set(h,'fontsize',36);
set(gca,'YTickLabel',{'45%' '50%' '55%' '60%' '65%'}); %adds labels
ylabel('Classification Accuracy','linewidth',2,'fontsize',fontsz);

text(6,.625,'Left','fontsize',30,'fontweight','b','horizontalalignment','center');
text(18,.625,'Right','fontsize',30,'fontweight','b','horizontalalignment','center');

set(gca,'XTick',((1:numel(label_roi))-1)*(numel(label_beh)  +1)+mean(1:numel(label_roi))-1.5);
set(gca,'XTickLabel',label_roi); %adds labels
set(gca,'TickDir','out'); %sticks them down more

set(gca,'linewidth',2);
set(gca,'fontsize',fontsz); %font size, way too big

orient landscape


plot([0 100],[.5 .5],'--k','linewidth',2) %chance bar
%print('-dpdf',[options.figure_fname '_classAcc_' datestr(now,29) '.pdf'])%this is where the save name is 
print(fullfile(options.save_dir,[options.figure_fname '_acc_' datestr(now,29) '.pdf']),'-dpdf')