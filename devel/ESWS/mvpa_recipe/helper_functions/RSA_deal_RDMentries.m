function targRDM = RSA_deal_RDMentries(targRDM,srcRDM,targ_inds)

%deal RDM entries to their location within a larger (and probably out of
%order) aggregate RDM. targRDM is aggregate RDM input, srcRDM is the RDM to
%be dealt, and targ_inds are the indicies for dealing entries. 

%for instance, if targ_inds = [4 38 9]'; 
%   srcRDM(1,1) deals to targRDM(4,4)
%   srcRDM(1,2) deals to targRDM(4,38)
%   srcRDM(2,3) deals to targRDM(38,9)
%   etc 

num_items = numel(targ_inds);

targ_lin_inds = conv2lin(size(targRDM),targ_inds);
src_lin_inds = conv2lin(size(srcRDM),1:num_items);

targRDM(targ_lin_inds) = srcRDM(src_lin_inds); %deal 'em



    function lin_inds = conv2lin(dims,entry_idx)
        [x,y] = meshgrid(entry_idx, entry_idx);
        x = x(:);
        y = y(:);
        lin_inds = sub2ind(dims,x,y);
    end
end




%HEY LOOK- I checked this, it's legit relax 

% 
% for checkidx = 1:num_items
%     row_check = targRDM(targ_inds,targ_inds(checkidx));
%     col_check = targRDM(targ_inds(checkidx),targ_inds);
%     row_errs = sum(row_check ~= srcRDM(:,checkidx));
%     col_errs = sum(col_check ~= srcRDM(checkidx,:));
%     if sum(row_errs) > 1 || sum(col_errs) > 1
%         disp('WRONG')
%         return
%     end
% end

