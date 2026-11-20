model UrbanMobility_PSO_Comun

// Experimento PSO común a todos los escenarios (punto 6.1).
// No se ejecuta directamente (virtual): lo heredan pso_lomas.gaml, pso_south.gaml y pso_gdl.gaml,
// que solo cambian el escenario. Así el algoritmo, sus parámetros y los rangos son idénticos en los tres casos.
import "UrbanMobility.gaml"

experiment PSO_base type: batch virtual: true repeat: 1 keep_seed: true until: (cycle >= 500) {

    float t_inicio <- gama.machine_time;
    int   n_evaluaciones <- 0;
    float mejor_f <- #infinity;

    // Variables de decisión: mismas que en la práctica de optimización
    parameter "x1: pt_speed_factor"        var: pt_speed_factor        min: 1.0	max: 5.0	step: 0.2;
    parameter "x2: pt_wait_time (min)"     var: pt_wait_time           min: 0.0	max: 60.0	step: 2.0;
    parameter "x3: lane_capacity_per_hour" var: lane_capacity_per_hour min: 100.0	max: 1050.0	step: 50.0;

    method pso
        num_particles: 8         // M (8 = núcleos de la máquina: una iteración cuesta lo mismo que con 6)
        iter_max: 5              // N
        weight_inertia: 0.7
        weight_cognitive: 1.5
        weight_social: 1.5
        minimize: f_obj;

    reflex registrar {
        ask simulations {
            myself.n_evaluaciones <- myself.n_evaluaciones + 1;
            myself.mejor_f <- min(myself.mejor_f, f_obj);
            write "[" + active_scenario + "] eval " + myself.n_evaluaciones
                + " | x1=" + pt_speed_factor + " | x2=" + pt_wait_time + " | x3=" + lane_capacity_per_hour
                + " | T=" + avg_travel_time_w + " | g1=" + g1_value + " | f=" + f_obj
                + " | mejor=" + myself.mejor_f
                + " | t(s)=" + ((gama.machine_time - myself.t_inicio) / 1000.0);

            save [myself.n_evaluaciones, active_scenario, pt_speed_factor, pt_wait_time, lane_capacity_per_hour,
                  avg_travel_time_w, g1_value, f_obj, share_car, congestion_index,
                  realized_car_time, realized_pt_time, myself.mejor_f,
                  (gama.machine_time - myself.t_inicio) / 1000.0]
                to: "../results/pso_" + active_scenario + ".csv" format: "csv" rewrite: false header: true;
        }
    }
}
