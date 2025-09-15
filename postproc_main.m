function swash = postproc_main(runDir, outDir, opts)
%PROCESS_SWASH_OUTPUTS
%
% Usage
%   swash = process_swash_outputs(runDir)
%   swash = process_swash_outputs(runDir, outDir)
%   swash = process_swash_outputs(runDir, outDir, opts)
%
% Inputs
%   runDir  : folder with SWASH .mat outputs
%   outDir  : folder to save results (default = runDir)
%   opts    : struct with fields (all optional)
%             .HsMin       (default 0.05)
%             .MaskOnshore (default true)
%             .SaveOutputs (default true)
%
% Output
%   swash : struct with fields
%           grid: Xp,Yp,Botlev,tide,spec1D,f,size
%           time: t (seconds from start)
%           etaAll, Hs, bkpt, (Qb?, normQb?)
%           vel: dirBar, magBar, etaBar, ksiBar


if nargin < 1 || isempty(runDir), error('runDir is required'); end
if nargin < 2 || isempty(outDir), outDir = runDir; end
if nargin < 3, opts = struct(); end

% Defaults
if ~isfield(opts,'HsMin'), opts.HsMin = 0.05; end
if ~isfield(opts,'MaskOnshore'), opts.MaskOnshore = true; end
if ~isfield(opts,'SaveOutputs'), opts.SaveOutputs = true; end

% Index all variables once
idx = build_index(runDir);

% Grid + time
[grid] = load_grid(idx);
[t]     = load_time(idx);

% Water levels → etaAll, Hs
etaAll = load_stack(idx, 'Wat*', grid.size);
Hs = squeeze(4 * sqrt(var(etaAll, 0, 1, 'omitnan')));
maskHs = Hs < opts.HsMin;                         % hides noise / dry
etaAll = mask3d(etaAll, maskHs);
Hs(maskHs) = NaN;

% Breaking
bkpt = load_stack(idx, 'Brkpnt*', grid.size);
if opts.MaskOnshore && ~isempty(grid.Botlev)
    onshore = grid.Botlev <= 0;                    % avoid land
    bkpt = mask3d(bkpt, onshore);
end

% Qb (optional)
Qb = []; normQb = [];
if exist('calculateQb','file') == 2
    try
        [Qb, normQb] = calculateQb(grid.Xp, grid.Botlev, grid.spec1D, grid.f, t, bkpt);
    catch e
        warning(e.identifier, 'calculateQb failed: %s', e.message);
    end
end

% Velocities (time means)
vDir = load_stack(idx, 'Vdir_*', grid.size);
vMag = load_stack(idx, 'Vmag_*', grid.size);
vEta = load_stack(idx, 'Veta_*', grid.size);
vKsi = load_stack(idx, 'Vksi_*', grid.size);

vel.dirBar = squeeze(mean(vDir, 1, 'omitnan'));
vel.magBar = squeeze(mean(vMag, 1, 'omitnan'));
vel.etaBar = squeeze(mean(vEta, 1, 'omitnan'));
vel.ksiBar = squeeze(mean(vKsi, 1, 'omitnan'));

% Mask velocity means where waves are negligible
vel.dirBar(maskHs) = NaN;
vel.magBar(maskHs) = NaN;
vel.etaBar(maskHs) = NaN;
vel.ksiBar(maskHs) = NaN;

% Pack
swash = struct();
swash.meta.runDir = char(runDir);
swash.meta.created = datetime("now", 30);
swash.grid = grid;
swash.time.t = t;
swash.etaAll = etaAll;
swash.Hs = Hs;
swash.bkpt = bkpt;
if ~isempty(Qb), swash.Qb = Qb; end
if ~isempty(normQb), swash.normQb = normQb; end
swash.vel = vel;

% Save
if opts.SaveOutputs
    if ~exist(outDir,'dir'), mkdir(outDir); end
    save(fullfile(outDir, 'swash_processed.mat'), 'swash', '-v7.3');
end
end

% ------------ helpers  ------------
function idx = build_index(runDir)
files = dir(fullfile(runDir, '*.mat'));
if isempty(files), error('No .mat files found in %s', runDir); end
rows = cell(0,3);
for k = 1:numel(files)
    fpath = fullfile(files(k).folder, files(k).name);
    w = whos('-file', fpath);
    for j = 1:numel(w)
        rows(end+1,:) = {fpath, w(j).name, w(j).size}; 
    end
end
idx = cell2table(rows, 'VariableNames', {'file','var','size'});
end

function rows = find_vars(idx, pattern)
re = regexptranslate('wildcard', pattern);
sel = ~cellfun('isempty', regexp(idx.var, re, 'once'));
rows = idx(sel, :);
rows = sort_natural(rows);
end

function rows = sort_natural(rows)
% keep Wat_2 < Wat_10
names = rows.var;
N = numel(names); base = strings(N,1); num = zeros(N,1);
for i = 1:N
    tok = regexp(names{i}, '^(.*?)(\d+)$', 'tokens', 'once');
    if isempty(tok), base(i) = string(names{i}); num(i) = 0; else
        base(i) = string(tok{1}); num(i) = str2double(tok{2});
    end
end
T = table(base, num);
[~, ord] = sortrows(T, {'base','num'});
rows = rows(ord, :);
end

function S = load_var(file, varname)
T = load(file, varname);
S = T.(varname);
end

function [grid] = load_grid(idx)
Xp = []; Yp = []; Botlev = []; tide = []; spec1D = []; f = [];
% try to get grid first
r = find_vars(idx, 'Xp'); if ~isempty(r), Xp = load_var(r.file{1}, r.var{1}); end
r = find_vars(idx, 'Yp'); if ~isempty(r), Yp = load_var(r.file{1}, r.var{1}); end
r = find_vars(idx, 'Botlev'); if ~isempty(r), Botlev = load_var(r.file{1}, r.var{1}); end
r = find_vars(idx, 'tide'); if ~isempty(r), tide = load_var(r.file{1}, r.var{1}); end
r = find_vars(idx, 'spec1D'); if ~isempty(r), spec1D = load_var(r.file{1}, r.var{1}); end
r = find_vars(idx, 'f'); if ~isempty(r), f = load_var(r.file{1}, r.var{1}); end

if ~isempty(Xp)
    gsize = size(Xp);
else
    % fallback: read one Wat*
    wr = find_vars(idx, 'Wat*');
    if isempty(wr), error('Cannot infer grid size: missing Xp and Wat*'); end
    A = load_var(wr.file{1}, wr.var{1});
    gsize = size(A);
end

grid = struct('Xp', Xp, 'Yp', Yp, 'Botlev', Botlev, 'tide', tide, ...
              'spec1D', spec1D, 'f', f, 'size', gsize);
end

function t = load_time(idx)
rows = find_vars(idx, 'Tsec_*');
if isempty(rows)
    warning('No Tsec_* variables found; t = []');
    t = []; return;
end
T = zeros(height(rows),1);
for i = 1:height(rows)
    v = load_var(rows.file{i}, rows.var{i});
    T(i) = v(1,1);
end
t = T - T(1);
end

function data = load_stack(idx, pattern, gsize)
rows = find_vars(idx, pattern);
if isempty(rows)
    data = zeros(0, gsize(1), gsize(2));
    return;
end
nT = height(rows);
data = NaN(nT, gsize(1), gsize(2));
for i = 1:nT
    A = load_var(rows.file{i}, rows.var{i});
    if ~isequal(size(A,1), gsize(1)) || ~isequal(size(A,2), gsize(2))
        error('%s has size %s, expected [%d %d]', rows.var{i}, mat2str(size(A)), gsize(1), gsize(2));
    end
    data(i,:,:) = A;
end
end

function out = mask3d(arr, mask2d)
if isempty(arr) || isempty(mask2d)
    out = arr; return;
end
out = arr;
repMask = repmat(logical(mask2d), [size(arr,1), 1, 1]);
out(repMask) = NaN;
end
