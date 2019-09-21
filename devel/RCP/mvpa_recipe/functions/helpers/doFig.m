function dofig(options,config)
for roi = 1:numel(config.label_roi)
    for beh = (1:length(config.label_beh))+1
        % descriptive stats
        acc_m(roi,beh) = mean(config.data(config.sublist,roi,beh));
        acc_ci(roi,beh) = std(config.data(config.sublist,roi,beh))./sqrt(numel(config.sublist));
        
        % inferential stats
        [h,p,ci,stat] = ttest(config.data(config.sublist,roi,beh),.5,'tail','right');
        pval(roi,beh) = p*3;
    end
end


figure    
hold on
for roi = 1:numel(config.label_roi)
    for beh = (1:length(config.label_beh))+1
        bar( beh + (roi-1)*(numel(config.label_beh)+1), acc_m(roi,beh),'facecolor',config.col(beh,:),'linewidth',2);
    end
end

for beh = (1:length(config.label_beh))+1
    for roi = 1:numel(config.label_roi)
        e=errorbar(beh + (roi-1)*(numel(config.label_beh)+1), acc_m(roi,beh),acc_ci(roi,beh),'k','linewidth',2);
        
        errorbar_tick(e,125);
        if pval(roi,beh)<.05
        text(beh + (roi-1)*(numel(config.label_beh)+1), acc_m(roi,beh)+acc_ci(roi,beh)+.025,sprintf('%.3f',pval(roi,beh)),'horizontalalignment','center','fontsize',12);
        elseif pval(roi,beh)<.1
        text(beh + (roi-1)*(numel(config.label_beh)+1), acc_m(roi,beh)+acc_ci(roi,beh)+.025,sprintf('%.3f',pval(roi,beh)),'horizontalalignment','center','fontsize',6);
        end
    end
end

% draw some lines
plot([0 100],[min(config.y_range) min(config.y_range)],'k','linewidth',2)

plot([17 17],[0 max(config.y_range)-.05],'b','linewidth',2)
% fig properties
axis([ 0 beh+(roi-1)*(numel(config.label_beh)+1)+1 config.y_range])
legend(config.label_beh, 'orientation', 'horizontal')
legend boxoff

set(gca,'YTick',-2:.05:4);
%h=title(ftitle);
%set(h,'fontsize',36);

set(gca,'XTick',((1:numel(config.label_roi))-1)*(numel(config.label_beh)+1)+mean(1:numel(config.label_roi))-1.5);
set(gca,'XTickLabel',config.label_roi);
set(gca,'TickDir','out');

set(gca,'linewidth',2);
set(gca,'fontsize',24);

orient landscape