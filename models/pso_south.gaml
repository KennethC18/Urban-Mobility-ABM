model UrbanMobility_PSO_South

// PSO sobre el escenario South. Todo lo demás (algoritmo, rangos, objetivo) viene de pso_comun.gaml.
import "pso_comun.gaml"

global { string scenario_override { return "South"; } }

experiment PSO_South parent: PSO_base type: batch repeat: 1 keep_seed: true until: (cycle >= 500) {}
