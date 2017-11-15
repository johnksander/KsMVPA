function tau = kendall_tau(X,Y,opt)
%Uses the fast kendall's tau sorting alg off file exchange.
%Info for that original function is:
%            Author: Liber Eleutherios
%            E-Mail: libereleutherios@gmail.com
%That function was reimplmented to give the options for:
%
%tau = kendall_tau(X) returns a P-by-P matrix of pairwise Kendall's tau-b
%coeffs between each pair of columns in the N-by-P matrix X.
%
%tau = kendall_tau(X,Y) returns a P1-by-P2 matrix containing the pairwise
%Kendall's tau-b coeffs between each pair of columns in the N-by-P1 and
%N-by-P2 matrices X and Y.
%
%The (X,Y) input format is more efficient (for both processing and memory)
%in certain situations. The original function's memory warnings were
%removed, so BE CAREFUL.
%
%tau = kendall_tau(X,Y,'Yperm') is a special instance of the (X,Y) input
%format. This assumes all columns of Y are permuted orderings of the same 
%vector, as would be the case in permutation testing. This simplifies the
%calculation needed for the tau-b denominator, specifically  
%the (n0 - nY) term under the radical. All vectors of Y will have the same
%number of tied values (since they're permutations of the same vector), so
%only one calculation is needed. This is a VERY SPECIFIC INSTANCE. 


if nargin == 1
    check_input(X)
    Xn = numel(X(:,1)); %number of observations
    [i1, i2] = find(tril(ones(Xn, 'uint8'), -1)); %pairwise comparison inds
    tau = sign(X(i2, :) - X(i1, :)); %find signs
    tau = tau' * tau;
    temp = diag(tau);
    tau = tau ./ sqrt(temp * temp');

    
elseif nargin == 2
    check_input([X,Y])
    Xn = numel(X(:,1));
    %Yn = numel(Y(:,1));
    [i1, i2] = find(tril(ones(Xn, 'uint8'), -1));
    Xsign = sign(X(i2, :) - X(i1, :));
    Ysign = sign(Y(i2, :) - Y(i1, :));
    tau = Xsign'*Ysign;
    tau = tau ./ sqrt(diag(Xsign'*Xsign) * diag(Ysign'*Ysign)');  
    
    
    %Seems like
    %tic;diag(Ysign'*Ysign),toc
    %is always faster than
    %tic;sum(Ysign.*Ysign,1),toc
    %despite what mathworks forum says... diag() must be optimized
    
    
    elseif nargin == 3 && strcmp(opt,'Yperm')
    check_input([X,Y])
    Xn = numel(X(:,1));
    %Yn = numel(Y(:,1));
    [i1, i2] = find(tril(ones(Xn, 'uint8'), -1));
    Xsign = sign(X(i2, :) - X(i1, :));
    Ysign = sign(Y(i2, :) - Y(i1, :));
    tau = Xsign'*Ysign;
    Yt = repmat(sum(abs(Ysign(:,1))),1,numel(Y(1,:))); %optimization trick for special instance 
    tau = tau ./ sqrt(diag(Xsign'*Xsign) * Yt);  
        
    
else
    error('Incorrect number of inputs');
end


function check_input(inpt)
%input control
ctrl1 = isnumeric(inpt) & isreal(inpt);
if ctrl1
    ctrl2 = ~any(isnan(inpt(:))) & ~any(isinf(inpt(:)));
    if ~ctrl2
        error('input contains infinite or nan values')
    end
else
    error('input is not a matrix of real numbers')
end
if numel(inpt(:,1)) < 2 || numel(inpt(1,:)) < 2
    error('input has less than two variables or two observations');
end
