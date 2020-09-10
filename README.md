# GEgraph: Contact tracing graph for Geneva canton

## Description of the data
This data is based on real data obtained through manual contact tracing in the Canton of Geneva. However it is:
* NOT a fully representative sample, 
* has significant noise introduced, and
* has some addtional permutations added,
all for privacy reasons.

Canton Geneva's strategy is (right now 20200910):
- to isolate every infected individual;
- to find their close contacts (>15min & <2m) during the two days period prior to symptoms (unclear what is done for asymptomatics);
- to quarantine their close contacts. 

The data contains this temporal slice of the social graph, a sort of wavefront expanding with the virus. Of course it is partial, as many cases are (still) being missed. 

![Screenshot of Neo4J result](https://github.com/PersonalDataIO/GEgraph/raw/master/screenshot.png "Screenshot of Neo4J result")

## How to read this graph
The graph above is one view on the data released, constructed in Neo4J. Beyond the raw data in CSV form, we have to make choices on how to model it in a graph database. We have chosen to connect individual through so-called *contexts*. Examples of contexts include:
* residence, as declared to the contact tracers through phone interview;
* close contact, as declared to the contact tracers through phone interview;
* same country of travel origin, when coming from a country on the list of countries forcing a quarantine;
* attendance to the same party, as logged through the [CoGa app](https://coga.app/), which is encouraged by public health authorities for event registration. 

Contexts are nodes here. This is because we want to eventually associate more data to those contexts (like hierarchies), and to the relations between individuals and their contexts. On a social network, the move we do here that is maybe most surprising is to represent friendships as groups of 2. 

Given that model, the graph presented here is a subset, consisting of the union of all nodes and relationships matching the grouping `(infected1)-(context1)--(person)--(context2)--(infected)` and then taking the union over all relationships between those nodes. Here `person` could also be infected! (also, due to Neo's [cyphermorphicity](https://www.slideshare.net/openCypher/configurable-pattern-matching-semantics-in-opencypher-defining-levels-of-node-and-relationship-uniqueness) and the way I have modeled this, `context1 != context2`). If you think about it, given the contact tracing strategy, this is all the non-infected persons in contact with at least two infected persons, as well as all the infected persons they were in contact with. 

Persons are represented in the graph with light brown circles. The smaller ones are infected, the bigger ones are not known to be. 
The circles between those correspond to context, colored according to which kind of common context they are: residence, social, work, etc. In darker blue, you have the co-residence context. Due to the data collection protocol, this one can appear multiple times between any two individuals, and in any case leads to obvious clusters. For the other contexts, the coloring is mostly pink/purple for social events/leisure, and dark green for work. 

The numbers in the circles represent:
- for infected individuals, the date of their positive result (index since January 1st 2020 of the day)
- for context, the day of the last encounter of that kind between the two individuals

![Zoom of Neo4J result](https://github.com/PersonalDataIO/GEgraph/raw/master/screenshot2.png "Zoom of Neo4J result")

## How to exploit this data
We include scripts to import this data into Neo4J.

This is a preliminary release. We do not think our scripts are very robust, and they can definitely be improved. Please file issues accordingly. 

## Goals in releasing this data
We hope this data might be useful in assessing the contact tracing strategies, explaining what contact tracing is, the proportionality of such techniques with respect to results, and in developing an interoperable framework across borders for opertations but also assessment of efficacy. 

## What is missing
* License on the data
* License on the code
* More complete description of the CSV data
* More complete description of the de-identification process that was followed to produce this CSV

## Thanks
With thanks to those who devoted time to this project within the [Cantonal Health Authority of Geneva canton](https://www.ge.ch/organisation/service-du-medecin-cantonal). 
