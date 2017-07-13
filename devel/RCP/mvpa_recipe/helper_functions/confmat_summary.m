function [TP,FP,FN,TN] = confmat_summary(actual, predict, classlist)

% CFMATRIX2 calculates the confusion matrix for any prediction 
% algorithm ( prediction algorithm generates a list of classes to which 
% each test feature vector is assigned ); 
%
% Outputs: confusion matrix
%
%                 Actual Classes
%                   p       n
%              ___|_____|______| 
%    Predicted  p'|     |      |
%      Classes  n'|     |      |
%
%           Also the TP, FP, FN and TN are output for each class based on 
%           http://en.wikipedia.org/wiki/Confusion_matrix
%           The Precision, Sensitivity and Specificity for each class have
%           also been added in this update along with the overall accuracy
%           of the model ( ModelAccuracy ).
%
%
% Further description of the outputs:
%
% True Postive [TP] = Condition Present + Positive result 
% False Positive [FP] = Condition absent + Positive result [Type I error] 
% False (invalid) Negative [FN] = Condition present + Negative result [Type II error] 
% True (accurate) Negative [TN] = Condition absent + Negative result
% Precision(class) = TP(class) / ( TP(class) + FP(class) )
% Sensitivity(class) = Recall(class) = TruePositiveRate(class)
% = TP(class) / ( TP(class) + FN(class) )
% Specificity ( mostly used in 2 class problems )=
% TrueNegativeRate(class)
% = TN(class) / ( TN(class) + FP(class) )
%
% Inputs: 
% 
% 1. actual / 2. predict
% The inputs provided are the 'actual' classes vector
% and the 'predict'ed classes vector. The actual classes are the classes
% to which the input feature vectors belong. The predicted classes are the 
% class to which the input feature vectors are predicted to belong to, 
% based on a prediction algorithm. 
% The length of actual class vector and the predicted class vector need to 
% be the same. If they are not the same, an error message is displayed. 
% 3. classlist
% The third input provides the list of all the classes {p,n,...} for which 
% the classification is being done. All classes are numbers.
% 4. per = 1/0 (default = 0)
% This parameter when set to 1 provides the values in the confusion matrix 
% as percentages. The default provides the values in numbers.
% 5. printout = 1/0 ( default = 1 )
% This parameter when set to 1 provides output on the matlab terminal and
% can be used to suppress output by setting to 0. ( default = 1 ). Assuming
% 'printout' of output use case would be more common and at the same time 
% provided option to suppress output when the number of classes can be very
% large.
%
% Example:
% >> a = [ 1 2 3 1 2 3 1 1 2 3 2 1 1 2 3];
% >> b = [ 1 2 3 1 2 3 1 1 1 2 2 1 2 1 3];
% >> Cf = cfmatrix2(a, b, [1 2 3], 0, 1); 
% is equivalent to
% >> Cf = cfmatrix2(a, b);
% The values of classlist(unique from actual), per(0), printout(1) are set
% to the respective defaults.
% 
%
% [Avinash Uppuluri: avinash_uv@yahoo.com: Last modified: 03/28/2012]
%
% Changes added for 03/28/2012 upload
% a. Pre-initialize confmatrix
% b. Simplified logic making the code more readable and faster; 
%    (based on comments from an interviewer who reviewed the code)
% c. Provide input variable 'printout' as an option to suppress output to
%    screen ( output to display is still the default (printout = 1) 
%    assuming that will be the more common use case ).
% d. Added Precision(class), Sensitivity(class), Specificity(class) and 
%    the overall accuracy of model calculations.

% If classlist not entered: make classlist equal to all 
% unique elements of actual
if (nargin < 2)
   error('Not enough input arguments. Need atleast two vectors as input');
elseif (nargin == 2)
    classlist = unique(actual); % default values from actual
end

if (length(actual) ~= length(predict))
    error('First two inputs need to be vectors with equal size.');
elseif ((size(actual,1) ~= 1) && (size(actual,2) ~= 1))
    error('First input needs to be a vector and not a matrix');
elseif ((size(predict,1) ~= 1) && (size(predict,2) ~= 1))
    error('Second input needs to be a vector and not a matrix');
end

n_class = length(classlist);
confmatrix = zeros(n_class);

for i = 1:n_class
    for j = 1:n_class
        m = (predict == classlist(i) ...
           & actual  == classlist(j));
        confmatrix(i,j) = sum(m);
    end
end

% True Postive [TP] = Condition Present + Positive result 
% False Positive [FP] = Condition absent + Positive result [Type I error] 
% False (invalid) Negative [FN] = Condition present + Negative result [Type II error] 
% True (accurate) Negative [TN] = Condition absent + Negative result
% Precision(class) = TP(class) / ( TP(class) + FP(class) )
% Sensitivity(class) = Recall(class) = TruePositiveRate(class)
% = TP(class) / ( TP(class) + FN(class) )
% Specificity ( mostly used in 2 class problems )=
% TrueNegativeRate(class)
% = TN(class) / ( TN(class) + FP(class) )
    
TPFPFNTN    = zeros(4, n_class);

for i = 1:n_class 
    TPFPFNTN(1, i) = confmatrix(i,i); % TP
    TPFPFNTN(2, i) = sum(confmatrix(i,:))-confmatrix(i,i); % FP
    TPFPFNTN(3, i) = sum(confmatrix(:,i))-confmatrix(i,i); % FN
    TPFPFNTN(4, i) = sum(confmatrix(:)) - sum(confmatrix(i,:)) -...
        sum(confmatrix(:,i)) + confmatrix(i,i); % TN
end 

if n_class == 2
    TP = TPFPFNTN(1,1);
    FP = TPFPFNTN(2,1);
    FN = TPFPFNTN(3,1);
    TN = TPFPFNTN(4,1);
else
    TP = TPFPFNTN(1,:);
    FP = TPFPFNTN(2,:);
    FN = TPFPFNTN(3,:);
    TN = TPFPFNTN(4,:);
end




