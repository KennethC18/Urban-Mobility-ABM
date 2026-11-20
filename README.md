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

- `results/pso_<scenario>_limpio.csv`: one row per PSO evaluation (`iteracion` 0 = initial swarm).
- `results/transferencia*.csv`: transfer / robustness runs.
- `videos/south_normal.mp4`, `videos/south_x3_300.mp4`: South with default capacity (700 veh/h/lane)
  and with 300 veh/h/lane (cars in red, PT in blue, links coloured by v/c).

Work in progress: PSO for `South` and `GDL_Oeste` and the transfer test are still running.
