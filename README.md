# Urban Mobility ABM (GAMA)

Agent-based model of commuter mode choice (car vs. public transport) on real road networks of the
Guadalajara metropolitan area (Tlaquepaque and surroundings), built in [GAMA Platform](https://gama-platform.org).
Presented at GAMA Days (ITESO, with Prof. Gamaliel Palomo-Briones).

## Model (`models/UrbanMobility.gaml`)

- **Road network** from shapefiles, converted to a graph (largest connected component only).
- **Commuters** (600 agents) travel home ↔ work; 70 % own a car. Car owners choose a mode with a logit rule
  that compares the car time with a *perceived* PT time = real PT time × (1 + bias). The bias decays 2.5 %
  each time the agent uses PT.
- **Congestion**: BPR function per link. Flow is computed as `q = N · 60 / t_free` (veh/h) and compared with
  `lanes × lane_capacity_per_hour`. Lanes and free speed come from the OSM `highway` tag when available.
- **Objective**: average **realized** travel time (including PT waiting) over the last 100 cycles, plus a
  penalty for violating a PT budget constraint `g1`.

### Scenarios (`scenario` parameter)

| Scenario | Drivable links used | Agents × persons/agent |
|---|---|---|
| `Lomas` | 589 | 600 × 1 |
| `South` (Tlaquepaque) | 6,429 | 600 × 2 |
| `GDL_Oeste` | 7,110 (from ~34,000 OSM features) | 600 × 2 |

Demand levels were chosen with a sweep so that every network is congested without gridlock; they are
**not** observed demand.

### Fixes in this version (vs. the early model)
1. `follow` moves in *graph-weight units*: once weights were set to minutes, cars teleported along their
   whole path in one cycle. Fixed with `move_weights` in metres.
2. Speed was passed in km/h where the `moving` skill expects m/s (`#km / #h` conversion added).
3. Multiplicative acceleration could never recover from ~0 km/h, gridlocking the network.
   Added `min_speed_kmh` (crawl speed in jams).
4. Volume (vehicles on a link) was divided by an hourly capacity (unit mismatch), so congestion was ~0.

## Optimization

- `models/optimizacion_batch.gaml`: Hill-Climbing and PSO on `South`.
- `models/pso_comun.gaml` + `pso_lomas.gaml`, `pso_south.gaml`, `pso_gdl.gaml`: the **same PSO**
  (8 particles, 5 iterations) on each scenario. Decision variables: `pt_speed_factor` ∈ [1, 5],
  `pt_wait_time` ∈ [0, 60] min, `lane_capacity_per_hour` ∈ [100, 1050].
- Transfer test (`scripts/gen_transfer.py` → `models/transferencia.gaml`): each scenario's best x* is
  evaluated on all three networks with seeds 1–5, to test whether one configuration fits all cases.

Run headless, e.g.: `gama-headless -m 9g -hpc 4 -batch PSO_South models/pso_south.gaml`
(limit the heap with `-m`; the default `-Xmx16G` can exceed the machine's RAM).

## Results

All runs: 500 cycles of 10 s (~83 simulated minutes); objective = mean realized travel time over the last
100 cycles (min) plus budget penalty.

### PSO per scenario (8 particles, 5 iterations, 48 evaluations, seed fixed)

| Scenario | x* (pt_speed_factor, pt_wait_time, lane_capacity) | f(x*) (min) | g1(x*) | car share | Evaluations | Time |
|---|---|---|---|---|---|---|
| Lomas | (5.00, 3.25, 958) | 8.54 | −17.87 | 0.88 | 48 | 4.9 min |
| South | (3.16, 5.82, 1050) | 11.76 | −18.55 | 0.95 | 48 | 37.9 min |
| GDL_Oeste | (2.87, 8.27, 1050) | 23.86 | −19.57 | 0.99 | 48 | 137.4 min |

None of the three runs converged (best value found in iterations 2–3, not improved afterwards).
The budget constraint is inactive at every x*; road capacity is the dominant lever.
Files: `results/pso_<scenario>_limpio.csv` (`iteracion` 0 = initial swarm).

### Transfer and robustness (each x* on every network, 5 seeds; mean ± sd of f in minutes)

| x* from \ evaluated on | Lomas | South | GDL_Oeste |
|---|---|---|---|
| x*_Lomas | **8.74 ± 0.15** | 14.17 ± 0.25 (+23 %) | 29.71 ± 1.40 (+30 %) |
| x*_South | 7.90 ± 0.23 (−10 %) | **11.51 ± 0.21** | 23.36 ± 0.94 (+2 %) |
| x*_GDL_Oeste | 8.31 ± 0.17 (−5 %) | 11.90 ± 0.21 (+3 %) | **22.94 ± 0.85** |

- The configuration tuned on the small network (Lomas) transfers badly to the larger ones (+23 % and +30 %,
  Welch t = 18.5 and 9.2).
- x*_South and x*_GDL_Oeste are nearly interchangeable (+1.8 % in GDL_Oeste, t = 0.7; +3.4 % in South, t = 2.9).
- On Lomas, the other networks' x* beat Lomas' own x* — with only 48 evaluations PSO did not reach Lomas' optimum.
- Seed-to-seed variability: sd of T 2–5 %, sd of car share ≤ 0.022.

Key case, South with default PT and 300 veh/h/lane (5 seeds): T = 31.06 ± 0.84 min, car share 0.975 ± 0.007;
realized car time 34.1 ± 0.7 min vs. realized PT time 20.5 ± 1.2 min (averages over different trips).

Files: `results/transferencia.csv` (one row per run; the `seed` column always shows 1.0 — GAMA logs the
experiment seed, but each run used seed 1–5), `results/transferencia_resumen.csv`.

### Videos
`videos/south_normal.mp4`, `videos/south_x3_300.mp4`: South with default capacity (700 veh/h/lane) and with
300 veh/h/lane (cars in red, PT in blue, links coloured by v/c).

### Notes on running
GDL_Oeste must be run with one simulation per JVM (`-hpc 1`): several GDL_Oeste simulations initialised in
parallel in the same JVM occasionally end with removed links inside the network and a hung batch.
