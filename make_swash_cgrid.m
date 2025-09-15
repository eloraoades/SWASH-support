% File: make_swash_cgrid.m
function [cgrid_line, details] = make_swash_cgrid(Out, opts)
%MAKE_SWASH_CGRID Build the SWASH "CGRID" command line from Out.x/y/z.
%
% Usage
%   [cgrid_line, details] = make_swash_cgrid(Out)
%   [cgrid_line, details] = make_swash_cgrid(Out, opts)
%
% Inputs
%   Out.x, Out.y, Out.z : ny-by-nx grids (meshgrid-style arrays)
%   opts (struct, optional):
%       .precision  -> decimals in sprintf                 (default 3)
%       .repeat     -> 'none'|'X'|'Y' to append REPEATING  (default 'none')
%       .alpc       -> grid x-axis angle (deg CCW)         (default 0)
%
% Outputs
%   cgrid_line : char, e.g.
%       CGRID REGULAR xpc ypc alpc xlenc ylenc mxc myc [REPEATING X|Y]
%   details    : struct with fields: xpc, ypc, alpc, xlenc, ylenc, mxc, myc, rx, sy, dx, dy

if nargin < 2 || isempty(opts), opts = struct(); end
if ~isfield(opts, 'precision') || isempty(opts.precision), opts.precision = 3; end
if ~isfield(opts, 'repeat')    || isempty(opts.repeat),    opts.repeat    = 'none'; end
if ~isfield(opts, 'alpc')      || isempty(opts.alpc),      opts.alpc      = 0; end

% normalize input opts type
opts.precision = double(opts.precision);
opts.alpc      = double(opts.alpc);
opts.repeat    = char(string(opts.repeat));


% shape 
[ny, nx] = size(Out.z);
assert(isequal(size(Out.x), [ny, nx]) && isequal(size(Out.y), [ny, nx]), ...
    'Out.x, Out.y, Out.z must be ny-by-nx arrays of equal size.');

% geometry from SW corner
xpc = Out.x(1,1);
ypc = Out.y(1,1);

% edge vectors (used only for lengths)
rx = [Out.x(1,2) - Out.x(1,1), Out.y(1,2) - Out.y(1,1)];
sy = [Out.x(2,1) - Out.x(1,1), Out.y(2,1) - Out.y(1,1)];

% meshes (points-1)
mxc = nx - 1;
myc = ny - 1;

% physical extents
dx = hypot(rx(1), rx(2));
dy = hypot(sy(1), sy(2));
xlenc = mxc * dx;
ylenc = myc * dy;

% format numbers with requested precision
fmt = @(v) num2str(v, ['%.' num2str(opts.precision) 'f']);
nums = strjoin({fmt(xpc), fmt(ypc), fmt(opts.alpc), fmt(xlenc), fmt(ylenc), ...
                num2str(mxc), num2str(myc)}, ' ');

cgrid_line = ['CGRID REGULAR ' nums];
rep = upper(strtrim(opts.repeat));
if any(strcmp(rep, {'X','Y'}))
    cgrid_line = [cgrid_line ' REPEATING ' rep];
end

% outputs
cgrid_line = char(cgrid_line);
details = struct('xpc',xpc,'ypc',ypc,'alpc',opts.alpc,'xlenc',xlenc,'ylenc',ylenc, ...
                 'mxc',mxc,'myc',myc,'rx',rx,'sy',sy,'dx',dx,'dy',dy);
end
