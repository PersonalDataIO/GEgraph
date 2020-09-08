// context: circumstances that might lead to infection, has hierarchy dictated by space and time
// context space-distance: given background knowledge, pairwise function on contexts
// context time-distance: given background knowledge, pairwise function on contexts
// every context C has a type C.type in T
// two functions Mspace, Mtime: T -> float

// lieu
// personne
//     residence -> lieu
// test: 
//     prise -> date
//     personne -> {positif, negatif}
//     resultat -> date
// statut
// mesures: isolation, quarantaine

// tracage de contact
// (i:I) => (i:I) -[:PRESENT]-> (c:C) <-[:PRESENT]- (:P)

// contact.wait contact.en_cours
// 

// preliminary work on removing "import" in the settings

// CONSTRUCT INDEXES

DROP INDEX ON :CONTEXT(id);
DROP INDEX ON :CONTEXT(destinataire, salle);



// INDEX.cql

// IMPORT.cql



// STATISTICS
MATCH (p:PERSON) -[i:PRESENT]-> (c:CONTEXT)
WITH p, i, c WHERE p.id_pos IS NULL
RETURN c.type, COUNT(*)

MATCH (p:PERSON) -[i:PRESENT]-> (c:CONTEXT)
WITH p, i, c WHERE NOT p.id_pos IS NULL
RETURN c.type, COUNT(*)

// GRAPHS

MATCH (i:INFECTED)
WITH i
REMOVE i:PERSON


MATCH (i1:INFECTED)-[:PRESENT]->(c1:CONTEXT)<-[:PRESENT]-(p:PERSON)-[:PRESENT]->(c2:CONTEXT)<-[:PRESENT]-(i2:INFECTED)
WHERE NOT i1=i2
RETURN *



MATCH (:INFECTED)-[:PRESENT]->(c1:CONTEXT)<-[:PRESENT]-(p1:PERSON)-[:PRESENT]->(c2:CONTEXT)<-[:PRESENT]-(:INFECTED)
RETURN *

MATCH (i1:INFECTED)-[:PRESENT]->(c1:CONTEXT)<-[:PRESENT]-(p1:PERSON)-[:PRESENT]->(c2:CONTEXT)<-[:PRESENT]-(i2:INFECTED)
RETURN *

MATCH (i1:INFECTED)-[:PRESENT]->(c1:CONTEXT)<-[:PRESENT]-(p1:PERSON)-[:PRESENT]->(c2:CONTEXT)<-[:PRESENT]-(i2:INFECTED)
RETURN duration.between(c1.contact_derniercont, c2.contact_derniercont)


// MISSING: link QUARANTINE -[:CAUSE] -> CONTACT

// order a test on an asymptomatic?
// quarantine forced under some strict conditions?
// 

// causes de quarantaine:
// - contact
// - presence a un evenement
// - presence dans un pays
