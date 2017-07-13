function combos = leave_ten_out_combos(options)

rng('shuffle')

num_combos = 1000;
subjects = options.subjects(~ismember(options.subjects,options.exclusions)); %no exclusions
US = subjects(subjects < 200)';
EA = subjects(subjects > 200)'; %divy up EA & US

%preallocate combo matrix

keepGoing = 1;
while keepGoing == 1 %repeat until there's no duplicate combinations
    noDupes = 1;
    combos = NaN(10,num_combos);
    for idx = 1:num_combos
        
        
        curr_combo = NaN(10,1);
        pick5 = randperm(numel(US));
        pick5 = pick5(1:5);
        curr_combo(1:5) = US(pick5);
        pick5 = randperm(numel(EA));
        pick5 = pick5(1:5);
        curr_combo(6:end) = EA(pick5);
        
        checkU = ismember(combos',curr_combo','rows');
        if sum(checkU) > 0
            noDupes = 0;
        end
        combos(:,idx) = curr_combo;
    end
    if noDupes == 1;
        keepGoing = 0;
    end
    
end


%orig is 2 x 342

