/**
* Name: PredatorPray
* Based on the internal skeleton template. 
* Author: nattkorat
* Tags: 
*/

model PredatorPrey

global {
	/** Insert the global definitions, variables and actions here */
	list<rgb> color_list <- [#black, #white, #gray];
	list<rgb> region_color_list <- [#black, #white, #gray];
	shape_file Vegetation0_shape_file <- shape_file("../includes/Vegetation.shp");
	geometry shape <- envelope(Vegetation0_shape_file);
	
	int nb_butterfy <- 100;
	float predator_density_rate <- 0.1;
	
	int black <- int(#black);
	int gray <- int(#gray);
	int mean_bg <- int(mean(black, gray));
	int white <- int(#white);
	int mean_wg <- int(mean(gray, white));
	
	
	int nb_white <- 0;
	
	int nb_gray <- 0;
	
	int nb_black <- 0;
	
	

	init{
		create butterfly number: nb_butterfy;
		create environment from: Vegetation0_shape_file;
		do observe;
		
//		write("White "+int(rgb(255, 255, 255)));
//		write("V_White "+int(rgb(254, 254, 254)));
//		write("Gray "+ int(#gray));
//		write("Black " + int (#black));
		
		write(white);
		write(mean_wg);
		write(gray);
		write(mean_bg);
		write(black);
		
		
	}
	
	
	action observe {
		nb_white <- butterfly count(int(each.my_color) between(mean_wg, 0));
		nb_black <- butterfly count(int(each.my_color) between(black-1, mean_bg));
		nb_gray <- butterfly count(int(each.my_color) between(mean_bg, mean_wg));

		
		
		write("Nb Gray: " + nb_gray);
		write("Nb White: " + nb_white);
		write("Nb Black: " + nb_black);
		
		write(10 between(-1, 11));
	}
	
	reflex update{
		do observe;
	}
	

}

species animal skills: [moving]{
	rgb my_color <- one_of(color_list);
	environment target <- nil;
	float my_speed <- rnd(8#km/#h, 19#km/#h);
	
	aspect default{
		draw circle(3) color: my_color border: #black;
		write("bla");
	}
	
	reflex get_random_loc when: target = nil {
		target <- one_of(environment);
	}
	
}

species butterfly parent: animal{
	float spending_time <- rnd(0.5#d, 1#d);
	bool reached_target <- false;
	rgb original_color <- my_color;
	
	reflex stay when: reached_target{
		do wander amplitude: 2.0;
		spending_time <- spending_time - 5#mn;
		if (spending_time <= 0){
			reached_target <- false;
			spending_time <- rnd(0.5#d, 1#d);
		}
	}
	
	reflex moving when: target != nil and not reached_target{
		do goto target: target speed: my_speed;
		if(location = target.location){
			target <- nil;
			reached_target <- true;
		}
	}
	
	reflex env_adapt {
		if(location overlaps target){
			my_color <- blend(my_color, target.my_color);
		}else{
			my_color <- blend(my_color, original_color);
		}
	}
	
	aspect default {
		draw reached_target? triangle(5): circle(5) color: my_color border: #red;
	}
}

species environment{
	rgb my_color;
	float season_period <- 10#d;
	
	init{
		my_color <- one_of(region_color_list);
	}
	
	reflex update_time{
		season_period <- season_period - 1#mn;
	}
	
	reflex update_color when: season_period <= 0{
		rgb new_color <- one_of(region_color_list);
		if(my_color != new_color){
			my_color <- new_color;
			season_period <- 10#d;
		}
	}
	
	aspect default{
		draw shape color: my_color;
	}
}


experiment PredatorPray type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
		display "Scene" background: rgb(102,89,63){
			species environment;
			species butterfly;
		}
		
		display "Butterfly Living" type: 2d{
			chart "Trending Life of Dinstinct Butterfly Over Time" type: series {
				data "Gray Butterfly" value: nb_gray color: #gray;
				data "Black Butterfly" value: nb_black color: #black;
				data "White Butterfly" value: nb_white color: #red;
			}
		}
		
		display "Butterflay Dist." type: 2d{
			chart "Butterfly Distribution" type: histogram color: #white background: rgb(22, 67, 93) {
				data "Gray Butterfly" value: butterfly count(each.original_color = #gray) color: #gray;
				data "Black Butterfly" value: butterfly count(each.original_color = #black) color: #black;
				data "White Butterfly" value: butterfly count(each.original_color = #white) color: rgb(255, 250, 255);
			}
		}
		
	}
}
