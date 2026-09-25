model Firstmodel

/* Insert your model definition here */
global {
	geometry shape <- square(500);
	
	init {
		step <- 3 #minute;
		create person number:1000;
		//ask one_of(person) {
		ask 10 among person {
			estado <- "Infectado";
		}
	}

	reflex reiniciar_brote {
		if empty(person where (each.estado = "Infectado")) {
			list<person> candidatos <- person where (each.estado = "Suceptible");
			if not empty(candidatos) {
				int n <- min(10, length(candidatos));
				ask n among candidatos {
					estado		<- "Infectado";
					lastChange	<- current_date;
				}
			}
		}
	}
}



species person skills: [moving] {
	int		edad;
	date	lastChange;
	float	days_infected	<- 0.0;
	float	days_immune		<- 0.0;
	float	days_suceptible	<- 0.0;
	string	estado;										// Suceptible, Infectado, Recuperado
	list <person> contactos -> { person at_distance 10};

	init {
		estado		<- "Suceptible";
		lastChange	<- current_date;
	}

	reflex contagiar {
		if estado = "Infectado" {
			ask contactos {
				if self.estado = "Suceptible" {
					self.estado		<- "Infectado";
					self.lastChange	<- current_date;
				}
			}
			days_infected <- (current_date - lastChange);
			days_infected <- days_infected / 86400;
			if days_infected > 3 {
				estado		<- "Recuperado";
				lastChange	<- current_date;
			}
		}
		
		if estado = "Recuperado" {
			days_immune <- (current_date - lastChange);
			days_immune <- days_immune / 86400;
			if days_immune > 1 {
				estado		<- "Suceptible";
				lastChange	<- current_date;
			}
		}
	}

	reflex moverse {
		do wander;
	}
	aspect	default {
		rgb myColor;
		if estado = "Suceptible" {
			myColor <- rgb(0, 255, 0);
		}
		else if estado = "Infectado" {
			myColor <- rgb(255, 0, 0);
		}
		else {
			myColor <- rgb(0, 0, 255);
		}
		draw circle(5) color:myColor;
	}
}



/* Experimento */
experiment prueba type:gui {
	output {
		display principal type:opengl {
			species person aspect:default;
		}
	}	
}
