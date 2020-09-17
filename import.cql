// DELETE EVERYTHING
MATCH (n) DETACH DELETE n;

:param path => 'file:///Users/pdehaye/Work/COVID/GEgraph/';

// ACTUAL IMPORT

LOAD CSV WITH HEADERS FROM $path + 'data/redcap_suivi.csv' AS row
WITH row
CREATE (r:REDCAP_SUIVI)
SET r += row;

LOAD CSV WITH HEADERS FROM $path + 'data/redcap_covitravel.csv' AS row
WITH row
CREATE (r:REDCAP_COVITRAVEL)
SET r += row;

LOAD CSV WITH HEADERS FROM $path + 'data/redcap_coga.csv' AS row
WITH row
CREATE (r:REDCAP_COGA)
SET r += row;

LOAD CSV WITH HEADERS FROM $path + 'data/redcap_entourage.csv' AS row
WITH row
CREATE (r:REDCAP_ENTOURAGE)
SET r += row;

MATCH (r:REDCAP_SUIVI)
MERGE (p:PERSON{record_id_pos:r.record_id_pos});


// precreates infected/travel
MATCH (row:REDCAP_COVITRAVEL)
WITH row WHERE NOT row.record_id_pos IS NULL
MATCH (p:PERSON{record_id_pos:row.record_id_pos})
SET p.record_id_travel = row.record_id_travel;

// precreates non-infected/travel
MATCH (row:REDCAP_COVITRAVEL)
MERGE (p:PERSON{record_id_travel:row.record_id_travel});


// precreates infected/coga
MATCH (row:REDCAP_COGA)
WHERE EXISTS(row.record_id_pos)
MATCH (p:PERSON{record_id_pos:row.record_id_pos})
SET p.record_id_coga = row.record_id_coga;

// precreates non-infected/coga
MATCH (row:REDCAP_COGA)
MERGE (p:PERSON{record_id_coga:row.record_id_coga});

// precreates infected/entourage
MATCH (row:REDCAP_ENTOURAGE)
WITH row WHERE NOT row.record_id_pos IS NULL
MATCH (p:PERSON{record_id_pos:row.record_id_pos})
SET p.record_id_contact = row.contact_record_id;

// precreates non-infected/entourage
MATCH (row:REDCAP_ENTOURAGE)
WITH row WHERE NOT row.contact_record_id IS NULL   
// WARNING: SOME ARE NULL, THIS IS A PROBLEM
MERGE (p:PERSON{record_id_contact:row.contact_record_id});

// TRAVEL
MATCH (row:REDCAP_COVITRAVEL)
MERGE (person:PERSON{record_id_travel:row.record_id_travel})
MERGE (context:CONTEXT{type:"country", id:row.pays_visite})
MERGE (person)<-[:PRESENT]-(context)
CREATE (q:QUARANTINE{
debut:CASE row.contact_q_datedeb WHEN NULL THEN NULL ELSE date(row.contact_q_datedeb) END, 
fin:CASE row.contact_q_datefin WHEN NULL THEN NULL ELSE date(row.contact_q_datefin) END,
day_index:duration.inDays(date("2020-01-01"), date(row.contact_q_datedeb)).days
})
MERGE (context) <-[:CAUSE]- (q) -[:INDIVIDUAL]->(person);

//  COGA
MATCH (row:REDCAP_COGA)
MERGE (person:PERSON{record_id_coga:row.record_id_coga})
MERGE (context:CONTEXT{
type:"coga", 
destinataire:row.destinataire, 
salle:CASE row.salle WHEN NULL THEN "" ELSE row.salle END
})
MERGE (person)<-[:PRESENT{
debut:datetime(replace(row.date," ","T")), 
source:"coga"
}]-(context)
;

MATCH (c:CONTEXT{type:"coga"})-[r:PRESENT]->(p:PERSON)
SET c.day_index = duration.inDays(date("2020-01-01"), r.debut).days;

// SUIVI
// suivi -> test
MATCH (row:REDCAP_SUIVI{redcap_event_name:"labo_arm_1"}) 
MERGE (p:PERSON{record_id_pos:row.record_id_pos})
SET p.date_res = date(row.date_res)
SET p.day_index = duration.inDays(date("2020-01-01"), date(row.date_res)).days;

// suivi -> adresse
MATCH (row:REDCAP_SUIVI{redcap_event_name:"s1_arm_1"}) 
WITH row WHERE row.redcap_repeat_instrument IS NULL
WITH row WHERE NOT row.lng IS NULL
MERGE (person:PERSON{record_id_pos:row.record_id_pos})
MERGE (residence:RESIDENCE{pt:point({latitude:toFloat(row.lat), longitude:toFloat(row.lng)})})
MERGE (context:CONTEXT{type:"residence"})-[:LOCATION]->(residence) // multiple people could live same address, we want this merged, i.e. identified as the same
CREATE (person)<-[:PRESENT{status:"lives"}]-(context);

// suivi -> contact, pre-feed when contact_record_id is present
MATCH (row:REDCAP_SUIVI{redcap_event_name:"s1_arm_1", redcap_repeat_instrument: "entourage"}) 
MERGE (person:PERSON{record_id_pos:row.record_id_pos})
MERGE (context:CONTEXT{type:"suivi.redcap_repeat_instrument.entourage", record_id_pos:row.record_id_pos, instance:row.redcap_repeat_instance})
MERGE (person)<-[:PRESENT{source:"true"}]-(context)
WITH row, context WHERE NOT row.contact_record_id IS NULL
MERGE (contact:PERSON{record_id_contact:row.contact_record_id})
MERGE (contact)<-[:PRESENT]-(context);

// suivi -> contact, pre-feed when contact_record_id is NOT present
MATCH (row:REDCAP_SUIVI{redcap_event_name:"s1_arm_1", redcap_repeat_instrument: "entourage"}) 
WITH row WHERE row.contact_record_id IS NULL
CREATE (contact:PERSON)
MERGE (person:PERSON{record_id_pos:row.record_id_pos})
MERGE (context:CONTEXT{type:"suivi.redcap_repeat_instrument.entourage", record_id_pos:row.record_id_pos, instance:row.redcap_repeat_instance})
MERGE (person)<-[:PRESENT{source:"true"}]-(context)
MERGE (contact)<-[:PRESENT]-(context);

// suivi -> contact
MATCH (row:REDCAP_SUIVI{redcap_event_name:"s1_arm_1", redcap_repeat_instrument: "entourage"}) 
MERGE (context:CONTEXT{type:"suivi.redcap_repeat_instrument.entourage", record_id_pos:row.record_id_pos, instance:row.redcap_repeat_instance})
SET context={
type:"suivi.contact",
classification:row.contact_type,
contact_derniercont:date(row.contact_derniercont),
day_index:CASE row.contact_derniercont WHEN NULL THEN NULL ELSE duration.inDays(date("2020-01-01"), date(row.contact_derniercont)).days END};

// ENTOURAGE
// WARNING: this needs to be adapted to refer to the suivi -> contact CONTEXT as a cause;missing a CAUSE pointing at the entourage investigation, because this information is not in the export
MATCH (row:REDCAP_ENTOURAGE)
WITH row WHERE NOT row.contact_record_id IS NULL
MERGE (p:PERSON{record_id_contact:row.contact_record_id})
MERGE (q:QUARANTINE{record_id_entourage:row.record_id_entourage})
MERGE (q)-[:INDIVIDUAL]->(p)
SET q={
debut:CASE row.contact_q_datedeb WHEN NULL THEN NULL ELSE date(row.contact_q_datedeb) END, 
fin:CASE row.contact_q_datefin WHEN NULL THEN NULL ELSE date(row.contact_q_datefin) END, 
contact_decision:CASE row.contact_decision WHEN NULL THEN NULL ELSE row.contact_decision END,
day_index:CASE row.contact_q_datedeb WHEN NULL THEN NULL ELSE duration.inDays(date("2020-01-01"), date(row.contact_q_datedeb)).days END
}
;

// this needs to be adapted to refer to the suivi -> contact CONTEXT as a cause
// WARNING: missing a CAUSE pointing at the entourage investigation, because this information is not in the export
MATCH (row:REDCAP_ENTOURAGE)
WITH row WHERE row.contact_record_id IS NULL 
// WARNING: This should not happen in an ideal world, because a new contact lead would create an entry in the other table
CREATE (p:PERSON)
MERGE (q:QUARANTINE{record_id_entourage:row.record_id_entourage})
MERGE (q)-[:INDIVIDUAL]->(p)
SET q={
debut:CASE row.contact_q_datedeb WHEN NULL THEN NULL ELSE date(row.contact_q_datedeb) END, 
fin:CASE row.contact_q_datefin WHEN NULL THEN NULL ELSE date(row.contact_q_datefin) END, 
contact_decision:CASE row.contact_decision WHEN NULL THEN NULL ELSE row.contact_decision END,
day_index:CASE row.contact_q_datedeb WHEN NULL THEN NULL ELSE duration.inDays(date("2020-01-01"), date(row.contact_q_datedeb)).days END
};

MATCH (c:CONTEXT)
WHERE c.classification = "1"
SET c:CONTEXT_RESIDENCE;

MATCH (c:CONTEXT)
WHERE c.type = "residence"
SET c:CONTEXT_RESIDENCE;

MATCH (c:CONTEXT)
WHERE c.classification = "2"
SET c:CONTEXT_INTIMATE;

MATCH (c:CONTEXT)
WHERE c.classification = "3"
SET c:CONTEXT_PRO;

MATCH (c:CONTEXT)
WHERE c.classification = "4"
SET c:CONTEXT_HEALTH;

MATCH (c:CONTEXT)
WHERE c.classification = "5"
SET c:CONTEXT_SOCIAL;

MATCH (c:CONTEXT)
WHERE c.classification = "6"
SET c:CONTEXT_FUN;

MATCH (c:CONTEXT)
WHERE c.classification = "7"
SET c:CONTEXT_OTHER;

MATCH (c:CONTEXT)
WHERE c.classification = "8"
SET c:CONTEXT_UNI;

MATCH (c:CONTEXT)
WHERE c.classification = "9"
SET c:CONTEXT_SCHOOL;

MATCH (c:CONTEXT)
WHERE c.type = "country"
SET c:CONTEXT_REGION;

MATCH (c:CONTEXT)
WHERE c.type = "coga"
SET c:CONTEXT_COGA;


// MARK INFECTED
MATCH (p:PERSON)
WHERE EXISTS(p.record_id_pos)
SET p:INFECTED;

MATCH (i1:INFECTED)<-[r:PRESENT]-(c:CONTEXT)
WHERE NOT c.day_index IS NULL
SET r.delay = i1.day_index - c.day_index;

// Delete redundant edges on contact pairs
MATCH (c1:CONTEXT{type:"residence"})--(p1:PERSON)--(c2:CONTEXT{classification:"1"})--(p2:PERSON)
WHERE NOT EXISTS((c1)-[:PRESENT{status:"lives"}]->(p2))
MERGE (c1)-[:PRESENT{status:"lives", inferred:"true"}]->(p2);

MATCH (c1:CONTEXT_RESIDENCE)--(p1:PERSON)-[r1]-(c2:CONTEXT{classification:"1"})-[r2]-(p2:PERSON)--(c1)
DETACH DELETE c2;


//count population
MATCH (c:CONTEXT)--(i:INFECTED)
WITH c, COUNT(i) AS population
SET c.infected_population = population;

MATCH (c:CONTEXT)--(i:PERSON)
WITH c, COUNT(i) AS population
SET c.total_population = population;

MATCH (c:CONTEXT)
SET c.prevalence = toFloat(c.infected_population)/toFloat(c.total_population);
