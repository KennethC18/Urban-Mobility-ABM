model UrbanMobility_Optimizacion

// El modelo (red, agentes, congestión y la función objetivo f_obj) vive en UrbanMobility.gaml.
// Este archivo solo define los experimentos de optimización, así no hay dos copias del modelo.
import "UrbanMobility.gaml"

experiment OptimizacionMovilidad type: batch repeat: 1 keep_seed: true until: (cycle >= 500) {

    // Control de tiempo y número de ejecuciones (para el reporte)
    float t_inicio <- gama.machine_time;
    int   n_corridas <- 0;

    // Escenario: South (predeterminado). No se declara como parámetro porque el método lo exploraría.
    // Para optimizar otros escenarios usa pso_lomas.gaml / pso_south.gaml / pso_gdl.gaml.

    // 1. Variables de decisión x = (x1, x2, x3)
    parameter "x1: pt_speed_factor"        var: pt_speed_factor        min: 1.0	max: 5.0	step: 0.2;
    parameter "x2: pt_wait_time (min)"     var: pt_wait_time           min: 0.0	max: 60.0	step: 2.0;
    parameter "x3: lane_capacity_per_hour" var: lane_capacity_per_hour min: 100.0	max: 1050.0	step: 50.0;
    // (max de x3 = 1050 implementa la restricción g2: x3 <= 1.5 * 700)

    // 2. Método de búsqueda y función objetivo (minimizar T̄ penalizado)
    method hill_climbing
        iter_max: 10
        minimize: f_obj;

    // 3. Registro de cada combinación evaluada (consola + CSV)
    reflex registrar {
        ask simulations {
            write "Sim " + int(self)
                + " | x1=" + pt_speed_factor
                + " | x2=" + pt_wait_time
                + " | x3=" + lane_capacity_per_hour
                + " | T_ventana=" + avg_travel_time_w
                + " | g1=" + g1_value
                + " | f=" + f_obj
                + " | share_car=" + share_car;

            save [int(self), active_scenario, pt_speed_factor, pt_wait_time, lane_capacity_per_hour,
                  avg_travel_time_w, g1_value, f_obj, share_car, congestion_index]
                to: "../results/hill_climbing_log_v2.csv" format: "csv" rewrite: false header: true;
        }
        n_corridas <- n_corridas + 1;
        write "Combinaciones evaluadas: " + n_corridas
            + " | tiempo acumulado (s): " + ((gama.machine_time - t_inicio) / 1000.0);
    }
}

experiment OptimizacionPSO type: batch repeat: 1 keep_seed: true until: (cycle >= 500) {

    // Control de tiempo, número de ejecuciones y mejor valor (para el reporte y la gráfica)
    float t_inicio <- gama.machine_time;
    int   n_corridas <- 0;
    float f_actual <- 0.0;
    float mejor_f <- 0.0;

    // Escenario: South (predeterminado). No se declara como parámetro porque el método lo exploraría.
    // Para optimizar otros escenarios usa pso_lomas.gaml / pso_south.gaml / pso_gdl.gaml.

    // 1. Mismas variables de decisión y rangos que en Hill-Climbing y AG
    parameter "x1: pt_speed_factor"        var: pt_speed_factor        min: 1.0	max: 5.0	step: 0.2;
    parameter "x2: pt_wait_time (min)"     var: pt_wait_time           min: 0.0	max: 60.0	step: 2.0;
    parameter "x3: lane_capacity_per_hour" var: lane_capacity_per_hour min: 100.0	max: 1050.0	step: 50.0;

    // 2. Configuración de la metaheurística de enjambre (minimizar el mismo f_obj)
    method pso
        num_particles: 6         // tamaño del enjambre (M)
        iter_max: 4              // iteraciones (N)
        weight_inertia: 0.7      // inercia (w)
        weight_cognitive: 1.5    // coeficiente cognitivo (c1)
        weight_social: 1.5       // coeficiente social (c2)
        minimize: f_obj;

    // 3. Registro de cada partícula evaluada (consola + CSV)
    //    Iteración aproximada de una fila = parte entera de (ID / num_particles)
    reflex registrar {
        ask simulations {
            write "Sim " + int(self)
                + " | x1=" + pt_speed_factor
                + " | x2=" + pt_wait_time
                + " | x3=" + lane_capacity_per_hour
                + " | T_ventana=" + avg_travel_time_w
                + " | g1=" + g1_value
                + " | f=" + f_obj
                + " | share_car=" + share_car;

            save [int(self), active_scenario, pt_speed_factor, pt_wait_time, lane_capacity_per_hour,
                  avg_travel_time_w, g1_value, f_obj, share_car, congestion_index]
                to: "../results/pso_log_v2.csv" format: "csv" rewrite: false header: true;
        }

        f_actual <- min(simulations collect each.f_obj);
        mejor_f <- (n_corridas = 0) ? f_actual : min(mejor_f, f_actual);
        n_corridas <- n_corridas + 1;

        write "Partículas evaluadas: " + n_corridas
            + " | mejor f hasta ahora: " + mejor_f
            + " | tiempo acumulado (s): " + ((gama.machine_time - t_inicio) / 1000.0);
    }

    // 4. Gráfica permanente de convergencia
    permanent {
        display "Progreso_PSO" type: 2d {
            chart "Convergencia del enjambre (PSO)" type: series {
                data "Mejor f global (min)" value: mejor_f color: #blue marker: true;
                data "f de la partícula actual (min)" value: f_actual color: #gray;
            }
        }
    }
}