model centrogdl

global {
	string	case_study;
	string	file_path	<- "../includes/" + case_study + "/roads.shp" ;
	file	roads_file	<- file( file_path );
	
	
}
