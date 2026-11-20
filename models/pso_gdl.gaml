model UrbanMobility_PSO_GDL_Oeste

// PSO sobre el escenario GDL_Oeste. Todo lo demás (algoritmo, rangos, objetivo) viene de pso_comun.gaml.
import "pso_comun.gaml"

global { string scenario_override { return "GDL_Oeste"; } }

experiment PSO_GDL_Oeste parent: PSO_base type: batch repeat: 1 keep_seed: true until: (cycle >= 500) {}
