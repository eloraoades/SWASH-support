# SWASH-support

Utilities for **pre-processing** (building computational/input grids, writing bathymetry) and **post-processing** (quick figures & movies) around [SWASH]([https://www.swash](https://swash.sourceforge.io)) runs. The focus is small, composable MATLAB functions you can drop into your own workflow.

> Status: early-stage, but already usable for 2D regular grids (rectilinear or rotated). Expect breaking changes while the API stabilizes.

---

## What’s inside

### Pre-processing

* **`bathy_extend.m`** – extend a bathymetric domain by mirroring edge profiles (adds \~25% per side) and plot original vs extended fields.
* **`bathy_preprocessing.m`** – download bathy bathy data, generate SWASH input bathy txt file.
* **`make_swash_cgrid.m`** – write `CGRID REGULAR ...` line for the SWASH computational grid from `Out.x/y/z`.
* **`make_swash_inpgrid.m`** – write `INPGRID BOTTOM REGULAR ...` line (input grid for bottom data).
* **`write_swash_bathy_txt.m`** – write ASCII bathymetry in SWASH `READINP BOTTOM` layout (`idla=1`).

### Post-processing

* **`figHs.m`** – quick-look plot of significant wave height.
* **`watlevMovie.m`** – movie visualisation of water level output.
* **`postproc_main.m`** – example function for post-processing.

> See each function’s header for arguments, defaults, and notes.

---

## Conventions & defaults

These are the current defaults used by helpers here:

* **Grid regularity**: assumes a *regular* mesh (uniform steps). Curvilinear support is a future item.
* **Angles**: `alpc=0` (x-axis aligned with global x) unless you pass a value.
* **Input grid ≡ computational grid** by default (`make_swash_inpgrid`).
* **Bathymetry sign**: files are written as **`Out.z`** directly (often negative), and the SWASH side uses **`fac=-1`** in `READINP BOTTOM`.
* **ASCII layout**: `idla=1` (= row-wise, start at *upper-left*, rows written **top→down**, left→right).
* **Precision**: 3 decimals for bathy txt file, 0 for .sws lines 
* **No headers** in the bathy text file (`nhedf=0`).

---

## Quickstart

### 1) Build/extend your bathy and produce an `Out` struct

```matlab
% xIn, yIn, zIn are ny-by-nx (meshgrid-style). Toggle selects inward edge.
[Out, fig1, fig2] = bathy_extend(xIn, yIn, zIn, toggle);
```

### 2) Generate SWASH grid lines

```matlab
% CGRID (computational grid)
optsC = struct('precision',0, 'repeat','none', 'alpc',0);
[cgrid_line, cgrid_info] = make_swash_cgrid(Out, optsC);

% INPGRID BOTTOM (input grid for bottom data) — identical to CGRID here
optsI = struct('precision',0, 'alpinp',0);
[inpgrid_line, inpgrid_info] = make_swash_inpgrid(Out, optsI);

fprintf('%s\n%s\n', cgrid_line, inpgrid_line);
```

### 3) Write the bathymetry ASCII file for `READINP BOTTOM`

```matlab
% idla=1, nhedf=0, precision=3
[info, readinp_line] = write_swash_bathy_txt(Out, 'bathy.txt', struct('precision',0));
fprintf('%s\n', readinp_line);
% -> READINP BOTTOM -1 'bathy.txt' 1 0 FREE
```

### 4) Drop the three lines into your `.sws`

```text
CGRID   REGULAR ...
INPGRID BOTTOM REGULAR ...
READINP BOTTOM -1 'bathy.txt' 1 0 FREE
```

### 5) Post-process (examples will vary by your SWASH outputs)

```matlab
% See headers for expected inputs; adapt to your file layout
figHs(...);
watlevMovie(...);
```

---

## Tips 

* **Units**: helpers assume meters (m) and degrees (°) for angles.
* **Rotation**: Do not rotate your bathy grid -- it is easier to rotate your input spectra.
* **NaNs**: `write_swash_bathy_txt` rejects NaNs by default. Clean them or add an EXCEPTION in SWASH (future helper may expose this).
* **Mesh counts**: remember SWASH uses *meshes* not 'points' i.e. (`points-1`) for `mx*`/`my*`.

---

## Contributing

PRs welcome! Please open an issue to discuss changes, especially interface/IO formats.
