
model traffic


global {
	string	file_path	<- "../includes/lomas/roads.shp";
	file	roads_file	<- file(file_path);
	
	geometry	shape			<- envelope(roads_file);
	graph		roads_network;
	
	init {
		step <- 1 #seconds;
		
		create road from: roads_file;
		roads_network	<- as_edge_graph(road);
		
		create car number:500;
	}
}



species car skills:[moving]{
	point	target_point;
	float	current_speed;
	float	aceleracion;
	float	desaceleracion;
	float	percepcion;
	
	init {
		current_speed	<- 10.0;
		aceleracion		<- 0.1;
		desaceleracion	<- 0.5;
		percepcion		<- 15.0;
		
		do compute_target;
	}

	reflex move_through_network {
		if ( target_point = nil or (location distance_to target_point)<5 ) {
			do compute_target;
		}
		
		list<car> cars_ahead <- car at_distance(percepcion) select(each!=self and
			abs(self.heading - (self.location direction_to each.location)) < 35);
		
		if (!empty(cars_ahead)) {
			current_speed <- max(current_speed - (current_speed * desaceleracion), 2.0 #km/#h);
		}
		else {
			current_speed <- min(current_speed + (current_speed * aceleracion), 50.0 #km/#h);
		}
		
		do goto target:target_point on: roads_network speed:current_speed;
	}

	action compute_target {
		target_point <- any_location_in(one_of(road));
	}
	
	aspect default {
		draw circle(15) color:#black;
	}
}

species road {
	aspect default{
		draw shape color:#gray;
	}
}



experiment traffic type: gui {
	output {
		display screen_1 {
			species road	aspect:default;
			species	car		aspect:default;
		}
	}
}

/*
model traffic

global {
	string	file_path	<- "../includes/gdl_oeste/roads.shp";
	file	roads_file	<- file(file_path);

	geometry	shape			<- envelope(roads_file);
	graph		roads_network;

	float avg_speed <- 0.0;
	int   stopped_cars <- 0;

	init {
		step <- 2 #seconds;

		create road from: roads_file;
		roads_network	<- as_edge_graph(road);

		// 70% conductores normales, 15% autobuses, 15% agresivos
		create car number:350;
		create bus number:75;
		create aggressive_driver number:75;
	}

	reflex update_metrics {
		avg_speed <- mean(car collect each.current_speed);
		stopped_cars <- car count (each.current_speed < 3 #km/#h);
	}
}


species car skills:[moving]{
	point	target_point;
	float	current_speed;
	float	aceleracion;
	float	desaceleracion;
	float	percepcion;
	float	velocidad_max;
	rgb		color <- #black;

	init {
		current_speed	<- 80.0;
		aceleracion		<- 0.1;
		desaceleracion	<- 0.5;
		percepcion		<- 15.0;
		velocidad_max	<- 50.0 #km/#h;

		do compute_target;
	}

	reflex move_through_network {
		if ( target_point = nil or (location distance_to target_point)<5 ) {
			do compute_target;
		}

		list<car> cars_ahead <- car at_distance(percepcion) select(each!=self and
			abs(self.heading - (self.location direction_to each.location)) < 35);

		if (!empty(cars_ahead)) {
			current_speed <- max(current_speed - (current_speed * desaceleracion), 2.0 #km/#h);
		}
		else {
			current_speed <- min(current_speed + (current_speed * aceleracion), velocidad_max);
		}

		do goto target:target_point on: roads_network speed:current_speed;
	}

	action compute_target {
		target_point <- any_location_in(one_of(road));
	}

	aspect default {
		draw circle(15) color:color;
	}
}

// Autobús: más lento y más grande, reacciona más lento
species bus parent: car {
	init {
		current_speed	<- 8.0;
		aceleracion		<- 0.05;
		desaceleracion	<- 0.6;
		percepcion		<- 20.0;
		velocidad_max	<- 20.0 #km/#h;
		color			<- #orange;
	}

	aspect default {
		draw square(25) color:color;
	}
}

// Conductor agresivo: menor distancia de seguridad, frena poco, acelera mucho
species aggressive_driver parent: car {
	init {
		current_speed	<- 15.0;
		aceleracion		<- 0.25;
		desaceleracion	<- 0.15;
		percepcion		<- 6.0;
		velocidad_max	<- 70.0 #km/#h;
		color			<- #red;
	}
}

species road {
	aspect default{
		draw shape color:#gray;
	}
}


experiment traffic type: gui {
	output {
		display screen_1 {
			species road	aspect:default;
			species	car		aspect:default;
			species bus		aspect:default;
			species aggressive_driver aspect:default;
		}

		display metrics refresh: every(1#cycle) {
			chart "Velocidad promedio (km/h)" type: series {
				data "Velocidad promedio" value: avg_speed color: #blue;
			}
		}

		display congestion refresh: every(1#cycle) {
			chart "Autos detenidos" type: series {
				data "Detenidos" value: stopped_cars color: #red;
			}
		}
	}
}
*/
