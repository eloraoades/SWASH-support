function [info, readinp_bottom_line] = write_swash_bathy_txt(Out, filename, opts)
%WRITE_SWASH_BATHY_TXT  Write bathymetry to ASCII file for SWASH READINP BOTTOM.
%
% Usage
%   [info, readinp_line] = write_swash_bathy_txt(Out, filename)
%   [info, readinp_line] = write_swash_bathy_txt(Out, filename, opts)
%
% Inputs
%   Out.x, Out.y, Out.z : ny-by-nx grids (meshgrid-style arrays)
%   filename            : output text file path
%   opts (struct, optional):
%       .precision  -> decimals for numeric formatting (default 3)
%       .idla       -> SWASH lay-out, only 1 supported here (default 1)
%       .nhedf      -> number of header lines (written = 0) (default 0)
%       .allowNaN   -> if true, allow NaN values (user must set EXCEPTION elsewhere). Default false.
%
% Outputs
%   info: struct with nx, ny, mxc, myc, idla, nhedf, precision, count, filename
%   readinp_bottom_line: ready-to-paste SWASH command, using fac=-1, FREE format:
%       READINP BOTTOM -1 'filename' idla nhedf FREE
%
% Why: idla=1 means write rows starting at the upper-left corner, left->right, row by row downward.

% ----------- defaults (nargin-friendly) -----------
if nargin < 3 || isempty(opts), opts = struct(); end
if ~isfield(opts,'precision') || isempty(opts.precision), opts.precision = 3; end
if ~isfield(opts,'idla')      || isempty(opts.idla),      opts.idla = 1; end
if ~isfield(opts,'nhedf')     || isempty(opts.nhedf),     opts.nhedf = 0; end
if ~isfield(opts,'allowNaN')  || isempty(opts.allowNaN),  opts.allowNaN = false; end

% ----------- validate -----------
[ny, nx] = size(Out.z);
assert(isequal(size(Out.x), [ny,nx]) && isequal(size(Out.y), [ny,nx]), ...
    'Out.x, Out.y, Out.z must be ny-by-nx arrays of equal size.');
assert(nx >= 1 && ny >= 1, 'Non-empty grids required.');
assert(opts.idla == 1, 'This writer currently supports only idla=1.');
if ~opts.allowNaN && any(~isfinite(Out.z(:)))
    error('Out.z contains NaN/Inf. Either clean the data or set opts.allowNaN=true and use INPGRID ... EXCEPTION.');
end

% ----------- open file -----------
[fid, msg] = fopen(filename, 'w');
if fid < 0, error('Failed to open file: %s', msg); end

% ----------- write rows (idla=1: from upper-left, left->right, row by row downward) -----------
fmtNum = ['%0.' num2str(opts.precision) 'f'];
fmtRow = [repmat([fmtNum ' '], 1, nx-1) fmtNum '\n'];

count = 0;
try
    % No header lines for nhedf=0 per your spec.
    for r = ny:-1:1                % start at upper row
        rowvals = Out.z(r, :);
        fprintf(fid, fmtRow, rowvals);
        count = count + nx;
    end
catch ME
    fclose(fid);
    rethrow(ME);
end
fclose(fid);

% ----------- outputs -----------
info = struct('nx',nx,'ny',ny,'mxc',nx-1,'myc',ny-1,'idla',opts.idla, ...
              'nhedf',opts.nhedf,'precision',opts.precision,'count',count, ...
              'filename',string(filename));

readinp_bottom_line = sprintf("READINP BOTTOM -1 '%s' %d %d FREE", filename, opts.idla, opts.nhedf);
end
