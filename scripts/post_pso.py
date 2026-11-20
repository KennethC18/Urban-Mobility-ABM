# Uso: python3 -I post_pso.py <results_dir> <Escenario> <num_particles>
# Escribe <results>/pso_<Escenario>_limpio.csv (con columna 'iteracion') e imprime el resumen.
import csv, sys, math, os
res, esc, M = sys.argv[1], sys.argv[2], int(sys.argv[3])
rows = list(csv.reader(open(os.path.join(res, f'pso_{esc}.csv'))))
h = rows[0]; data = [r for r in rows[1:] if r and r[0] != h[0]]
cols = ['eval','iteracion','escenario','x1_pt_speed_factor','x2_pt_wait_time','x3_lane_capacity',
        'T_ventana_min','g1','f_obj','share_car','congestion_index','car_real_min','pt_real_min','mejor_f_acum','t_acum_s']
out = []
for r in data:
    e = int(float(r[0]))
    out.append([e, math.ceil(e / M) - 1] + r[1:])   # 0 = enjambre inicial
with open(os.path.join(res, f'pso_{esc}_limpio.csv'), 'w', newline='') as f:
    w = csv.writer(f); w.writerow(cols); w.writerows(out)
best = min(out, key=lambda r: float(r[8]))
fl = lambda i, d=3: round(float(best[i]), d)
print(f'== PSO {esc}: {len(out)} evaluaciones, enjambre inicial + {max(r[1] for r in out)} iteraciones, tiempo total {float(out[-1][14])/60:.1f} min')
print(f'   x* = ({fl(3,2)}, {fl(4,2)}, {fl(5,1)})  f = {fl(8)}  T = {fl(6)}  g1 = {fl(7,2)}  share_car = {fl(9)}  cong = {fl(10)}  (eval {best[0]}, iter {best[1]})')
print(f'   penalizadas (g1>0): {sum(float(r[7])>0 for r in out)}/{len(out)}')
for it in sorted(set(r[1] for r in out)):
    sub = [float(r[8]) for r in out if r[1] == it]
    print(f'   iter {it}: mejor f de la iteración = {min(sub):.3f}, media = {sum(sub)/len(sub):.3f}')
print('XSTAR', esc, best[3], best[4], best[5])
