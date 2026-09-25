model UrbanMobility_Fundamentals

global {
    // =========================================================
    // 1. Mapa (cargado desde un shapefile real, como en el modelo "traffic")
    // =========================================================
    string	file_path		<- "../includes/South/roads_clean.shp";
    file	roads_file		<- file(file_path);
    geometry	shape			<- envelope(roads_file);
    graph	roads_network;

    // =========================================================
    // 2. POBLACIÓN
    // =========================================================
    int		nb_commuters			<- 300		min:50		max:3000;
    float	car_ownership_rate		<- 0.7		min:0.0		max:1.0;
    float	persons_per_agent		<- 1.0		min:1.0		max:200.0;

    // =========================================================
    // 3. OFERTA DE TP
    // =========================================================
    float pt_speed_factor			<- 1.4		min:1.0		max: 5.0;
    float	pt_wait_time			<- 8.0		min:0.0		max: 60.0;

    // =========================================================
    // 4. TRÁNSITO Y CONGESTIÓN
    // =========================================================
    float free_speed_kmh			<- 30.0		min:5.0		max:120.0;
    float lane_capacity_per_hour	<- 700.0	min:100.0	max:3000.0;
    float bpr_alpha					<- 0.15		min:0.0		max:1.0;
    float bpr_beta					<- 4.0		min:1.0		max:10.0;
    int   refresh_weights_every		<- 10		min:1		max:100;
    float acceleration_rate			<- 0.1		min:0.0		max:1.0;
    float deceleration_rate			<- 0.3		min:0.0		max:1.0;

    // =========================================================
    // 5. CONDUCTA
    // =========================================================
    float beta_time					<- 0.15		min:0.0		max:2.0;
    float learning_rate				<- 0.025	min:0.0		max:1.0;
    float init_bias_mean			<- 1.0		min:0.0		max:5.0;
    float init_bias_sd				<- 0.3		min:0.0		max:2.0;

    // =========================================================
    // MÉTRICAS
    // =========================================================
    float share_car					<- 0.0;
    float avg_car_time				<- 0.0;
    float avg_real_pt_time			<- 0.0;
    float avg_believed_pt_time		<- 0.0;
    float avg_pt_bias				<- 0.0;
    float congestion_index			<- 0.0;

    init {
        step <- 10 #s;

        // --- construir la red a partir del mapa real ---
        create road from: roads_file;
        roads_network <- as_edge_graph(road);

        create commuter number: nb_commuters;
    }

    // =========================================================
    // CADA MINUTO
    // =========================================================
    reflex update_traffic {
        // 1. contar cuántos coches hay AHORA MISMO en cada calle
        ask road { volume <- 0.0; }
        ask commuter where (each.traveling and each.chosen_mode = "car" and each.wait_left <= 0) {
            road r <- road closest_to self;
            if r != nil { r.volume <- r.volume + persons_per_agent; }
        }
        ask road { do update_time; }

        // 2. métricas
        do compute_metrics;

        // 3. cada cierto tiempo, "se corre la voz" de qué calles están lentas ahora,
        //    para que los próximos tramos (no los que ya van a la mitad) las eviten
        if cycle > 0 and cycle mod refresh_weights_every = 0 {
            map<road, float> w <- road as_map (each::each.current_time);
            roads_network <- roads_network with_weights w;
        }
    }

    action compute_metrics {
        list<commuter> owners <- commuter where each.has_car;
        list<commuter> drivers <- commuter where (each.chosen_mode = "car");

        share_car <- empty(owners) ? 0.0 : length(drivers) / length(owners);
        avg_car_time <- empty(drivers) ? 0.0 : mean(drivers collect each.last_car_time);
        avg_real_pt_time <- mean(commuter collect each.last_real_pt_time);
        avg_believed_pt_time <- mean(commuter collect each.last_believed_pt_time);
        avg_pt_bias <- empty(owners) ? 0.0 : mean(owners collect each.pt_bias);

        list<road> used <- road where (each.volume > 0);
        congestion_index <- empty(used) ? 0.0
            : sum(used collect (each.vc_ratio() * each.volume)) / sum(used collect each.volume);
    }
}

// =========================================================
// Mapa (el shapefile ya trae su propia geometría)
// =========================================================
species road {
    float free_time		<- 0.0;
    float volume		<- 0.0;
    float current_time	<- 0.0;

    init {
        free_time <- (shape.perimeter / 1000.0) / free_speed_kmh * 60.0;
        current_time <- free_time;
    }

    float capacity { return lane_capacity_per_hour; }
    float vc_ratio { return volume / capacity(); }

    action update_time {
        current_time <- free_time * (1.0 + bpr_alpha * (vc_ratio() ^ bpr_beta));
    }

    aspect default {
        rgb c <- (vc_ratio() < 0.6) ? #lightgray : ((vc_ratio() < 1.0) ? #orange : #red);
        draw shape color: c width: 2;
    }
}



// =========================================================
// COMMUTER — ahora sí camina de verdad por el mapa
// =========================================================
species commuter skills: [moving] {

    bool	has_car <- flip(car_ownership_rate);
    point	home;
    point	work;
    point	destination;      // a dónde va ahorita (home o work)
    bool	traveling <- false;
    float	wait_left <- 0.0; // minutos que le faltan de espera antes de subirse al TP

    float	pt_bias <- has_car ? max(0.0, gauss(init_bias_mean, init_bias_sd)) : 0.0;
    string	chosen_mode <- nil;

    // el tramo que le toca caminar (se guarda una sola vez al salir, para no reasignarlo a medio camino)
    path	my_path <- nil;

    // lo que cree que tardaría el tramo actual, calculado solo al empezar cada tramo (no en cada minuto)
    float	last_car_time <- 0.0;
    float	last_real_pt_time <- 0.0;
    float	last_believed_pt_time <- 0.0;

    // la velocidad que llevo AHORITA (cambia poco a poco, no de un salto)
    float	current_speed <- 10.0;

    init {
        home <- point(one_of(roads_network.vertices));
        work <- point(one_of(roads_network.vertices));
        loop while: work = home {
            work <- point(one_of(roads_network.vertices));
        }
        destination <- work;
        location <- home;
    }

    // ---------------------------------------------------
    // Estimar cuánto tardaría el tramo actual con las calles como están ahora
    // ---------------------------------------------------
    action update_time_estimates {
        path p <- path_between(roads_network, location, destination);
        my_path <- p;
        last_car_time <- (p = nil) ? 0.0 : sum(list<road>(p.edges) collect each.current_time);
        last_real_pt_time <- last_car_time * pt_speed_factor + pt_wait_time;
        last_believed_pt_time <- last_real_pt_time * (1.0 + pt_bias);
    }

    // ---------------------------------------------------
    // Decidir modo y salir (una sola vez al empezar el tramo, no en cada minuto)
    // ---------------------------------------------------
    action choose_and_depart {
        do update_time_estimates;
        if !has_car {
            chosen_mode <- "pt";
        } else {
            float diff	<- last_believed_pt_time - last_car_time; // > 0 favorece el auto
            float p_car <- 1.0 / (1.0 + exp(-beta_time * diff));
            chosen_mode <- flip(p_car) ? "car" : "pt";
        }
        wait_left <- (chosen_mode = "pt") ? pt_wait_time : 0.0;
        traveling <- true;
    }

    // ---------------------------------------------------
    // La velocidad que "le toca" ahora mismo, según qué tan llena está la calle donde estoy parado
    // ---------------------------------------------------
    float target_speed_kmh {
        road r <- road closest_to self;
        float base_kmh <- (r = nil) ? free_speed_kmh : (free_speed_kmh / (1.0 + bpr_alpha * (r.vc_ratio() ^ bpr_beta)));
        return (chosen_mode = "pt") ? (base_kmh / pt_speed_factor) : base_kmh;
    }

    // ---------------------------------------------------
    // Un minuto de viaje: esperar el camión si toca, o avanzar un poco
    // ---------------------------------------------------
    reflex do_trip {
        if !traveling {
            do choose_and_depart;
        } else if wait_left > 0 {
            wait_left <- wait_left - (step / 1 #minute);
        } else if my_path = nil {
            // no se encontró camino (red desconectada): no se mueve, para no quedar en el limbo
            do arrive;
        } else {
            float target <- target_speed_kmh();
            current_speed <- (current_speed < target)
                ? min(current_speed * (1.0 + acceleration_rate), target)
                : max(current_speed * (1.0 - deceleration_rate), target);
            do follow path: my_path speed: current_speed;
            if (location distance_to destination) < 15.0 {
                do arrive;
            }
        }
    }

    action arrive {
        if chosen_mode = "pt" { do experience_pt; }
        traveling <- false;
        destination <- (destination = work) ? home : work; // al llegar, se da la vuelta y regresa
    }

    action experience_pt {
        pt_bias <- pt_bias * (1.0 - learning_rate);
    }

    aspect default {
        draw circle(6) color: (chosen_mode = "car" ? #red : #blue);
    }
}



// =========================================================
// EXPERIMENTO
// =========================================================
experiment mobility_fundamentals type: gui {

    parameter "Archivo de la red vial (shapefile)"			var: file_path				category: "Red";

    parameter "Número de commuters" 						var: nb_commuters			category: "Población";
    parameter "Fracción con auto disponible"				var: car_ownership_rate		category: "Población";
    parameter "Personas por agente"							var: persons_per_agent		category: "Población";

    parameter "TP: factor de lentitud vs. auto"				var: pt_speed_factor		category: "Oferta de TP";
    parameter "TP: espera fija (min)"						var: pt_wait_time			category: "Oferta de TP";

    parameter "Velocidad libre (km/h)"						var: free_speed_kmh			category: "Tránsito";
    parameter "Capacidad de cada calle (veh/h)" 			var: lane_capacity_per_hour	category: "Tránsito";
    parameter "Cada cuántos minutos se recalculan las calles rápidas" var: refresh_weights_every category: "Tránsito";
    parameter "Qué tan rápido acelera"						var: acceleration_rate		category: "Tránsito";
    parameter "Qué tan rápido frena"						var: deceleration_rate		category: "Tránsito";

    parameter "Sensibilidad de elección (beta_time)"		var: beta_time				category: "Conducta";
    parameter "Tasa de aprendizaje"							var: learning_rate			category: "Conducta";
    parameter "Sesgo inicial promedio"						var: init_bias_mean			category: "Conducta";

    output {
        display red_view type: 2d {
            species road		aspect: default;
            species commuter	aspect: default;
        }

        display reparto_modal type: 2d {
            chart "How many people still use their cars?" type: series {
                data "% who use a car (among those who own one)" value: share_car color: #red;
            }
        }

        display el_sesgo type: 2d {
            chart "The bias: what they believe vs. how long the PT actually takes." type: series {
                data "Real-time PT (min)" value: avg_real_pt_time color: #blue;
                data "Time they think it takes (min)" value: avg_believed_pt_time color: #purple;
            }
        }

        display tiempos_reales type: 2d {
            chart "Actual travel time by mode" type: series {
                data "Car" value: avg_car_time color: #red;
                data "Public Transport" value: avg_real_pt_time color: #blue;
            }
        }

        display congestion type: 2d {
            chart "How crowded the streets are" type: series {
                data "Congestion index" value: congestion_index color: #black;
            }
        }
    }
}
