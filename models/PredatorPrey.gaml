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
	
	int nb_butterfly <- 100;
	float distance_to_reproduce <- 0.5#m;
	float predator_density_rate <- 0.1;
	float sense_to_catch_butterfly <- 1#m;
	float killing_rate <- 0.9;
	
	int black <- int(#black);
	int gray <- int(#gray);
	int mean_bg <- int(mean(black, gray));
	int white <- int(#white);
	int mean_wg <- int(mean(gray, white));
	
	
	int nb_white;
	int nb_gray;
	int nb_black;
	
	int c_nb_white;
	int c_nb_gray;
	int c_nb_black;
	
	int nb_kill_white <- 0;
	int nb_kill_black <- 0;
	int nb_kill_gray <- 0;
	
	float env_season_period <- 1#h;
	
	

	init{
		create environment from: Vegetation0_shape_file;
		create butterfly number: nb_butterfly;
		create predator number: int(predator_density_rate * nb_butterfly);
		do observe;
		c_nb_white <- nb_white;
		c_nb_black <- nb_black;
		c_nb_gray <- nb_gray;
	}
	
	reflex stopWhenNoB when: length(butterfly) <= 0{
		do pause;
	}
	
	
	action observe {
		nb_white <- butterfly count(int(each.my_color) between(mean_wg, 0));
		nb_black <- butterfly count(int(each.my_color) between(black-1, mean_bg));
		nb_gray <- butterfly count(int(each.my_color) between(mean_bg, mean_wg));

	}
	
	reflex update{
		do observe;
	}

}

species animal skills: [moving]{
	float lifetime;
	rgb my_color <- one_of(color_list);
	environment target <- nil;
	float my_speed <- rnd(8#km/#h, 19#km/#h);
	
	
	reflex get_random_loc when: target = nil {
		target <- one_of(environment);
	}
	
	aspect default{
		draw circle(3) color: my_color border: #black;
		
	}
	
	
}

species butterfly parent: animal{
	float spending_time <- rnd(0.5#d, 1#d);
	bool reached_target <- false;
	rgb original_color <- my_color;
	environment current_env <- nil;
	
	init {
		lifetime <- rnd(4#d, 7#d); // few week lifetime
	}
	
	reflex stay when: reached_target{
		do move heading: rnd(0.0, 360.0) speed: my_speed bounds: current_env;
		spending_time <- spending_time - 5#mn;
		if (spending_time <= 0){
			reached_target <- false;
			spending_time <- rnd(0.5#d, 1#d);
		}
	}
	
	reflex moving when: target != nil and not reached_target{
		do goto target: target speed: my_speed;
		if(location = target.location){
			current_env <- target;
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
	
	reflex reproduce{
		butterfly my_peer <- one_of(butterfly at_distance(distance_to_reproduce)); // parameter
		
		if(my_peer != nil){
			if(original_color = my_peer.original_color){
				create butterfly{
					self.my_color <- myself.original_color;
					if(self.my_color = #gray){
						c_nb_gray <- c_nb_gray + 1;
					}else if(self.my_color = #black){
						c_nb_black <- c_nb_black + 1;
					}else{
						c_nb_white <- c_nb_white + 1;
					}
				}
				write("Baby with " + original_color + " butterfly is born ;)");
			}else{
				// for the special case of gray with other colors butterfly
				if (original_color = #gray){
					if(my_peer.original_color = #black){
						create butterfly{
							self.my_color <- flip(0.5)? #gray: #black;
							if(self.my_color = #gray){
								c_nb_gray <- c_nb_gray + 1;
							}else{
								c_nb_black <- c_nb_black + 1;
							}
						}
					}else{
						create butterfly{
							self.my_color <- flip(0.5)? #gray: #white;
							if(self.my_color = #gray){
								c_nb_gray <- c_nb_gray + 1;
							}else{
								c_nb_white <- c_nb_white + 1;
							}
						}
					}
					write("Mixing Baby with " + original_color + " butterfly is born ;)");
				}
			}
		}
		
	}
	
	reflex aging_and_die {
		if(lifetime > 0){
			lifetime <- lifetime - 1#h;
		}else{
			write ("Butterfly" + name + " is old and die ;(");
			do die;
		}
	}
	
	aspect default {
		draw reached_target? triangle(10): circle(5) color: my_color border: #red;
	}
}

species predator parent: animal {
	environment my_environment;
	int nb_eated_butterfly <- 0;
	
	init {
		
		my_environment <- one_of(environment);
		location <- any_location_in(my_environment);
		target <- my_environment;

		lifetime <- rnd(7#d, 14#d); // few week lifetime
	}

	
	reflex catching {
		/**
		 * 1. Check the all butterfly in the area and know only different color from env
		 * 2. Select one and to to catch it (catching around 50%)
		 */
		 list<butterfly> bt_in_region <- butterfly select(
		 	(each.location overlaps my_environment)
		 );
		 
		 list<butterfly> diff_color_bt;
		 
		 if(my_color = #black){ 	
			 diff_color_bt <- bt_in_region select(not(int((each.my_color)) between(black-1, mean_bg)));
		 }
		 if(my_color = #white){ 	
			 diff_color_bt <- bt_in_region select(not(int((each.my_color)) between(mean_wg, 0)));
		 }
		 if(my_color = #gray){ 	
			 diff_color_bt <- bt_in_region select(not(int((each.my_color)) between(mean_bg, mean_wg)));
		 }
		 
		 list<butterfly> surounding_bt <- diff_color_bt at_distance(sense_to_catch_butterfly); // parameter
		 
		 butterfly victim <- one_of(surounding_bt);
		 
		 if(victim != nil){
			location <- victim.location;
			 ask victim {
			 	if(flip(killing_rate)){ // parameter
			 		myself.nb_eated_butterfly <- myself.nb_eated_butterfly + 1;
			 		
			 		if(self.original_color = #gray){
			 			nb_kill_gray <- nb_kill_gray + 1;
			 		}else if(self.original_color = #black){
			 			nb_kill_black <- nb_kill_black + 1;
			 		}else{
			 			nb_kill_white <- nb_kill_white + 1;
			 		}
			 		
			 		write("Oh I got catch ;(");
			 		do die;
			 	}
			 }
		 }else{
		 	do goto target: any_location_in(one_of(bt_in_region)) speed: my_speed;
		 } 
		 
	}
	
	reflex produce when: nb_eated_butterfly > 5 { // paramter
		create predator{
			location <- any_location_in(one_of(environment));
		}
		nb_eated_butterfly <- 0;
	}
	
	reflex aging {
		if(lifetime > 0){
			lifetime <- lifetime - 1#h;
		}else{
			do die;
		}
	}

	
	aspect default {
		draw square(10) color: #red;
	}
}

species environment{
	rgb my_color;
	float season_period <- env_season_period;
	
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
			season_period <- env_season_period;
		}
	}
	
	aspect default{
		draw shape color: my_color;
	}
}


experiment PredatorPray type: gui {
	/** Insert here the definition of the input and output of the model */
	parameter "Predator Density Rate" category: "Predator" var: predator_density_rate <- 0.1 min:0.1 max: 1.0;
	parameter "Sense to Catch Butterfly" category: "Predator" var: sense_to_catch_butterfly <- 1#m min: 0.1#m max: 5#m;
	parameter "Killing Rate" category: "Predator" var: killing_rate <- 0.9 min: 0.1 max: 1.0;
	
	
	parameter "Distance of Butterfly to Reproduce" category: "Butterfly" var: distance_to_reproduce <- 0.5#m min: 0.0#m max: 1.5#m;
	
	parameter "Season Duration" category: "Environment" var:env_season_period <- 1#h min: 0.5#h max: 30#h;
	
	output {
		monitor "Killing White Rate" value: nb_kill_white / c_nb_white;
		monitor "Killing Black Rate" value: nb_kill_black / c_nb_black;
		monitor "Killing Gray Rate" value: nb_kill_gray / c_nb_gray;
		
		display "Scene" background: rgb(102,89,63){
			species environment;
			species butterfly;
			species predator;
		}
		
		display "Butterfly Living" type: 2d{
			chart "Trending Life of Dinstinct Butterfly Over Time" type: series background: #yellow{
				data "Gray Butterfly" value: nb_gray color: #gray;
				data "Black Butterfly" value: nb_black color: #black;
				data "White Butterfly" value: nb_white color: #white;
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
