function permutedRDM = RSA_permuteRDM(RDM,permuted_order)
%permute rows and columns of RDM according to permutation of condition labels 
permutedRDM = RDM(permuted_order,:);
permutedRDM = permutedRDM(:,permuted_order);

