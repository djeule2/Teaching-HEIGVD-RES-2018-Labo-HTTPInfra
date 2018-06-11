var Chance = require('chance');
var chance = new Chance();

var compteur = 0;

const express = require('express')
const app = express()

app.get('/', function (req, res) {
  res.send(generateAnimals());
})

app.listen(3000, function () {
  console.log('Accepting HTTP requests on port 3000.')
})

function generateAnimals() {
	var numberOfAnimals = chance.integer({
		min: 0,
		max: 10
	});
	console.log(numberOfAnimals);
	var animals = [];
	for(var i = 0; i < numberOfAnimals; i++){
		var birthYear = chance.year({
			min: 1986,
			max: 1996
		});
		animals.push({
			cmp: compteur++,
			name: chance.first(),
			animalType: chance.animal(),
			birthday: chance.birthday({
				year: birthYear
			})
		});
	};
	console.log(animals);
	return animals;
}