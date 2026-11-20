# Uso: python3 -I gen_transfer.py <results_dir> <models_dir> [etiquetas_separadas_por_coma] [archivo_salida.gaml]
#   etiquetas: subconjunto de xstar_Lomas,xstar_South,xstar_GDL_Oeste,base_x3_300 (por defecto: todas)
#   Omite las combinaciones (config, escenario, semilla) que ya estén en results/transferencia.csv,
#   para poder adelantar una parte en paralelo sin repetirla.
import csv, os, sys
res, mdir = sys.argv[1], sys.argv[2]
escs = ['Lomas', 'South', 'GDL_Oeste']
wanted = sys.argv[3].split(',') if len(sys.argv) > 3 and sys.argv[3] else [f'xstar_{e}' for e in escs] + ['base_x3_300']
outname = sys.argv[4] if len(sys.argv) > 4 else 'transferencia.gaml'
done = set()
tf = os.path.join(res, 'transferencia.csv')
if os.path.exists(tf):
    for r in list(csv.reader(open(tf)))[1:]:
        if r and r[0] != 'config_label':
            done.add((r[0], r[1], int(float(r[2]))))
configs = []
for e in escs:
    if f'xstar_{e}' in wanted:
        rows = list(csv.reader(open(os.path.join(res, f'pso_{e}_limpio.csv'))))
        best = min(rows[1:], key=lambda r: float(r[8]))
        configs.append((f'xstar_{e}', escs, *(float(v) for v in best[3:6])))
if 'base_x3_300' in wanted:   # caso clave: South, TP por defecto, x3 = 300
    configs.append(('base_x3_300', ['South'], 1.4, 8.0, 300.0))
maps = []
for lab, where, x1, x2, x3 in configs:
    for e in where:
        for s in range(1, 6):
            if (lab, e, s) not in done:
                maps.append(f'["config_label"::"{lab}", "scenario"::"{e}", "pt_speed_factor"::{x1}, "pt_wait_time"::{x2}, "lane_capacity_per_hour"::{x3}, "seed"::{s}.0]')
body = ',\n        '.join(maps)
gaml = f'''model UrbanMobility_Transferencia

// Punto 6.2 + 6.3: transferencia y robustez.
// Cada x* (el mejor que encontró PSO en un escenario) se evalúa en los TRES escenarios con 5 semillas.
// Si x*_A aplicado en B es peor que x*_B en B, no hay una configuración única: el óptimo depende del caso.
// Además: South con TP por defecto y x3 = 300 (caso clave de la presentación), 5 semillas.
// Generado automáticamente desde results/pso_<escenario>_limpio.csv.
import "UrbanMobility.gaml"

global {{ string config_label <- ""; }}

experiment Transferencia type: batch repeat: 1 keep_seed: true until: (cycle >= 500) {{
    // La semilla va explícita en cada combinación: en esta versión de GAMA, keep_seed: false
    // NO cambia la semilla entre repeticiones.
    method exploration with: [
        {body}
    ];

    reflex registrar {{
        ask simulations {{
            write "[" + config_label + " en " + active_scenario + " seed " + seed + "] T=" + avg_travel_time_w
                + " share=" + share_car + " f=" + f_obj;
            save [config_label, active_scenario, seed, pt_speed_factor, pt_wait_time, lane_capacity_per_hour,
                  avg_travel_time_w, g1_value, f_obj, share_car, congestion_index, realized_car_time, realized_pt_time]
                to: "../results/transferencia.csv" format: "csv" rewrite: false header: true;
        }}
    }}
}}
'''
model_name = 'UrbanMobility_' + os.path.splitext(outname)[0]
gaml = gaml.replace('model UrbanMobility_Transferencia', 'model ' + model_name)
open(os.path.join(mdir, outname), 'w').write(gaml)
print('configs:', [(c[0], c[2:]) for c in configs], 'ya hechas:', len(done), 'combinaciones nuevas:', len(maps))
