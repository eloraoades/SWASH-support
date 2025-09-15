function [inpgrid_line, details] = make_swash_inpgrid(Out, opts)
%MAKE_SWASH_INPGRID  Build SWASH INPGRID BOTTOM REGULAR ... line from Out.x/y.
%
% Usage
%   [line, details] = make_swash_inpgrid(Out)
%   [line, details] = make_swash_inpgrid(Out, opts)
%
% Inputs
%   Out.x, Out.y : ny-by-nx coordinate grids (meshgrid-style arrays)
%   opts (struct, optional):
%       .precision -> decimals for numeric formatting (default 3)
%       .alpinp    -> grid x-axis angle (deg CCW) (default 0)
%
% Outputs
%   inpgrid_line : char
%       INPGRID BOTTOM REGULAR xpinp ypinp alpinp mxinp myinp dxinp dyinp
%   details      : struct with fields xpinp, ypinp, alpinp, mxinp, myinp, dxinp, dyinp
%
% Assumptions: identical to computational grid; no exception value; stationary.

if nargin < 2 || isempty(opts), opts = struct(); end
if ~isfield(opts,'precision') || isempty(opts.precision), opts.precision = 3; end
if ~isfield(opts,'alpinp')    || isempty(opts.alpinp),    opts.alpinp    = 0; end

[ny, nx] = size(Out.x);
assert(isequal(size(Out.y), [ny,nx]), 'Out.x and Out.y must be same size.');

xpinp = Out.x(1,1);
ypinp = Out.y(1,1);
mxinp = nx - 1;
myinp = ny - 1;

% mesh sizes from first steps (no uniformity checks)
dxinp = Out.x(1,2) - Out.x(1,1);
dyinp = Out.y(2,1) - Out.y(1,1);

fmt = @(v) num2str(v, ['%0.' num2str(opts.precision) 'f']);
nums = strjoin({fmt(xpinp), fmt(ypinp), fmt(opts.alpinp), ...
                num2str(mxinp), num2str(myinp), fmt(dxinp), fmt(dyinp)}, ' ');

inpgrid_line = ['INPGRID BOTTOM REGULAR ' nums];

details = struct('xpinp',xpinp,'ypinp',ypinp,'alpinp',opts.alpinp, ...
                 'mxinp',mxinp,'myinp',myinp,'dxinp',dxinp,'dyinp',dyinp);
end