model UrbanMobility_Fundamentals

global {
    // =========================================================
    // 1. ESCENARIO (red vial + demanda)
    // =========================================================
    // Cada escenario es un caso distinto del mismo problema: otra red, otro tamaño, otra demanda.
    string	scenario		<- "South" among: ["Lomas", "South", "GDL_Oeste", "Personalizado"];	// parámetro (GUI / exploración)

    // scenario_override() existe para que un modelo que importa a este (p. ej. pso_lomas.gaml) pueda fijar
    // el escenario SIN declararlo como parámetro: PSO trata todo parámetro como una dimensión a explorar.
    // "" = usar el parámetro scenario. El modelo siempre lee active_scenario.
    string scenario_override { return ""; }
    string	active_scenario	<- (scenario_override() = "") ? scenario : scenario_override();
    string	file_path		<- "../includes/South/roads_clean.shp";	// solo se usa con "Personalizado"
    map<string, string> scenario_files <- [
        "Lomas"::"../includes/lomas/roads.shp",			//   589 tramos, sin atributos
        "South"::"../includes/South/roads_clean.shp",		// 6 429 tramos, sin atributos (Tlaquepaque)
        "GDL_Oeste"::"../includes/gdl_oeste/roads.shp"		// ~34 000 elementos OSM, con atributo "highway"
    ];

    // Demanda por escenario. Elegida con un barrido (500 ciclos, TP por defecto) para que cada red
    // tenga congestión sin trabarse. NO es demanda real observada:
    //   Lomas     600 x 1 -> congestion_index ~1.5, T ~9 min   (red chica, muy cargada)
    //   South     600 x 2 -> congestion_index ~1.6, T ~14 min  (caso base, Tlaquepaque)
    //   GDL_Oeste 600 x 2 -> congestion_index ~0.5, T ~20 min  (red grande con jerarquía vial, viajes largos)
    bool	use_scenario_defaults	<- true;
    map<string, int>   scenario_nb_commuters	<- ["Lomas"::600, "South"::600, "GDL_Oeste"::600];
    map<string, float> scenario_persons		<- ["Lomas"::1.0, "South"::2.0, "GDL_Oeste"::2.0];

    file	roads_file		<- file(active_scenario = "Personalizado" ? file_path : scenario_files[active_scenario]);
    geometry	shape			<- envelope(roads_file);
    graph	roads_network;
    list<road> net_roads	<- [];		// tramos que pertenecen a la componente conexa principal
    map<road, float> length_weights;	// longitud (m) de cada tramo: para que follow avance en metros

    // Tipos de vía OSM transitables y sus atributos (solo aplica a redes que traen "highway")
    list<string> drivable_types <- ["motorway", "motorway_link", "trunk", "trunk_link",
        "primary", "primary_link", "secondary", "secondary_link", "tertiary", "tertiary_link",
        "unclassified", "residential", "living_street", "service"];
    map<string, int> lanes_by_type <- ["motorway"::3, "trunk"::3, "primary"::2, "secondary"::2,
        "motorway_link"::1, "trunk_link"::1, "primary_link"::1, "secondary_link"::1];
    map<string, float> speed_by_type <- ["motorway"::80.0, "motorway_link"::50.0, "trunk"::60.0,
        "trunk_link"::40.0, "primary"::50.0, "primary_link"::35.0, "secondary"::40.0,
        "secondary_link"::30.0, "tertiary"::35.0, "tertiary_link"::30.0, "unclassified"::30.0,
        "residential"::30.0, "living_street"::15.0, "service"::20.0];

    // =========================================================
    // 2. POBLACIÓN
    // =========================================================
    int		nb_commuters			<- 300		min:50		max:5000;
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
    float free_speed_kmh			<- 30.0		min:5.0		max:120.0;	// velocidad de calles sin tipo
    int   default_lanes				<- 1		min:1		max:4;		// carriles de calles sin tipo
    float lane_capacity_per_hour	<- 700.0	min:100.0	max:3000.0;	// por carril
    float min_link_length_m			<- 50.0		min:1.0		max:500.0;	// evita v/c absurdos en tramos diminutos
    float bpr_alpha					<- 0.15		min:0.0		max:1.0;
    float bpr_beta					<- 4.0		min:1.0		max:10.0;
    int   refresh_weights_every		<- 10		min:1		max:100;
    float acceleration_rate			<- 0.1		min:0.0		max:1.0;
    float deceleration_rate			<- 0.3		min:0.0		max:1.0;
    float min_speed_kmh				<- 3.0		min:0.5		max:20.0;	// avance lento en embotellamiento

    // =========================================================
    // 5. CONDUCTA
    // =========================================================
    float beta_time					<- 0.15		min:0.0		max:2.0;
    float learning_rate				<- 0.025	min:0.0		max:1.0;
    float init_bias_mean			<- 1.0		min:0.0		max:5.0;
    float init_bias_sd				<- 0.3		min:0.0		max:2.0;

    // Visualización (no afecta la dinámica): radio de los agentes y grosor de las calles en el display
    float agent_draw_size			<- 6.0		min:1.0		max:200.0;
    float road_draw_width			<- 2.0		min:0.5		max:10.0;

    // =========================================================
    // MÉTRICAS
    // =========================================================
    float share_car					<- 0.0;
    float avg_car_time				<- 0.0;		// estimado al salir (lo que el agente cree que tardará en auto)
    float avg_real_pt_time			<- 0.0;		// estimado al salir
    float avg_believed_pt_time		<- 0.0;
    float avg_pt_bias				<- 0.0;
    float congestion_index			<- 0.0;
    float realized_car_time			<- 0.0;		// tiempo REALMENTE recorrido, último viaje en auto (min)
    float realized_pt_time			<- 0.0;		// tiempo REALMENTE recorrido, último viaje en TP (min)

    // =========================================================
    // OPTIMIZACIÓN: constantes de las restricciones (supuestos)
    // =========================================================
    float cost_w		<- 60.0;	// c_w: costo asociado a reducir la espera del TP (millones MXN/año)
    float cost_s		<- 40.0;	// c_s: costo asociado a acelerar el TP (millones MXN/año)
    float budget_B		<- 40.0;	// B: presupuesto máximo del TP (millones MXN/año)
    float penalty_M		<- 5.0;		// M: castigo (min) por cada unidad que se viola g1
    int   window_size	<- 100;		// ciclos finales sobre los que se promedia el objetivo

    // =========================================================
    // OPTIMIZACIÓN: métricas de la función objetivo
    // =========================================================
    float avg_travel_time	<- 0.0;		// T̄ REAL en el ciclo actual (min)
    float avg_travel_time_w	<- 0.0;		// T̄ promediado en la ventana final (min)
    float g1_value			<- 0.0;		// g1(x): <= 0 significa que se cumple el presupuesto
    float f_obj				<- 0.0;		// f(x) penalizada: lo que minimizan los algoritmos
    list<float> tt_hist		<- [];

    init {
        step <- 10 #s;

        if use_scenario_defaults and (active_scenario in scenario_nb_commuters.keys) {
            nb_commuters <- scenario_nb_commuters[active_scenario];
            persons_per_agent <- scenario_persons[active_scenario];
        }

        // --- construir la red a partir del mapa real ---
        if active_scenario = "GDL_Oeste" {
            // export de OSM: trae ríos, banquetas, etc.; nos quedamos solo con calles transitables
            create road from: roads_file with: [hw::string(read("highway"))];
            ask road where !(each.hw in drivable_types) { do die; }
        } else {
            create road from: roads_file;
        }
        ask road { do setup_attributes; }

        // solo la componente conexa principal: así toda casa/trabajo tiene camino
        roads_network <- main_connected_component(as_edge_graph(road));
        net_roads <- list<road>(roads_network.edges);
        ask net_roads { in_network <- true; }
        ask road where !each.in_network { do die; }

        // follow avanza en "unidades de peso" de la gráfica: si los pesos son minutos y no metros,
        // el agente se teletransporta. Por eso se le pasan explícitamente las longitudes.
        length_weights <- net_roads as_map (each::each.shape.perimeter);

        // rutas por TIEMPO (no por longitud), ya que cada tipo de calle tiene su velocidad
        roads_network <- roads_network with_weights (net_roads as_map (each::each.free_time));

        create commuter number: nb_commuters;

        write "Escenario " + active_scenario + ": " + length(net_roads) + " tramos, "
            + nb_commuters + " agentes x " + persons_per_agent + " personas";
    }

    // =========================================================
    // CADA CICLO (10 s)
    // =========================================================
    reflex update_traffic {
        // 1. contar cuántos autos hay AHORA MISMO en cada calle (la calle exacta por la que va)
        ask net_roads { volume <- 0.0; }
        ask commuter where (each.traveling and each.chosen_mode = "car" and each.wait_left <= 0) {
            road r <- road(current_edge);
            if r != nil { r.volume <- r.volume + persons_per_agent; }
        }
        ask net_roads {
            vc <- (volume * 60.0 / eff_time) / (lanes * lane_capacity_per_hour);
            current_time <- free_time * (1.0 + bpr_alpha * (vc ^ bpr_beta));
        }

        // 2. métricas
        do compute_metrics;

        // 3. cada cierto tiempo, "se corre la voz" de qué calles están lentas ahora,
        //    para que los próximos tramos (no los que ya van a la mitad) las eviten
        if cycle > 0 and cycle mod refresh_weights_every = 0 {
            roads_network <- roads_network with_weights (net_roads as_map (each::each.current_time));
        }
    }

    reflex update_objective {
        // T̄ = promedio, entre agentes, del tiempo REAL de su último viaje terminado.
        // Si el viaje en curso ya lleva más que eso (p. ej. un viaje atorado), se usa lo que lleva.
        list<commuter> active <- commuter where (each.chosen_mode != nil);
        avg_travel_time <- empty(active) ? 0.0
            : mean(active collect max(each.last_trip_min, each.traveling ? (time - each.trip_start) / 60.0 : 0.0));

        add avg_travel_time to: tt_hist;
        avg_travel_time_w <- mean(last(window_size, tt_hist));

        // g1(x) = c_w/(x2+1) + c_s/x1 - B   (x1 = pt_speed_factor, x2 = pt_wait_time)
        g1_value <- cost_w / (pt_wait_time + 1.0) + cost_s / pt_speed_factor - budget_B;

        // f(x) = T̄ + M * max(0, g1)
        f_obj <- avg_travel_time_w + penalty_M * max(0.0, g1_value);
    }

    action compute_metrics {
        list<commuter> owners <- commuter where each.has_car;
        list<commuter> drivers <- commuter where (each.chosen_mode = "car");

        share_car <- empty(owners) ? 0.0 : length(drivers) / length(owners);
        avg_car_time <- empty(drivers) ? 0.0 : mean(drivers collect each.last_car_time);
        avg_real_pt_time <- mean(commuter collect each.last_real_pt_time);
        avg_believed_pt_time <- mean(commuter collect each.last_believed_pt_time);
        avg_pt_bias <- empty(owners) ? 0.0 : mean(owners collect each.pt_bias);

        list<commuter> car_done <- commuter where (each.last_car_trip_min > 0);
        list<commuter> pt_done <- commuter where (each.last_pt_trip_min > 0);
        realized_car_time <- empty(car_done) ? 0.0 : mean(car_done collect each.last_car_trip_min);
        realized_pt_time <- empty(pt_done) ? 0.0 : mean(pt_done collect each.last_pt_trip_min);

        list<road> used <- net_roads where (each.volume > 0);
        congestion_index <- empty(used) ? 0.0
            : sum(used collect (each.vc * each.volume)) / sum(used collect each.volume);
    }
}

// =========================================================
// CALLES
// =========================================================
species road {
    string	hw			<- "";		// tipo de vía OSM (vacío si el shapefile no lo trae)
    int		lanes		<- 1;
    float	speed_kmh	<- 30.0;
    float	free_time	<- 0.0;		// min
    float	eff_time	<- 0.0;		// min; free_time con longitud mínima, para el cálculo de flujo
    float	volume		<- 0.0;		// autos (personas-auto) en el tramo en este instante
    float	current_time <- 0.0;	// min
    float	vc			<- 0.0;		// v/c del ciclo actual (se recalcula justo después de contar el volumen)
    bool	in_network	<- false;

    action setup_attributes {
        lanes <- (hw in lanes_by_type.keys) ? lanes_by_type[hw] : default_lanes;
        speed_kmh <- (hw in speed_by_type.keys) ? speed_by_type[hw] : free_speed_kmh;
        free_time <- (shape.perimeter / 1000.0) / speed_kmh * 60.0;
        eff_time <- (max(shape.perimeter, min_link_length_m) / 1000.0) / speed_kmh * 60.0;
        current_time <- free_time;
    }

    // v/c y tiempo BPR se calculan en el reflejo global (update_traffic) como atributos, NO con acciones:
    // en GAMA 2025.6 cada llamada a una acción crea un ThreadLocal; con ~7,000 calles por ciclo, la tabla de
    // ThreadLocals de un hilo puede crecer hasta volver la simulación decenas de veces más lenta.
    //   Flujo equivalente (veh/h): N autos en un tramo que se cruza en eff_time min generan N * 60 / eff_time veh/h.
    //   vc = flujo / (carriles * capacidad por carril);  current_time = free_time * (1 + alpha * vc^beta)

    aspect default {
        rgb c <- (vc < 0.6) ? #lightgray : ((vc < 1.0) ? #orange : #red);
        draw shape color: c width: road_draw_width;
    }
}



// =========================================================
// COMMUTER — camina de verdad por el mapa
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

    // lo que cree que tardaría el tramo actual, calculado solo al empezar cada tramo (no en cada ciclo)
    float	last_car_time <- 0.0;
    float	last_real_pt_time <- 0.0;
    float	last_believed_pt_time <- 0.0;

    // tiempos REALES (lo que de verdad tardó, incluida la espera del TP)
    float	trip_start <- 0.0;			// s (reloj de la simulación)
    float	last_trip_min <- 0.0;		// último viaje terminado, cualquier modo
    float	last_car_trip_min <- 0.0;
    float	last_pt_trip_min <- 0.0;

    // la velocidad que llevo AHORITA en km/h (cambia poco a poco, no de un salto)
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

    // Tiempo real que aporta este agente al objetivo (min): max(último viaje terminado, lo que lleva el actual).
    // Se calcula en línea en update_objective (sin acción, por la misma razón que vc en road).

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
    // Decidir modo y salir (una sola vez al empezar el tramo, no en cada ciclo)
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
        trip_start <- time;
        traveling <- true;
    }

    // ---------------------------------------------------
    // Un ciclo de viaje: esperar el camión si toca, o avanzar un poco
    // ---------------------------------------------------
    reflex do_trip {
        if !traveling {
            do choose_and_depart;
        } else if wait_left > 0 {
            wait_left <- wait_left - (step / 1 #minute);
        } else if my_path = nil {
            // sin camino (no debería pasar con la componente conexa principal)
            do arrive(false);
        } else {
            // velocidad (km/h) que "le toca" según qué tan llena está su calle;
            // nunca 0: en un embotellamiento se avanza lento, pero se avanza (si no, la red se traba para siempre)
            road r <- road(current_edge);
            float base_kmh <- (r = nil) ? free_speed_kmh
                : (r.speed_kmh / (1.0 + bpr_alpha * (r.vc ^ bpr_beta)));
            float target <- max(min_speed_kmh, (chosen_mode = "pt") ? (base_kmh / pt_speed_factor) : base_kmh);
            current_speed <- (current_speed < target)
                ? min(max(current_speed, min_speed_kmh) * (1.0 + acceleration_rate), target)
                : max(current_speed * (1.0 - deceleration_rate), target);
            // el skill moving espera m/s: se convierte de km/h
            do follow path: my_path speed: current_speed #km / #h move_weights: length_weights;
            if (location distance_to destination) < 15.0 {
                do arrive(true);
            }
        }
    }

    action arrive (bool completed) {
        if completed {
            float minutes <- (time - trip_start) / 60.0;
            last_trip_min <- minutes;
            if chosen_mode = "car" { last_car_trip_min <- minutes; } else { last_pt_trip_min <- minutes; }
        }
        if chosen_mode = "pt" { do experience_pt; }
        traveling <- false;
        destination <- (destination = work) ? home : work; // al llegar, se da la vuelta y regresa
    }

    action experience_pt {
        pt_bias <- pt_bias * (1.0 - learning_rate);
    }

    aspect default {
        draw circle(agent_draw_size) color: (chosen_mode = "car" ? #red : #blue);
    }
}



// =========================================================
// EXPERIMENTO
// =========================================================
experiment mobility_fundamentals type: gui {

    parameter "Escenario"									var: scenario				category: "Red";
    parameter "Archivo (solo escenario Personalizado)"		var: file_path				category: "Red";
    parameter "Usar demanda predeterminada del escenario"	var: use_scenario_defaults	category: "Red";

    parameter "Número de commuters" 						var: nb_commuters			category: "Población";
    parameter "Fracción con auto disponible"				var: car_ownership_rate		category: "Población";
    parameter "Personas por agente"							var: persons_per_agent		category: "Población";

    parameter "TP: factor de lentitud vs. auto"				var: pt_speed_factor		category: "Oferta de TP";
    parameter "TP: espera fija (min)"						var: pt_wait_time			category: "Oferta de TP";

    parameter "Velocidad libre de calles sin tipo (km/h)"	var: free_speed_kmh			category: "Tránsito";
    parameter "Carriles de calles sin tipo"					var: default_lanes			category: "Tránsito";
    parameter "Capacidad por carril (veh/h)" 				var: lane_capacity_per_hour	category: "Tránsito";
    parameter "Cada cuántos ciclos se recalculan las calles rápidas" var: refresh_weights_every category: "Tránsito";
    parameter "Qué tan rápido acelera"						var: acceleration_rate		category: "Tránsito";
    parameter "Qué tan rápido frena"						var: deceleration_rate		category: "Tránsito";
    parameter "Velocidad mínima en embotellamiento (km/h)"	var: min_speed_kmh			category: "Tránsito";

    parameter "Sensibilidad de elección (beta_time)"		var: beta_time				category: "Conducta";
    parameter "Tasa de aprendizaje"							var: learning_rate			category: "Conducta";
    parameter "Sesgo inicial promedio"						var: init_bias_mean			category: "Conducta";

    parameter "Tamaño de los agentes (m)"					var: agent_draw_size		category: "Visualización";
    parameter "Grosor de las calles"						var: road_draw_width		category: "Visualización";

    output {
        monitor "Escenario" value: active_scenario;
        monitor "T promedio real, ventana (min)" value: avg_travel_time_w;
        monitor "Índice de congestión" value: congestion_index;

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
            chart "Actual (realized) travel time by mode" type: series {
                data "Car" value: realized_car_time color: #red;
                data "Public Transport" value: realized_pt_time color: #blue;
                data "Average (objective)" value: avg_travel_time color: #black;
            }
        }

        display congestion type: 2d {
            chart "How crowded the streets are" type: series {
                data "Congestion index" value: congestion_index color: #black;
            }
        }
    }
}
