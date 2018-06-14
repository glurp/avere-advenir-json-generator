
Voici un script permettant:
* de generer des données de type "courbes de charge " et "operation de charge"
* de les transmettre a advenir.mobi, en HTTPS ( TODO )


Les données brutes proviennes d'un parc de borne de recharges existant, qui conmporte des message OCPP 1.5
au format json.

Usage
> ruby advenir.rb USER-ID-ADVENIR dir

les fichiers json/OCPP sont recherch en ..../dir/scpecific_WEB/bornesjson/log_*.txt

LICENSE
=======
Libre : MIT