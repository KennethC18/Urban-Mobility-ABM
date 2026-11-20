model UrbanMobility_PSO_Lomas

// PSO sobre el escenario Lomas. Todo lo demás (algoritmo, rangos, objetivo) viene de pso_comun.gaml.
import "pso_comun.gaml"

global { string scenario_override { return "Lomas"; } }

experiment PSO_Lomas parent: PSO_base type: batch repeat: 1 keep_seed: true until: (cycle >= 500) {}
