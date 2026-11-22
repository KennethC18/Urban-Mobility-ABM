# Uso: python3 -I summarize_sweeps.py <results_dir> {sesgo|x3}
import csv, os, sys, statistics as st
res, kind = sys.argv[1], sys.argv[2]
f = os.path.join(res, 'barrido_sesgo.csv' if kind == 'sesgo' else 'barrido_x3.csv')
rows = [r for r in csv.reader(open(f))]
h = rows[0]; data = [r for r in rows[1:] if r and r[0] != h[0]]
idx = {k: i for i, k in enumerate(h)}
g = {}
for r in data: g.setdefault(r[0], []).append(r)
ms = lambda v: f'{st.mean(v):.3f} ± {(st.stdev(v) if len(v) > 1 else 0):.3f}'
cols = ([('avg_pt_bias', 'sesgo medio final'), ('share_car', 'share_car'), ('avg_travel_time_w', 'T real'),
         ('realized_car_time', 'auto real'), ('realized_pt_time', 'TP real'), ('avg_car_time', 'auto estimado al salir'),
         ('avg_believed_pt_time', 'TP creído'), ('congestion_index', 'congestión')] if kind == 'sesgo' else
        [('avg_travel_time_w', 'T real'), ('share_car', 'share_car'), ('congestion_index', 'congestión'),
         ('realized_car_time', 'auto real'), ('avg_car_time', 'auto estimado'), ('realized_pt_time', 'TP real')])
out = []
for lab in sorted(g):
    rr = g[lab]
    line = [lab, len(rr)] + [ms([float(r[idx[c]]) for r in rr]) for c, _ in cols]
    out.append(line)
    print(f'== {lab} (n={len(rr)})'); [print(f'   {n}: {v}') for (_, n), v in zip(cols, line[2:])]
with open(f.replace('.csv', '_resumen.csv'), 'w', newline='') as fo:
    w = csv.writer(fo); w.writerow(['config', 'n'] + [n + ' (media ± sd)' for _, n in cols]); w.writerows(out)
