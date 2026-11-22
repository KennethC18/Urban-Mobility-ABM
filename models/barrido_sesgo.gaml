model UrbanMobility_BarridoSesgo

// Barrido del sesgo perceptivo inicial hacia el TP en South con capacidad baja (x3 = 300) y TP por defecto.
// Pregunta: ¿share_car sigue alto aun sin sesgo? Si sí, el mecanismo dominante es la subestimación del
// tiempo en auto (estimado al salir con la congestión del momento), no el sesgo hacia el TP.
// bias0_sd0 = sesgo exactamente 0 (con sd 0.3 y media 0, el recorte max(0, gauss) deja un sesgo medio ~0.12).
import "UrbanMobility.gaml"

global {
    string config_label <- "";
    int run_seed <- 0;      // la columna seed de GAMA no registra la semilla de cada corrida
}

experiment BarridoSesgo type: batch repeat: 1 keep_seed: true until: (cycle >= 500) {
    method exploration with: [
        ["config_label"::"bias0.0", "run_seed"::1, "scenario"::"South", "init_bias_mean"::0.0, "init_bias_sd"::0.3, "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::300.0, "seed"::1.0],
        ["config_label"::"bias0.0", "run_seed"::2, "scenario"::"South", "init_bias_mean"::0.0, "init_bias_sd"::0.3, "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::300.0, "seed"::2.0],
        ["config_label"::"bias0.0", "run_seed"::3, "scenario"::"South", "init_bias_mean"::0.0, "init_bias_sd"::0.3, "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::300.0, "seed"::3.0],
        ["config_label"::"bias0.0", "run_seed"::4, "scenario"::"South", "init_bias_mean"::0.0, "init_bias_sd"::0.3, "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::300.0, "seed"::4.0],
        ["config_label"::"bias0.0", "run_seed"::5, "scenario"::"South", "init_bias_mean"::0.0, "init_bias_sd"::0.3, "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::300.0, "seed"::5.0],
        ["config_label"::"bias0.5", "run_seed"::1, "scenario"::"South", "init_bias_mean"::0.5, "init_bias_sd"::0.3, "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::300.0, "seed"::1.0],
        ["config_label"::"bias0.5", "run_seed"::2, "scenario"::"South", "init_bias_mean"::0.5, "init_bias_sd"::0.3, "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::300.0, "seed"::2.0],
        ["config_label"::"bias0.5", "run_seed"::3, "scenario"::"South", "init_bias_mean"::0.5, "init_bias_sd"::0.3, "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::300.0, "seed"::3.0],
        ["config_label"::"bias0.5", "run_seed"::4, "scenario"::"South", "init_bias_mean"::0.5, "init_bias_sd"::0.3, "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::300.0, "seed"::4.0],
        ["config_label"::"bias0.5", "run_seed"::5, "scenario"::"South", "init_bias_mean"::0.5, "init_bias_sd"::0.3, "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::300.0, "seed"::5.0],
        ["config_label"::"bias1.0", "run_seed"::1, "scenario"::"South", "init_bias_mean"::1.0, "init_bias_sd"::0.3, "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::300.0, "seed"::1.0],
        ["config_label"::"bias1.0", "run_seed"::2, "scenario"::"South", "init_bias_mean"::1.0, "init_bias_sd"::0.3, "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::300.0, "seed"::2.0],
        ["config_label"::"bias1.0", "run_seed"::3, "scenario"::"South", "init_bias_mean"::1.0, "init_bias_sd"::0.3, "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::300.0, "seed"::3.0],
        ["config_label"::"bias1.0", "run_seed"::4, "scenario"::"South", "init_bias_mean"::1.0, "init_bias_sd"::0.3, "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::300.0, "seed"::4.0],
        ["config_label"::"bias1.0", "run_seed"::5, "scenario"::"South", "init_bias_mean"::1.0, "init_bias_sd"::0.3, "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::300.0, "seed"::5.0],
        ["config_label"::"bias0_sd0", "run_seed"::1, "scenario"::"South", "init_bias_mean"::0.0, "init_bias_sd"::0.0, "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::300.0, "seed"::1.0],
        ["config_label"::"bias0_sd0", "run_seed"::2, "scenario"::"South", "init_bias_mean"::0.0, "init_bias_sd"::0.0, "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::300.0, "seed"::2.0],
        ["config_label"::"bias0_sd0", "run_seed"::3, "scenario"::"South", "init_bias_mean"::0.0, "init_bias_sd"::0.0, "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::300.0, "seed"::3.0],
        ["config_label"::"bias0_sd0", "run_seed"::4, "scenario"::"South", "init_bias_mean"::0.0, "init_bias_sd"::0.0, "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::300.0, "seed"::4.0],
        ["config_label"::"bias0_sd0", "run_seed"::5, "scenario"::"South", "init_bias_mean"::0.0, "init_bias_sd"::0.0, "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::300.0, "seed"::5.0]
    ];
    reflex registrar {
        ask simulations {
            save [config_label, run_seed, init_bias_mean, init_bias_sd, avg_pt_bias, share_car, avg_travel_time_w,
                  realized_car_time, realized_pt_time, avg_car_time, avg_real_pt_time, avg_believed_pt_time,
                  congestion_index]
                to: "../results/barrido_sesgo.csv" format: "csv" rewrite: false header: true;
        }
    }
}
