// DELETE EVERYTHING
:param path => '/Users/pdehaye/Work/COVID/GEgraph/';

MATCH (n) DETACH DELETE n;

// ACTUAL IMPORT

LOAD CSV WITH HEADERS FROM 'file://' + $path + 'data/redcap_suivi.csv' AS row
MERGE (p:PERSON{id_pos:row.record_id_pos});

// precreates infected/travel
LOAD CSV WITH HEADERS FROM 'file://' + $path + 'data/redcap_covitravel.csv' AS row
WITH row WHERE NOT row.record_id_pos IS null
MATCH (p:PERSON{id_pos:row.record_id_pos})
SET p.id_travel = row.record_id_travel;

// precreates infected/coga
LOAD CSV WITH HEADERS FROM 'file://' + $path + 'data/redcap_coga.csv' AS row
WITH row WHERE NOT row.record_id_pos IS null
MATCH (p:PERSON{id_pos:row.record_id_pos})
SET p.id_coga = row.record_id_coga;

// precreates infected/contact record
LOAD CSV WITH HEADERS FROM 'file://' + $path + 'data/redcap_entourage.csv' AS row
WITH row WHERE NOT row.record_id_pos IS null
MATCH (p:PERSON{id_pos:row.record_id_pos})
SET p.id_contact = row.contact_record_id;

// TRAVEL
LOAD CSV WITH HEADERS FROM 'file://' + $path + 'data/redcap_covitravel.csv' AS row
MERGE (person:PERSON{id_travel:row.record_id_travel})  // this will possibly match someone infected
MERGE (r:REGION{type:"pays", id:row.pays_visite})
CREATE (context:CONTEXT{type:"trip"})
CREATE (context)-[:LOCATION]->(r)
CREATE (person)-[:PRESENT]->(context)
CREATE (q:QUARANTINE{debut:CASE row.contact_q_datedeb WHEN NULL THEN NULL ELSE date(row.contact_q_datedeb) END, fin:CASE row.contact_q_datefin WHEN NULL THEN NULL ELSE date(row.contact_q_datefin) END})
CREATE (q)-[:CAUSE]->(context)
CREATE (q)-[:INDIVIDUAL]->(person);

//  COGA
LOAD CSV WITH HEADERS FROM 'file://' + $path + 'data/redcap_coga.csv' AS row
MERGE (person:PERSON{id_coga:row.record_id_coga}) // this will possibly match someone infected
MERGE (facility:FACILITY{type:"coga", destinataire:row.destinataire, salle:CASE row.salle WHEN NULL THEN "" ELSE row.salle END})
CREATE (context:CONTEXT{type:"event"})
CREATE (person)-[:PRESENT{debut:datetime(replace(row.date," ","T")), source:"coga"}]->(context)
CREATE (context)-[:LOCATION]->(facility);

// SUIVI
// suivi -> test
LOAD CSV WITH HEADERS FROM 'file://' + $path + 'data/redcap_suivi.csv' AS row
WITH row WHERE row.redcap_event_name = "labo_arm_1"
MERGE (p:PERSON{id_pos:row.record_id_pos})
SET p.date_res = date(row.date_res)
SET p.day_index = duration.inDays(date("2020-01-01"), date(row.date_res)).days;

// suivi -> adresse
LOAD CSV WITH HEADERS FROM 'file://' + $path + 'data/redcap_suivi.csv' AS row
WITH row WHERE row.redcap_event_name = "s1_arm_1"
WITH row WHERE row.redcap_repeat_instrument IS NULL
WITH row WHERE NOT row.lng IS NULL
MERGE (person:PERSON{id_pos:row.record_id_pos})
MERGE (residence:RESIDENCE{pt:point({latitude:toFloat(row.lat), longitude:toFloat(row.lng)})})
MERGE (context:CONTEXT{type:"residence"})-[:LOCATION]->(residence) // multiple people could live same address, we want this merged, i.e. identified as the same
CREATE (person)-[:PRESENT{status:"lives"}]->(context);

// suivi -> contact, pre-feed when contact_record_id is present
LOAD CSV WITH HEADERS FROM 'file://' + $path + 'data/redcap_suivi.csv' AS row
WITH row WHERE row.redcap_event_name = "s1_arm_1" 
WITH row WHERE row.redcap_repeat_instrument = "entourage"
MERGE (person:PERSON{id_pos:row.record_id_pos})
MERGE (context:CONTEXT{type:"suivi.redcap_repeat_instrument.entourage", id_pos:row.record_id_pos, instance:row.redcap_repeat_instance})
MERGE (person)-[:PRESENT{relation:"reference"}]->(context)
WITH row, context WHERE NOT row.contact_record_id IS NULL
MERGE (contact:PERSON{id_contact:row.contact_record_id})
MERGE (contact)-[:PRESENT{relation:"referenced"}]->(context);

// suivi -> contact, pre-feed when contact_record_id is NOT present
LOAD CSV WITH HEADERS FROM 'file://' + $path + 'data/redcap_suivi.csv' AS row
WITH row WHERE row.redcap_event_name = "s1_arm_1" 
WITH row WHERE row.redcap_repeat_instrument = "entourage"
MERGE (person:PERSON{id_pos:row.record_id_pos})
MERGE (context:CONTEXT{type:"suivi.redcap_repeat_instrument.entourage", id_pos:row.record_id_pos, instance:row.redcap_repeat_instance})
MERGE (person)-[:PRESENT{relation:"reference"}]->(context)
WITH row, context WHERE row.contact_record_id IS NULL
MERGE (contact:PERSON)-[:PRESENT{relation:"referenced"}]->(context);

// suivi -> contact
LOAD CSV WITH HEADERS FROM 'file://' + $path + 'data/redcap_suivi.csv' AS row
WITH row WHERE row.redcap_event_name = "s1_arm_1" 
WITH row WHERE row.redcap_repeat_instrument = "entourage"
MERGE (context:CONTEXT{type:"suivi.redcap_repeat_instrument.entourage", id_pos:row.record_id_pos, instance:row.redcap_repeat_instance})
MERGE (person)-[:PRESENT{relation:"reference"}]->(context)
SET context={
type:"suivi.contact",
classification:CASE row.contact_type WHEN NULL THEN NULL ELSE row.contact_type END,
contact_derniercont:CASE row.contact_derniercont WHEN NULL THEN NULL ELSE date(row.contact_derniercont) END,
day_index:CASE row.contact_derniercont WHEN NULL THEN NULL ELSE duration.inDays(date("2020-01-01"), date(row.contact_derniercont)).days END};

// ENTOURAGE
// this needs to be adapted to refer to the suivi -> contact CONTEXT as a cause
LOAD CSV WITH HEADERS FROM 'file://' + $path + 'data/redcap_entourage.csv' AS row 
WITH row WHERE NOT row.contact_record_id IS NULL
MERGE (p:PERSON{id_contact:row.contact_record_id})
MERGE (q:QUARANTINE{id_entourage:row.record_id_entourage})
SET q={debut:CASE row.contact_q_datedeb WHEN NULL THEN NULL ELSE date(row.contact_q_datedeb) END, fin:CASE row.contact_q_datefin WHEN NULL THEN NULL ELSE date(row.contact_q_datefin) END, contact_decision:CASE row.contact_decision WHEN NULL THEN NULL ELSE row.contact_decision END}
// WARNING: missing a CAUSE pointing at the entourage investigation, because this information is not in the export
MERGE (q)-[:INDIVIDUAL]->(p);

// this needs to be adapted to refer to the suivi -> contact CONTEXT as a cause
LOAD CSV WITH HEADERS FROM 'file://' + $path + 'data/redcap_entourage.csv' AS row 
WITH row WHERE row.contact_record_id IS NULL 
// WARNING: This should not happen in an ideal world, because a new contact lead would create an entry in the other table
CREATE (p:PERSON)
MERGE (q:QUARANTINE{id_entourage:row.record_id_entourage})
SET q={debut:CASE row.contact_q_datedeb WHEN NULL THEN NULL ELSE date(row.contact_q_datedeb) END, fin:CASE row.contact_q_datefin WHEN NULL THEN NULL ELSE date(row.contact_q_datefin) END, contact_decision:CASE row.contact_decision WHEN NULL THEN NULL ELSE row.contact_decision END}
// WARNING: missing a CAUSE pointing at the entourage investigation, because this information is not in the export
MERGE (q)-[:INDIVIDUAL]->(p);

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

// MARK INFECTED
MATCH (p:PERSON)
WITH p WHERE NOT p.id_pos IS NULL
SET p:INFECTED;


