function [isDone, epsLevel, vscale, cutoff] = testConvergence(disc, values, vscale, pref)
%TESTCONVERGENCE   Happiness check.
%   Given: 
%      DISC: chebDiscretization, 
%      VALUES: a cell array of scalars/sampled function values (see the
%           toFunction method),
%      VSCALE: scalar value giving the desired scale by which to measure
%           relative convergence against (defaults to 0, which means use
%           the intrinsic scale of the result),
%      PREF: A cheboppref() options structure.
%
%   Output:  
%      ISDONE: True if the functions passed in are sufficiently resolved.
%      EPSLEVEL: Apparent resolution accuracy (relative to VSCALE or the
%      functions' intrinsic scale).

% Copyright 2014 by The University of Oxford and The Chebfun Developers.
% See http://www.chebfun.org/ for Chebfun information.

if ( nargin < 4 )
    pref = cheboppref;
    if ( nargin < 3 )
        vscale = 0;   % will have no effect
    end
end

% Convert to a piecewise array-valued CHEBFUN.
u = toFunctionOut(disc, cat(2, values{:}));
numCol = size(u, 2);

% This is a cell array of coefficients (one for each piece).
coeffs = get(u, 'coeffs', 1);

d = disc.domain;
numInt = numel(d) - 1;
isDone = false(numInt, 1);
cutoff = zeros(numInt, numCol);
epsLevel = 0;

% Get the discretization.
if ( isequal(pref.discretization, @colloc1) )
    tech = chebtech1;
elseif ( isequal(pref.discretization, @colloc2) )
    tech = chebtech2;
elseif ( isequal(pref.discretization, @collocFour) )
    tech = fourtech;
else
    tech = chebtech2;
end

% If an external vscale was supplied, it can supplant the inherent scale of the
% result.
vscale = max(u.vscale, max(vscale));
%prefTech = chebtech.techPref();
prefTech = tech.techPref();
prefTech.eps = pref.errTol;

% [TODO]: imrpove this.
% First, do we want to create a CHEBTECH2 even if using COLLOC1?
% Second, is it the right way to implement this?
% Test convergence on each piece.
% if ( ~isa(disc, 'collocFour') )
%     for i = 1:numInt
%         c = cat(2, coeffs{i,:});
%         f = chebtech2({[], c});
%         f.vscale = vscale;
%         [isDone(i), neweps, cutoff(i,:)] = plateauCheck(f, get(f,'values'), prefTech);
%         epsLevel = max(epsLevel, neweps);
%     end
% else
%     for i = 1:numInt
%     c = cat(2, coeffs{i,:});
%     f = fourtech({[], c});
%     f.vscale = vscale;
%     [isDone(i), neweps, cutoff(i,:)] = plateauCheck(f, prefTech);
%     epsLevel = max(epsLevel, neweps);
%     end
% end

for i = 1:numInt
    c = cat(2, coeffs{i,:});
    f = tech.make({[], c});
    f.vscale = vscale;
    [isDone(i), neweps, cutoff(i,:)] = plateauCheck(f, get(f,'values'), prefTech);
    epsLevel = max(epsLevel, neweps);
end

isDone = all(isDone, 2);

end