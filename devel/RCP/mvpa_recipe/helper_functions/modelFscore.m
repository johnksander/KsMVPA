function Fscore = modelFscore(yhat,true)
%get harmonic F score for whole model, usable for multiclass
%input: predicted labels, true labels
%output: model F score

Cmat = confusionmat(true,yhat);
precision =  diag(Cmat)./sum(Cmat,2); %this should be zero if dividing by zero, just sucks (didn't get a label right once, still tried)
precision(isnan(precision)) = 0;
recall = diag(Cmat)./sum(Cmat,1)'; %this should be NaN if dividing by zero, meaningless (didn't guess a label ever)
recall(isnan(recall)) = 0; %penalize classifier for never guessing a particular label 
classF = 2*(precision.*recall)./(precision+recall);
classF(isnan(classF)) = 0; %penalize classifier for never guessing a particular label 
Fscore = mean(classF); 

%precision & recall formulas:
%cmStruct.precision(idx) = tp ./ (tp + fp);
%cmStruct.recall(idx) = tp ./ (tp + fn);

%how to handle NaNs here?

%11/3/16: if you ignore classes without guesses, (like, doing nanmean()
%over classF) you run the risk of getting high F scores in a scenario
%like: one class is slightly over represented in the training set, classifier gusses that class for 
%every label- you get high classification. Same problem with average classification
%accuracy, but F score is supposed to fix that. 