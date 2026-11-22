model UrbanMobility_barrido_x3_GDL

// Tabla T real vs. capacidad vial (x3 = 300 / 700 / 1050) con TP por defecto y semillas 1-5.
// GDL_Oeste. (GDL_Oeste va en un archivo aparte, una simulación por JVM.)
import "UrbanMobility.gaml"

global {
    string config_label <- "";
    int run_seed <- 0;
}

experiment BarridoX3 type: batch repeat: 1 keep_seed: true until: (cycle >= 500) {
    method exploration with: [
        ["config_label"::"GDL_Oeste_x3_300", "run_seed"::1, "scenario"::"GDL_Oeste", "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::300.0, "seed"::1.0],
        ["config_label"::"GDL_Oeste_x3_300", "run_seed"::2, "scenario"::"GDL_Oeste", "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::300.0, "seed"::2.0],
        ["config_label"::"GDL_Oeste_x3_300", "run_seed"::3, "scenario"::"GDL_Oeste", "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::300.0, "seed"::3.0],
        ["config_label"::"GDL_Oeste_x3_300", "run_seed"::4, "scenario"::"GDL_Oeste", "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::300.0, "seed"::4.0],
        ["config_label"::"GDL_Oeste_x3_300", "run_seed"::5, "scenario"::"GDL_Oeste", "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::300.0, "seed"::5.0],
        ["config_label"::"GDL_Oeste_x3_700", "run_seed"::1, "scenario"::"GDL_Oeste", "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::700.0, "seed"::1.0],
        ["config_label"::"GDL_Oeste_x3_700", "run_seed"::2, "scenario"::"GDL_Oeste", "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::700.0, "seed"::2.0],
        ["config_label"::"GDL_Oeste_x3_700", "run_seed"::3, "scenario"::"GDL_Oeste", "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::700.0, "seed"::3.0],
        ["config_label"::"GDL_Oeste_x3_700", "run_seed"::4, "scenario"::"GDL_Oeste", "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::700.0, "seed"::4.0],
        ["config_label"::"GDL_Oeste_x3_700", "run_seed"::5, "scenario"::"GDL_Oeste", "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::700.0, "seed"::5.0],
        ["config_label"::"GDL_Oeste_x3_1050", "run_seed"::1, "scenario"::"GDL_Oeste", "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::1050.0, "seed"::1.0],
        ["config_label"::"GDL_Oeste_x3_1050", "run_seed"::2, "scenario"::"GDL_Oeste", "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::1050.0, "seed"::2.0],
        ["config_label"::"GDL_Oeste_x3_1050", "run_seed"::3, "scenario"::"GDL_Oeste", "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::1050.0, "seed"::3.0],
        ["config_label"::"GDL_Oeste_x3_1050", "run_seed"::4, "scenario"::"GDL_Oeste", "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::1050.0, "seed"::4.0],
        ["config_label"::"GDL_Oeste_x3_1050", "run_seed"::5, "scenario"::"GDL_Oeste", "pt_speed_factor"::1.4, "pt_wait_time"::8.0, "lane_capacity_per_hour"::1050.0, "seed"::5.0]
    ];
    reflex registrar {
        ask simulations {
            save [config_label, run_seed, active_scenario, lane_capacity_per_hour, avg_travel_time_w, share_car,
                  congestion_index, realized_car_time, avg_car_time, realized_pt_time]
                to: "../results/barrido_x3.csv" format: "csv" rewrite: false header: true;
        }
    }
}
