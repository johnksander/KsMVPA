function combos = twofoldESWScombos(options)

rng('shuffle')
disp(sprintf('\nCreating twofold subject combinations\n'))

num_combos = 1000;
subs_per_fold = 18;
subjects = options.subjects(~ismember(options.subjects,options.exclusions)); %no exclusions
US = subjects(subjects < 200)';
EA = subjects(subjects > 200)'; %divy up EA & US

%preallocate combo matrix

keepGoing = 1;
while keepGoing == 1 %repeat until there's no duplicate combinations
    noDupes = 1;
    combos = NaN(subs_per_fold,num_combos);
    for idx = 1:num_combos        
        curr_combo = NaN(subs_per_fold,1);
        pickhalf = randperm(numel(US));
        pickhalf = pickhalf(1:subs_per_fold/2);
        curr_combo(1:subs_per_fold/2) = US(pickhalf);
        pickhalf = randperm(numel(EA));
        pickhalf = pickhalf(1:subs_per_fold/2);
        curr_combo((subs_per_fold/2) + 1:end) = EA(pickhalf);
        
        checkU = ismember(combos',curr_combo','rows');
        if sum(checkU) > 0
            %disp('dups found')
            noDupes = 0;
        end
        combos(:,idx) = curr_combo;
    end
    if noDupes == 1;
        keepGoing = 0;
    end
    
end


%orig is 2 x 342

