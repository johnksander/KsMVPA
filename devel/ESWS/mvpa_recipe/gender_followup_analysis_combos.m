function combos = gender_followup_analysis_combos(options,name)

%Name: train_Fonly
%Goal: predict culture group with gender balanced CV
%Scheme: same as Fonly scheme, except all male subjects are allowed in each
%testing set. Training is still only performed on female subjects, as in
%Fonly scheme. 

%Name: Fonly
%Goal: predict culture group with gender balanced CV
%Scheme: create 1k CV folds where all male subjects are excluded. In CV,
%subjects are randomly left out, and within the training set there's always
%the maximum equal number of EA and US subjects.

%Name: Pgender
%Goal: predict subject gender (well... goal is null result really)
%Scheme: create 1k CV folds where: subjects are randomly left out, and within
%the training set there's always the maximum equal number of male and
%female observations.

rng('shuffle')

num_combos = 1000;
subjects = options.subjects(~ismember(options.subjects,options.exclusions)); %do exclusions
genderIDs = options.demos_gender(~ismember(options.subjects,options.exclusions)); %do exclusions

switch name
    
    case 'train_Fonly'
        
        male_subjects = options.subjects(options.demos_gender == 1);
        cultureIDs = NaN(size(subjects));
        cultureIDs(subjects < 200) = 1;
        cultureIDs(subjects > 200) = 2;
        culture = unique(cultureIDs);
        genders = unique(genderIDs);
        max_class = min(cellfun(@(x) sum(ismember(cultureIDs,x)),num2cell(cultureIDs))); %max number of each class allowed in the training set
        train_sz = max_class * numel(culture);
        
        class_mask = repmat(culture,max_class,1);
        class_mask = class_mask(:);
        
        %I'm working this a little backwords. Find balanced training sets first,
        %then build testing sets from those. I'm mimicing the real analysis'
        %training class sizes, so I think it'll be a bit easier to work backwords this way
        
        %preallocate combo matrix
        
        train_combos = NaN(train_sz,num_combos);
        for idx = 1:num_combos
            dupe_check = 1; %initialize duplicate check var
            go_again = 0; %initialize sanity counter
            while sum(dupe_check) ~= 0
                curr_combo = NaN(train_sz,1);
                for groupidx = 1:numel(culture)
                    curr_group = culture(groupidx);
                    curr_combo(class_mask == curr_group) = pickN(subjects(cultureIDs == curr_group),max_class);
                end
                curr_combo = sort(curr_combo); %force ordering for duplicate check. Not sure off-hand if ismember 'rows' works outa order
                dupe_check = sum(ismember(train_combos',curr_combo','rows'));
                if sum(dupe_check) ~= 0
                    go_again = go_again+1; %count number of failed convergences
                    disp(sprintf('combo #%i non convergence',idx))
                end
                if go_again > 1000,disp('ERROR: COMBOS DID NOT CONVERGE'),return;end %super super insanity check
            end
            
            train_combos(:,idx) = curr_combo;
        end
        
        
        %alright now get the training set, every fold should
        %have one class where Nobs = max_class - 1
        
        test_sz = numel(subjects) - (train_sz-1);
        combos = NaN(test_sz,num_combos);
        group2drop = repmat(culture,1,num_combos/numel(culture));
        
        for idx = 1:num_combos
            go_again = 0; %should be just a sanity check really...
            while ~go_again
                curr_combo = train_combos(:,idx);
                drop_subj = curr_combo(class_mask == group2drop(idx));
                drop_subj = drop_subj(randi(max_class,1));
                curr_combo(curr_combo == drop_subj) = []; %drop 'em
                checkU = ismember(combos',subjects(~ismember(subjects,curr_combo)),'rows');
                if sum(checkU) > 0
                    %go again
                else
                    combos(:,idx) = subjects(~ismember(subjects,curr_combo)); %corresponding training set
                    go_again = 1;
                end
                if go_again > 1000,disp('ERROR: COMBOS DID NOT CONVERGE'),return;end %super super insanity check
            end
        end
        %now add all the male subjects to every testing set 
        male_subjects = repmat(male_subjects',1,num_combos);
        combos = [combos;male_subjects];
        
    case 'Fonly'
                
        cultureIDs = NaN(size(subjects));
        cultureIDs(subjects < 200) = 1;
        cultureIDs(subjects > 200) = 2;
        culture = unique(cultureIDs);
        genders = unique(genderIDs);
        max_class = min(cellfun(@(x) sum(ismember(cultureIDs,x)),num2cell(cultureIDs))); %max number of each class allowed in the training set
        train_sz = max_class * numel(culture);
        
        class_mask = repmat(culture,max_class,1);
        class_mask = class_mask(:);
        
        %I'm working this a little backwords. Find balanced training sets first,
        %then build testing sets from those. I'm mimicing the real analysis'
        %training class sizes, so I think it'll be a bit easier to work backwords this way
        
        %preallocate combo matrix
        
        train_combos = NaN(train_sz,num_combos);
        for idx = 1:num_combos
            dupe_check = 1; %initialize duplicate check var
            go_again = 0; %initialize sanity counter
            while sum(dupe_check) ~= 0
                curr_combo = NaN(train_sz,1);
                for groupidx = 1:numel(culture)
                    curr_group = culture(groupidx);
                    curr_combo(class_mask == curr_group) = pickN(subjects(cultureIDs == curr_group),max_class);
                end
                curr_combo = sort(curr_combo); %force ordering for duplicate check. Not sure off-hand if ismember 'rows' works outa order
                dupe_check = sum(ismember(train_combos',curr_combo','rows'));
                if sum(dupe_check) ~= 0
                    go_again = go_again+1; %count number of failed convergences
                    disp(sprintf('combo #%i non convergence',idx))
                end
                if go_again > 1000,disp('ERROR: COMBOS DID NOT CONVERGE'),return;end %super super insanity check
            end
            
            train_combos(:,idx) = curr_combo;
        end
        
        
        %alright now get the training set, every fold should
        %have one class where Nobs = max_class - 1
        
        test_sz = numel(subjects) - (train_sz-1);
        combos = NaN(test_sz,num_combos);
        group2drop = repmat(culture,1,num_combos/numel(culture));
        
        for idx = 1:num_combos
            go_again = 0; %should be just a sanity check really...
            while ~go_again
                curr_combo = train_combos(:,idx);
                drop_subj = curr_combo(class_mask == group2drop(idx));
                drop_subj = drop_subj(randi(max_class,1));
                curr_combo(curr_combo == drop_subj) = []; %drop 'em
                checkU = ismember(combos',subjects(~ismember(subjects,curr_combo)),'rows');
                if sum(checkU) > 0
                    %go again
                else
                    combos(:,idx) = subjects(~ismember(subjects,curr_combo)); %corresponding training set
                    go_again = 1;
                end
                if go_again > 1000,disp('ERROR: COMBOS DID NOT CONVERGE'),return;end %super super insanity check
            end
        end
        
        
                
    case 'Pgender'
        
        genders = unique(genderIDs);
        max_class = min(cellfun(@(x) sum(ismember(genderIDs,x)),num2cell(genders))); %max number of each class allowed in the training set
        train_sz = max_class * numel(genders);
        class_mask = repmat(genders,max_class,1);
        class_mask = class_mask(:);
        
        
        
        %I'm working this a little backwords. Find balanced training sets first,
        %then build testing sets from those. I'm mimicing the real analysis'
        %training class sizes, so I think it'll be a bit easier to work backwords this way
        
        %preallocate combo matrix
        keepGoing = 1;
        while keepGoing == 1 %repeat until there's no duplicate combinations
            noDupes = 1;
            train_combos = NaN(train_sz,num_combos);
            for idx = 1:num_combos
                
                
                curr_combo = NaN(train_sz,1);
                for groupidx = 1:numel(genders)
                    curr_group = genders(groupidx);
                    curr_combo(class_mask == curr_group) = pickN(subjects(genderIDs == curr_group),max_class);
                end
                curr_combo = sort(curr_combo); %force ordering for duplicate check. Not sure off-hand if ismember 'rows' works outa order
                checkU = ismember(train_combos',curr_combo','rows');
                if sum(checkU) > 0
                    noDupes = 0;
                end
                train_combos(:,idx) = curr_combo;
            end
            if noDupes == 1;
                keepGoing = 0;
            end
            
        end
        
        %alright now get the training set, every fold should
        %have one class where Nobs = max_class - 1
        
        test_sz = numel(subjects) - (train_sz-1);
        combos = NaN(test_sz,num_combos);
        group2drop = repmat(genders,1,num_combos/numel(genders));
        
        for idx = 1:num_combos
            curr_combo = train_combos(:,idx);
            drop_subj = curr_combo(class_mask == group2drop(idx));
            go_again = 0; %should be just a sanity check really...
            while ~go_again
                drop_subj = drop_subj(randi(max_class,1));
                curr_combo(curr_combo == drop_subj) = []; %drop 'em
                checkU = ismember(combos',subjects(~ismember(subjects,curr_combo)),'rows');
                if sum(checkU) > 0
                    %go again
                else
                    combos(:,idx) = subjects(~ismember(subjects,curr_combo)); %corresponding training set
                    go_again = 1;
                end
                if go_again > 1000,disp('ERROR: COMBOS DID NOT CONVERGE'),return;end %super super insanity check
            end
        end
        
        
        
end

    function sel = pickN(x,n)
        sel = randperm(numel(x));
        sel = sel(1:n);
        sel = x(sel);
    end

end