function hs = HaltonSequence(n,b)
% Function to generates the first n numbers in Halton's low
% discrepancy sequence with base b
%
% hs = HaltonSequence(n,b)
%
% Inputs: n - the length of the vector to generate
%         b - the base of the sequence
%
% Notes: This code focuses on details of the implementation of the
%        Halton algorithm.
%        It does not contain any programatic essentials such as error
%        checking.
%        It does not allow for optional/default input arguments.
%        It is not optimized for memory efficiency or speed.

% Author: Phil Goddard (phil@goddardconsulting.ca)
% Date: Q2 2006

% Preallocate the output
hs = zeros(n,1);
% Generate the numbers
for idx = 1:n
    hs(idx) = localHaltonSingleNumber(idx,b);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Subfunction to generate the nth number in Halton's sequence
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function hn = localHaltonSingleNumber(n,b)
% This function generates the n-th number in Halton's low
% discrepancy sequence.
n0 = n;
hn = 0;
f = 1/b;
while (n0>0)
    n1 = floor(n0/b);
    r = n0-n1*b;
    hn = hn + f*r;
    f = f/b;
    n0 = n1;
end 
