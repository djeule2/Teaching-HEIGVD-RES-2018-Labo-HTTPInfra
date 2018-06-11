$(function() {
        console.log("Loading animals");

        function loadAnimals() {
                $.getJSON( "/api/students/", function( animals ) {
                        console.log(animals);
                        var message = "No animal here";
                       
						message += ", compteur : " + animals.cmp; 
                        $(".intro-lead-in").text(message);
                });
        };

        loadAnimals();
        setInterval( loadAnimals, 2000 );
});