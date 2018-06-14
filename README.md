
Voici un script permettant:
* de generer des données de type "courbes de charge " et "operation de charge"
* de les transmettre a advenir.mobi, en HTTPS ( TODO :) )


Les données brutes proviennent d'un parc de borne de recharges existant, qui comporte des messages OCPP 1.5 au format json.

Usage
> ruby advenir.rb USER-ID-ADVENIR dir
> ruby advenir.rb 986932097096 site1 > out.site1.json

les fichiers json/OCPP sont recherchés en  data-json/<dir>/log_*.txt

LICENSE
=======
Libre : MIT