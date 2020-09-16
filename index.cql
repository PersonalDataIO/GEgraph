CREATE CONSTRAINT ON (p:PERSON) ASSERT p.record_id_pos IS UNIQUE;  // implicitly creates index
CREATE CONSTRAINT ON (p:PERSON) ASSERT p.record_id_travel IS UNIQUE;
CREATE CONSTRAINT ON (p:PERSON) ASSERT p.record_id_coga IS UNIQUE;
CREATE CONSTRAINT ON (p:PERSON) ASSERT p.record_id_contact IS UNIQUE;

CREATE CONSTRAINT ON (q:QUARANTINE) ASSERT q.record_id_entourage IS UNIQUE;

CREATE INDEX FOR (c:CONTEXT) ON (c.type, c.id);
CREATE INDEX FOR (c:CONTEXT) ON (c.type, c.destinataire, c.salle);
CREATE INDEX FOR (c:CONTEXT) ON (c.type, c.record_id_pos, c.instance);
CREATE INDEX FOR (i:INFECTED) ON (i.record_id_coga);
CREATE INDEX FOR (i:INFECTED) ON (i.record_id_contact);
CREATE INDEX FOR (i:INFECTED) ON (i.record_id_travel);
