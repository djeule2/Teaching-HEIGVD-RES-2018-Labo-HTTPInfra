$(function() {
        console.log("Loading animals");

        function loadAnimals() {
                $.getJSON( "/api/students/", function( animals ) {
                        console.log(animals);
                        var message = "No animal here";
                        if( animals.length > 0 ) {
                                message = animals[0].name + " " + animals[0].animalType;
                        }
                        $(".intro-lead-in").text(message);
                });
        };

        loadAnimals();
        setInterval( loadAnimals, 2000 );
});