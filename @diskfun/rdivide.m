function varargout = rdivide(varargin)
%./   Pointwise right divide of DISKFUN objects.
%   F./G if F is a DISKFUN and G is a double this returns (1/G)*F
%
%   F./G if F is a double and G is a v this returns F/G, but this doe
%   not work if G becomes numerically close to zero.
%
%   F./G we do not allow F and G to both be DISKFUN object.
% 
%   F./G is the same as the command rdivide(F,G)
%
% See also DISKFUN/LDIVIDE.

% Copyright 2016 by The University of Oxford and The Chebfun Developers.
% See http://www.chebfun.org/ for Chebfun information.

[varargout{1:nargout}] = rdivide@separableApprox(varargin{:});

end
