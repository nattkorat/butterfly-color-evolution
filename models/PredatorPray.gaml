/**
* Name: PredatorPray
* Based on the internal skeleton template. 
* Author: nattkorat
* Tags: 
*/

model PredatorPray

global {
	/** Insert the global definitions, variables and actions here */
	list<rgb> color_list <- [#black, #white, #gray];
	shape_file Vegetation0_shape_file <- shape_file("../includes/Vegetation.shp");
	geometry shape <- envelope(Vegetation0_shape_file);
	
	int nb_butterfy <- 100;
	float predator_density_rate <- 0.1;

	init{
		create butterfly number: nb_butterfy;
		create environment from: Vegetation0_shape_file;
	}
}

species animal skills: [moving]{
	rgb my_color <- one_of(color_list);
	point target <- nil;
	float my_speed <- rnd(1#m/#mn, 5.0#m/#mn);
	
	aspect default{
		draw circle(3) color: my_color border: #black;
	}
	
	reflex get_random_loc when: target = nil {
		target <- any_location_in(one_of(environment));
	}
	
	reflex moving when: target != nil{
		do goto target: target speed: my_speed;
		if(location = target){
			target <- nil;
		}
	}
}

species butterfly parent: animal{
	
}

species environment{
	
	aspect default{
		draw shape color: #gray;
	}
}


experiment PredatorPray type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
		display "Scene" type: opengl{
			species environment;
			species butterfly;
		}
		
		display "Butterfly Living" type: 2d{
			chart "Trending Life of Dinstinct Butterfly Over Time" type: series {
				
			}
		}
		
		display "Butterflay Dist." type: 2d{
			chart "Butterfly Distribution" type: histogram color: #white background: rgb(22, 67, 93) {
				data "Gray Butterfly" value: butterfly count(each.my_color = #gray) color: #gray;
				data "Black Butterfly" value: butterfly count(each.my_color = #black) color: #black;
				data "White Butterfly" value: butterfly count(each.my_color = #white) color: rgb(255, 250, 255);
			}
		}
		
	}
}
