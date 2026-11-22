model UrbanMobility_transferencia_LS

// Punto 6.2 + 6.3: transferencia y robustez.
// Cada x* (el mejor que encontró PSO en un escenario) se evalúa en los TRES escenarios con 5 semillas.
// Si x*_A aplicado en B es peor que x*_B en B, no hay una configuración única: el óptimo depende del caso.
// Además: South con TP por defecto y x3 = 300 (caso clave de la presentación), 5 semillas.
// Generado automáticamente desde results/pso_<escenario>_limpio.csv.
import "UrbanMobility.gaml"

global { string config_label <- ""; }

experiment Transferencia type: batch repeat: 1 keep_seed: true until: (cycle >= 500) {
    // La semilla va explícita en cada combinación: en esta versión de GAMA, keep_seed: false
    // NO cambia la semilla entre repeticiones.
    method exploration with: [
        ["config_label"::"xstar_Lomas", "scenario"::"Lomas", "pt_speed_factor"::5.0, "pt_wait_time"::3.247024042862586, "lane_capacity_per_hour"::958.0013317805602, "seed"::1.0],
        ["config_label"::"xstar_Lomas", "scenario"::"Lomas", "pt_speed_factor"::5.0, "pt_wait_time"::3.247024042862586, "lane_capacity_per_hour"::958.0013317805602, "seed"::2.0],
        ["config_label"::"xstar_Lomas", "scenario"::"Lomas", "pt_speed_factor"::5.0, "pt_wait_time"::3.247024042862586, "lane_capacity_per_hour"::958.0013317805602, "seed"::3.0],
        ["config_label"::"xstar_Lomas", "scenario"::"Lomas", "pt_speed_factor"::5.0, "pt_wait_time"::3.247024042862586, "lane_capacity_per_hour"::958.0013317805602, "seed"::4.0],
        ["config_label"::"xstar_Lomas", "scenario"::"Lomas", "pt_speed_factor"::5.0, "pt_wait_time"::3.247024042862586, "lane_capacity_per_hour"::958.0013317805602, "seed"::5.0],
        ["config_label"::"xstar_Lomas", "scenario"::"South", "pt_speed_factor"::5.0, "pt_wait_time"::3.247024042862586, "lane_capacity_per_hour"::958.0013317805602, "seed"::1.0],
        ["config_label"::"xstar_Lomas", "scenario"::"South", "pt_speed_factor"::5.0, "pt_wait_time"::3.247024042862586, "lane_capacity_per_hour"::958.0013317805602, "seed"::2.0],
        ["config_label"::"xstar_Lomas", "scenario"::"South", "pt_speed_factor"::5.0, "pt_wait_time"::3.247024042862586, "lane_capacity_per_hour"::958.0013317805602, "seed"::3.0],
        ["config_label"::"xstar_Lomas", "scenario"::"South", "pt_speed_factor"::5.0, "pt_wait_time"::3.247024042862586, "lane_capacity_per_hour"::958.0013317805602, "seed"::4.0],
        ["config_label"::"xstar_Lomas", "scenario"::"South", "pt_speed_factor"::5.0, "pt_wait_time"::3.247024042862586, "lane_capacity_per_hour"::958.0013317805602, "seed"::5.0],
        ["config_label"::"xstar_South", "scenario"::"Lomas", "pt_speed_factor"::3.1606637346462767, "pt_wait_time"::5.81920737178806, "lane_capacity_per_hour"::1050.0, "seed"::1.0],
        ["config_label"::"xstar_South", "scenario"::"Lomas", "pt_speed_factor"::3.1606637346462767, "pt_wait_time"::5.81920737178806, "lane_capacity_per_hour"::1050.0, "seed"::2.0],
        ["config_label"::"xstar_South", "scenario"::"Lomas", "pt_speed_factor"::3.1606637346462767, "pt_wait_time"::5.81920737178806, "lane_capacity_per_hour"::1050.0, "seed"::3.0],
        ["config_label"::"xstar_South", "scenario"::"Lomas", "pt_speed_factor"::3.1606637346462767, "pt_wait_time"::5.81920737178806, "lane_capacity_per_hour"::1050.0, "seed"::4.0],
        ["config_label"::"xstar_South", "scenario"::"Lomas", "pt_speed_factor"::3.1606637346462767, "pt_wait_time"::5.81920737178806, "lane_capacity_per_hour"::1050.0, "seed"::5.0],
        ["config_label"::"xstar_South", "scenario"::"South", "pt_speed_factor"::3.1606637346462767, "pt_wait_time"::5.81920737178806, "lane_capacity_per_hour"::1050.0, "seed"::1.0],
        ["config_label"::"xstar_South", "scenario"::"South", "pt_speed_factor"::3.1606637346462767, "pt_wait_time"::5.81920737178806, "lane_capacity_per_hour"::1050.0, "seed"::2.0],
        ["config_label"::"xstar_South", "scenario"::"South", "pt_speed_factor"::3.1606637346462767, "pt_wait_time"::5.81920737178806, "lane_capacity_per_hour"::1050.0, "seed"::3.0],
        ["config_label"::"xstar_South", "scenario"::"South", "pt_speed_factor"::3.1606637346462767, "pt_wait_time"::5.81920737178806, "lane_capacity_per_hour"::1050.0, "seed"::4.0],
        ["config_label"::"xstar_South", "scenario"::"South", "pt_speed_factor"::3.1606637346462767, "pt_wait_time"::5.81920737178806, "lane_capacity_per_hour"::1050.0, "seed"::5.0],
        ["config_label"::"xstar_GDL_Oeste", "scenario"::"Lomas", "pt_speed_factor"::2.8664384362754833, "pt_wait_time"::8.27179216500698, "lane_capacity_per_hour"::1050.0, "seed"::1.0],
        ["config_label"::"xstar_GDL_Oeste", "scenario"::"Lomas", "pt_speed_factor"::2.8664384362754833, "pt_wait_time"::8.27179216500698, "lane_capacity_per_hour"::1050.0, "seed"::2.0],
        ["config_label"::"xstar_GDL_Oeste", "scenario"::"Lomas", "pt_speed_factor"::2.8664384362754833, "pt_wait_time"::8.27179216500698, "lane_capacity_per_hour"::1050.0, "seed"::3.0],
        ["config_label"::"xstar_GDL_Oeste", "scenario"::"Lomas", "pt_speed_factor"::2.8664384362754833, "pt_wait_time"::8.27179216500698, "lane_capacity_per_hour"::1050.0, "seed"::4.0],
        ["config_label"::"xstar_GDL_Oeste", "scenario"::"Lomas", "pt_speed_factor"::2.8664384362754833, "pt_wait_time"::8.27179216500698, "lane_capacity_per_hour"::1050.0, "seed"::5.0],
        ["config_label"::"xstar_GDL_Oeste", "scenario"::"South", "pt_speed_factor"::2.8664384362754833, "pt_wait_time"::8.27179216500698, "lane_capacity_per_hour"::1050.0, "seed"::1.0],
        ["config_label"::"xstar_GDL_Oeste", "scenario"::"South", "pt_speed_factor"::2.8664384362754833, "pt_wait_time"::8.27179216500698, "lane_capacity_per_hour"::1050.0, "seed"::2.0],
        ["config_label"::"xstar_GDL_Oeste", "scenario"::"South", "pt_speed_factor"::2.8664384362754833, "pt_wait_time"::8.27179216500698, "lane_capacity_per_hour"::1050.0, "seed"::3.0],
        ["config_label"::"xstar_GDL_Oeste", "scenario"::"South", "pt_speed_factor"::2.8664384362754833, "pt_wait_time"::8.27179216500698, "lane_capacity_per_hour"::1050.0, "seed"::4.0],
        ["config_label"::"xstar_GDL_Oeste", "scenario"::"South", "pt_speed_factor"::2.8664384362754833, "pt_wait_time"::8.27179216500698, "lane_capacity_per_hour"::1050.0, "seed"::5.0],
        ["config_label"::"base_x3_300", "scenario"::"South", "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::300.0, "seed"::1.0],
        ["config_label"::"base_x3_300", "scenario"::"South", "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::300.0, "seed"::2.0],
        ["config_label"::"base_x3_300", "scenario"::"South", "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::300.0, "seed"::3.0],
        ["config_label"::"base_x3_300", "scenario"::"South", "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::300.0, "seed"::4.0],
        ["config_label"::"base_x3_300", "scenario"::"South", "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::300.0, "seed"::5.0]
    ];

    reflex registrar {
        ask simulations {
            write "[" + config_label + " en " + active_scenario + " seed " + seed + "] T=" + avg_travel_time_w
                + " share=" + share_car + " f=" + f_obj;
            save [config_label, active_scenario, seed, pt_speed_factor, pt_wait_time, lane_capacity_per_hour,
                  avg_travel_time_w, g1_value, f_obj, share_car, congestion_index, realized_car_time, realized_pt_time]
                to: "../results/transferencia.csv" format: "csv" rewrite: false header: true;
        }
    }
}
