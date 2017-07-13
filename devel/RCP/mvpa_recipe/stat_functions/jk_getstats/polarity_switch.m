function pm = polarity_switch(ds)
% pm = randi(2,[ds(1),1]) - 1;
% pm = repmat(pm,1,ds(2));
pm = randi(2,ds) - 1;
pm(pm==0) = -1;
