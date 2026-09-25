model traffic

global{
	
	float	avg_speed;
	float	slow_cars;
	
	string	casestudy;
	string	file_path <- "../includes/"+casestudy+"/roads.shp";
	file	roads_file <- file(file_path);
	geometry shape <- envelope(roads_file);
	graph	roads_network;
	
	init {
		//step <- 0.01 #seconds;
		
		create road from:	roads_file;
		create car	number:	50;
		roads_network <- as_edge_graph(road);
		
		create intersection from: roads_network.vertices {
			if ( flip(0.3) ) {
				is_traffic_light	<- true;
				is_green			<- flip(0.5);
				counter				<- rnd(0, 20);
			}
		}
	}
	
	reflex updateValues{
		avg_speed <- mean(car collect each.current_speed);
		slow_cars <- car count (each.current_speed <= 2.5 #km/#h);
	}
}

species intersection {
	bool	is_traffic_light;
	bool	is_green;
	int		green_time;
	int		red_time;
	int		counter;
	
	init {
		green_time	<- 30;
		red_time	<- 30;
		counter		<- 0;
	}
	
	reflex main_behaviour when: is_traffic_light {
		counter <- counter + 1;
		if ( is_green and counter > green_time ) {
			is_green	<- false;
			counter		<- 0;
		}
		else if ( !is_green and counter > red_time ) {
			is_green	<- true;
			counter		<- 0;
		}
	}
	
	aspect default {
		if is_traffic_light {
			draw circle(8) wireframe:true border:is_green?#green:#red width:2.0;
		}
	}
}

species car skills:[moving]{
	point target_point;
	float current_speed;
	float desaceleracion;
	float aceleracion;
	float percepcion;
	init{
		current_speed	<- 10.0;
		aceleracion		<- 0.25;
		desaceleracion	<- 0.5;
		percepcion		<- 15;
		do compute_target;
	}
	reflex move_through_network{
		if(target_point = nil or (location distance_to target_point)<5){
			do compute_target;
		}
		
		list<intersection>	red_traffic_lights_ahead <- intersection at_distance(percepcion)
		select(
			each.is_traffic_light
			and
			!each.is_green
			and
			abs(self.heading - (self.location direction_to each.location))<35.0
		);
		
		int normalized_heading <- heading mod(360);
		list<car>			cars_ahead <- car at_distance(percepcion)
		select(
			each!=self
			and
			abs(self.heading - (self.location direction_to each.location))<35.0
			and
			abs(normalized_heading - each.heading) < 25
		);
		
		if( !empty(cars_ahead) or !empty(red_traffic_lights_ahead) ) {
			current_speed <- max(current_speed - (current_speed*desaceleracion),
				2.0 #km/#h
			);
		}
		else{
			current_speed <- min(current_speed + (current_speed*aceleracion),
				50.0 #km/#h
			);
		}
		do goto target:target_point on:roads_network speed:current_speed;
	}
	
	action compute_target{
		target_point <- any_location_in(one_of(road));
	}
	
	aspect default{
		draw triangle(10) rotate:heading+90 color:current_speed > 5.0 ? #blue: #red;
	}
	
}

species road{
	aspect default{
		draw shape color:#gray;
	}
}

experiment traffic type:gui{
	parameter "Caso de estudio" var:casestudy 
	<- "lomas" among:["lomas","gdl"];
	output{
		layout #split;
		display screen1{
			species road			aspect: default;
			species intersection	aspect: default;
			species car				aspect: default;
		}
		display charts{
			chart "Avg speed" type:series {
				data "Avg speed" value:avg_speed;
			} 
		}
	}
}

