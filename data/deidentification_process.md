First anonymization pass
=

Il y a 4 fichiers :
* Redcap_suivi correspond au projet de suivi des cas positifs au COVID19.
* Redcap_covitravel correspond au projet des gens se déclarant comme retour de voyage d’un pays a risque
* Redcap_entourage est le projet de suivi des quarantaines de l’entourage des personnes positives (déclarées par la personne positive)
* Redcap_coga sont les gens donnés par l’application coga lorsque une requête est faite par le smc (service médecin cantonal)

La structure est celle données par redcap. J’ai du coder quelques variables pour avoir les liens entre les différents projets.
J’appelle contact étroit ou entourage les gens déclaré comme contact par une personne positive covid, j’appelle patient index la personne positive qui a déclaré quelqu’un comme entourage.

Redcap_suivi
---

|identifiant|description|
|---|---|
|record_id_pos	|Identifiant de la personne positive|
|redcap_event_name	|Variable de structure redcap (format lonitudinal : nom de l’évènement)|
|redcap_repeat_instrument	|Variable de structure redcap : nom du formulaire répétable|
|redcap_repeat_instance	|Variable de structure redcap, numéro d’instance du formulaire répétable|
|date_res	|Date de résultat|
|lng	|Longitude de l’adresse|
|lat	|Latitude de l’adresse|
|contact_record_id	|Identifiant de la personne contact|
|contact_derniercont|	Date du dernier contact avec avec le patient index|
|contact_type	|Type de lien avec le patient index : 1	Vit sous le même toit, 2	Contact intime (ne vivant pas sous le même toit), 3	Professionnel 4	Milieu de la santé 5	Relation sociale 6	Loisirs 8	Formation professionnelle/universitaire 9	Milieu scolaire (crèche, primaire, secondaire I et II) 7	Autre|


La table contient plusieurs « formulaire », donc plusieures source d’information. Ce qui est désigné par la variable redcap_event_name par « labo_arm_1 » concerne les résultat du labo, et donne la variable date_res, la date du résultat. Dans l’évènement s1_arm_1 (redcap_event_name == « s1_arm_1 »), il y a un formulaire qui correspond à la variable redcap_repeat_instrument vide, qui contient les données sur la personne positive, dont son adresse avec lng et lat ; puis des formulaires répétables données par redcap_event_name == s1_arm_1, redcap_repeat_instrument == entourage, avec chaque formulaire donné par un entier dans la variable redcap_repeat_instance correspondant à un contact étroit de la personne positive. Exemple :



Le record 869 a un résultat le 28.04, habite 6.15 46.17, et vit avec deux personnes identifiées par contact_record_id 5 et 6, dont le dernier contact remonte au 28.04.2020

Redcap_entourage
---

Le projet entourage à une entrée par quarantaine/contact
|identifiant|description|
|---|---|
|record_id_entourage	|Identifiant de la quarantaine|
|record_id_pos	|Identifiant de cette personne dans le projet suivi si à eu un test positif|
|contact_record_id	|Identifiant de la personne contact étroit (cf projet suivi)|
|contact_decision	|1	Quarantaine 2	Auto-surveillance  3	Aucune mesure|
|contact_q_datedeb	|Date de début de quarantaine|
|contact_q_datefin	|Date de fin de quarantaine|


Exemple : pour le contact 5 du record_id_pos 869 (exemple du dessus) :

|record_id_entourage|	record_id_pos|	contact_record_id|	contact_decision|	contact_q_datedeb|	contact_q_datefin|
|---|---|---|---|---|---|
|1351	|<NA>	|5	|1	|06.05.2020	|16.05.2020|


Cette personne est mise en quarantaine du 06.05 au 16.05, n’est pas devenue positive/n’a pas été positive (sinon record_id_pos serait renseigné, et donnerai l’entrée de cette personne dans redcap_suivi)

Redcap_covitravel
---
|identifiant|description|
|---|---|
|record_id_travel|	Identifiant de la personne retournant de voyage|
|record_id_pos|	Identifiant dans le projet suivi si cette personne à été testée positive|
|pays_visite|	Identifiant su pays|
|contact_q_datedeb|	Date de début de quarantaine, correspondant à la date de retour en suisse|
|contact_q_datefin|	Date de fin de quarantaine|


Redcap_coga
---
|identifiant|description|
|---|---|
|record_id_coga|	Identifiant coga|
|record_id_pos|	Identifiant dans le projet suivi si cette personne à été testée positive|
|destinataire|	Lieu de fréquentation (destinataire de la requête coga)|
|salle|	Salle du lieu|
|date|	Date de la fréquentation|


Pour chaque valeur de destinataire, les entrées correspondent aux gens présents à ce moment pour la date données
Anonymisation

Les dates ont été décalées de manière random de +- une semaine. Les localisations sont données avec un jitter tiré d’une distribution uniforme d’un km, et les identifiants ont été recodés en entiers. J’ai forcé les dates de fin de quarantaine à être le début + 10 jours, et les pays de provenance ont été tirés aléatoirement avec une distribution uniforme. J’ai viré aléatoirement une certaine quantité des entrées dans les différents projets pour qu’on ne puisse pas faire des stats sur ces données. Dans redcap_suivi, il y a seulement les entrées avec des données contact ou apparaissant dans les autres projets.

Second anonymization pass
=

contact_types have been merged for privacy reasons: 2 -> 1, 8 -> 3, 9 -> 7 (i.e. intimate is folded into co-living, university is folded into professional, school is folded into other)

coga file has been modified significantly, e.g. the positive ids are picked at random around the correct one

