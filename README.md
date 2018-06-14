
Voici un script permettant:
* de generer des données de type "courbes de charge " et "operation de charge"
* de les transmettre à advenir.mobi, en HTTPS 


Les données brutes proviennent d'un parc de borne de recharges existant, qui comporte des messages OCPP 1.5 au format json.

Usage :
```
 > ruby advenir.rb USER-ID-ADVENIR dir
 > ruby advenir.rb 986932097096 site1 > out.site1.json
```

les fichiers json/OCPP de tests sont recherchés en  ```data-json/dir/log_*.txt```


LICENSE
=======
Les elements de ce projet sont independant de l'association AVERE. 
Ceci est une production d'un particulier, fournis a titre didactique.

Libre : MIT