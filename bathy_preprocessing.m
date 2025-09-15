%% Bottom Boundary Preprocessing

c = ("cmocean"); % insert filepath here 
addpath(c); 

%% Import survey data (non-gridded) 
T = readtable('survey_data.xlsx', ...
              'Sheet', '20171011', ...    % <-- Select the day (sheet) 
              'Range', 'H:J');

T.Properties.VariableNames = {'x','y','z'};

%% Select area of interest & remove nans
mask = (T.x > 50 & T.x < 1200) & (T.y > -100 & T.y < 1200);

x = T.x(mask);
y = T.y(mask);
z = T.z(mask);

good = ~(isnan(x) | isnan(y) | isnan(z));
x = x(good); y = y(good); z = z(good);

%% Build grid onto which we'll project z 
dx = 2;     % meters in x (cross-shore)
dy = 6;     % meters in y (alongshore)

xmin = round(min(x)); xmax = round(max(x));
ymin = round(min(y)); ymax = round(max(y));

xg = floor(xmin/dx)*dx : dx : ceil(xmax/dx)*dx;
yg = floor(ymin/dy)*dy : dy : ceil(ymax/dy)*dy;

[Xg, Yg] = meshgrid(xg, yg);

F = scatteredInterpolant(x, y, z, 'natural', 'none');  % no extrapolation
Zg = F(Xg, Yg);

%% Quick figure check 

figure(); 
pcolor(xg, yg, Z_y); axis tight equal; 
shading flat; colorbar(); clim([-14 2])
cmocean('topo', 'pivot', 0); 
xlabel('x (m)'); ylabel('y (m)'); title('Gridded Z (NAVD88, m)');

% Overlay raw points to sanity-check
hold on; plot(x, y, 'k.', 'MarkerSize', 4);

%% Fill in missing data 

Z_y = fillmissing(Zg, 'previous', 1, 'EndValues', 'nearest'); % in the alongshore 
% Z_xy = fillmissing(Z_y, 'previous', 2, 'EndValues', 'nearest');

% & Plot 
figure(); 
pcolor(xg, yg, Z_xy); axis tight equal; shading flat; 
colorbar(); 
xlabel('x (m)'); ylabel('y (m)'); title('Gridded z (NAVD88, m)');

% Overlay survey collection points 
hold on; plot(x, y, 'k.', 'MarkerSize', 4);

%% Extend bathy to enable repeatable boundary conditions alongshore 

[Out, fig1, fig2] = bathy_extend(Xg, Yg, Z_y, 3);

%% Write swash CGRID line 

opts = struct();
opts.precision = 0;   % decimals
opts.repeat    = 'Y';
opts.alpc      = 0;   % degrees CCW (no rotation)

[cgrid, info] = make_swash_cgrid(Out, opts);

disp(info);

%% Write SWASH Bathy Text file 

% (idla=1, precision=3, no headers)
[info, readinp] = write_swash_bathy_txt(Out, 'bathy.txt');
disp(readinp); 

% 2) Make INPGRID BOTTOM line identical to computational grid, alpinp=0
[inpgrid, det] = make_swash_inpgrid(Out, opts);
disp(inpgrid);
% -> INPGRID BOTTOM REGULAR xpinp ypinp 0 mx my dx dy