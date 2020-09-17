MATCH (i1:INFECTED)--(c1)--(x:PERSON)--(c2)--(i2:INFECTED)
WHERE NOT i1.day_index < 200 AND NOT i2.day_index < 200  
RETURN *
LIMIT 200
// (sometimes day_index is empty, needs to be taken into account)

