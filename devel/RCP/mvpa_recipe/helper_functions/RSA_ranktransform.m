function RDM = RSA_ranktransform(RDM)
%rank transform a vectorized RDM (upper triangular part)
%note, this needs to be changed to handle ties! 
[~,i] = sort(RDM);
RDM(i) = 1:numel(RDM);


