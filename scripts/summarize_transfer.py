# Uso: python3 -I summarize_transfer.py <results_dir>
# Lee results/transferencia.csv, escribe results/transferencia_resumen.csv e imprime las tablas.
import csv, os, sys, statistics as st
res = sys.argv[1]
rows = list(csv.reader(open(os.path.join(res, 'transferencia.csv'))))
h = rows[0]; data = [r for r in rows[1:] if r and r[0] != h[0]]
# columnas: config, escenario, seed, x1, x2, x3, T, g1, f, share, cong, car_real, pt_real
groups = {}
for r in data:
    groups.setdefault((r[0], r[1]), []).append(r)
out = []
for (cfg, esc), g in sorted(groups.items()):
    T = [float(r[6]) for r in g]; S = [float(r[9]) for r in g]; F = [float(r[8]) for r in g]
    sd = lambda v: st.stdev(v) if len(v) > 1 else 0.0
    out.append([cfg, esc, len(g), g[0][3], g[0][4], g[0][5], g[0][7],
                st.mean(T), sd(T), st.mean(S), sd(S), st.mean(F), sd(F)])
with open(os.path.join(res, 'transferencia_resumen.csv'), 'w', newline='') as f:
    w = csv.writer(f)
    w.writerow(['config', 'escenario', 'n_semillas', 'x1', 'x2', 'x3', 'g1', 'T_media', 'T_sd', 'share_car_media', 'share_car_sd', 'f_media', 'f_sd'])
    w.writerows(out)
print('config | escenario | n | T media ± sd | share_car media ± sd | f media')
for o in out:
    print(f'{o[0]} | {o[1]} | {o[2]} | {o[7]:.2f} ± {o[8]:.2f} | {o[9]:.3f} ± {o[10]:.3f} | {o[11]:.2f}')
escs = ['Lomas', 'South', 'GDL_Oeste']
m = {(o[0], o[1]): o[11] for o in out}
print('\nMatriz de transferencia: f media (fila = x* de, columna = evaluado en); pérdida vs. el x* propio')
for a in escs:
    cells = []
    for b in escs:
        v, own = m.get((f'xstar_{a}', b)), m.get((f'xstar_{b}', b))
        cells.append('-' if v is None else f'{v:.2f}' + ('' if a == b or own is None else f' ({100*(v-own)/own:+.0f}%)'))
    print(f'x*_{a}: ' + ' | '.join(cells))
