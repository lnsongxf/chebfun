function vals = fastSphereEval(f, lambda, theta )
%FASTSPHEREEVAL     Fast evaluation of a spherefun
%   VALS = FASTSPHEREEVAL(F, LAMBDA, THETA) evaluates the spherefun F at the
%   points (LAMBDA, THETA), where LAMBDA is longitude, with -pi<=LAMBA<=pi, and
%   THETA is co-latitude, with 0<=THETA<=PI. Returns the values of F at these
%   points in the array VALS.
%
%   This is a fast transform analogue to the direct algorithm evaluation of F
%   using Horner's rule. The evaluation costs O(m*n*log(m*n) + N) operations.
%
%   The algorithm in this MATLAB script is based on the paper:
%    [1] D. Ruiz--Antoln and A. Townsend, "A nonuniform fast Fourier transform
%    based on low rank approximation", submitted, 2016.
%
% See also SPHEREFUN/FEVAL and SPHEREFUN/ROTATE.

% Copyright 2017 by The University of Oxford and The CHEBFUN Developers.
% See http://www.chebfun.org/ for CHEBFUN information.

% Primary author: Alex Townsend, January 2017.

% Convert to NUFFT2D convention (from Spherefun's convention):
lambda = -lambda/(2*pi);
theta  = -theta/(2*pi);

% Working tolerance:
% tol = 10*eps; % This is hardcoded in choice of K1 and K2 below.

% Get size of evaluation points and Fourier coefficients:
[M, N] = size(lambda);
[n, m] = length(f);
m = m + (1-mod(m,2));
n = n + (1-mod(n,2));

% Low rank approximation for the coefficients of F:
[C, D, R] = coeffs2(f, n, m);
rk = size(D,1);

% Make columns:
lambda = lambda(:);
theta = theta(:);

% Assign each evaluation point to its closest point on a 2D equispaced grid:
xj = round(n*lambda)/n;
xt = mod(round(n*lambda),n)+1;
yj = round(m*theta)/m;
yt = mod(round(m*theta),m)+1;

% Fourier modes:
mm = -floor(m/2):floor(m/2);
nn = -floor(n/2):floor(n/2);

%%%%%%%%%%%%%%%% FAST TRANSFORM %%%%%%%%%%%%%%%%
% Ay = exp(-2*pi*1i*m*(y(:)-yj(:))*mm/m);
% Find low rank approximation to Ay = U1*V1.':
er = m*(theta-yj);
gam = norm(er, inf);
% K1 = ceil(5*gam*exp(lambertw(log(10/tol)/gam/7)))
K1 = 15;
U1 = chebT(K1-1,er/gam) * besselCoeffs(K1, gam);
V1 = chebT(K1-1, 2*mm'/m);

% Ax = exp(-2*pi*1i*n*(x(:)-xj(:))*nn/n);
% Find low rank approximation to Ax = U2*V2.':
er = n*(lambda-xj);
gam = norm(er, inf);
% K2 = ceil(5*gam*exp(lambertw(log(10/tol)/gam/7)));
K2 = 15;
U2 = ( chebT(K2-1,er/gam) * besselCoeffs(K2, gam) ).';
V2 = chebT(K2-1, 2*nn'/n);

% Business end of the transform. (Everything above could be considered
% precomputation.)
FFT_cols = zeros(m,rk,K1);
for s = 1:K1
    % Transform in the "col" variable:
    FFT_cols(:,:,s) = fft( ifftshift(bsxfun(@times, C, V1(:,s)),1) );
end
FFT_rows = zeros(rk,n,K2);
for r = 1:K2
    % Transform in the "row" variable:
    FFT_rows(:,:,r) = D*fft(ifftshift(bsxfun(@times,R,V2(:,r)).',2),[],2);
end

% Permute:
XX = permute(FFT_rows,[1 3 2]);
YY = permute(FFT_cols,[3 2 1]);
% Convert to cell for speed:
X = cell(n,1);
for k = 1:n
    X{k} = XX(:,:,k);
end
Y = cell(size(YY,3),1);
for k = 1:m
    Y{k} = YY(:,:,k);
end

% Spread the love out from equispaced points to actual evaluation points. Do
% this K1*K2 times for an accurate transform:
[ii, jj] = ind2sub([m,n], yt(:)+m*(xt(:)-1));

% Do only unique multiplications:
[c, ~, ic] = unique([ii, jj], 'rows');
YX = cell(size(c,1), 1);
Y = Y(c(:,1));
X = X(c(:,2));
for idx = 1:size(c,1)
    YX{idx} = Y{idx} * X{idx};
end

% Recover A:
vals = zeros(M, N);
for idx = 1:M*N
   vals(idx) = U1(idx,:) * (YX{ic(idx)} * U2(:,idx));
end

end

function cfs = besselCoeffs(K, gam)
% The bivarate Chebyshev coefficients for the function f(x,y) = exp(-i*x.*y) on
% the domain [-gam, gam]x[0,2*pi] are given by Lemma A.2 of Townsend's DPhil
% thesis.
arg = -gam*pi/2;
[pp, qq] = meshgrid(0:K-1);
cfs = 4*(1i).^qq.*besselj((pp+qq)/2,arg).*besselj((qq-pp)/2, arg);
cfs(2:2:end,1:2:end) = 0;
cfs(1:2:end,2:2:end) = 0;
cfs(1,:) = cfs(1,:)/2;
cfs(:,1) = cfs(:,1)/2;
end

function T = chebT(n, x)
% Evaluate Chebyshev polynomials of degree 0,...,n at points in x. Use the
% three-term recurrence relation:
N = size(x, 1);
T = zeros(N, n+1);
T(:,1) = 1;
T(:,2) = x;
twoX = 2*x;
for k = 2:n
    T(:,k+1) = twoX.*T(:,k) - T(:,k-1);
end
end