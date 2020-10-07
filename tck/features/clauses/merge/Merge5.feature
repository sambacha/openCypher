#
# Copyright (c) 2015-2020 "Neo Technology,"
# Network Engine for Objects in Lund AB [http://neotechnology.com]
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Attribution Notice under the terms of the Apache License 2.0
#
# This work was created by the collective efforts of the openCypher community.
# Without limiting the terms of Section 6, any Derivative Work that is not
# approved by the public consensus process of the openCypher Implementers Group
# should not be described as “Cypher” (and Cypher® is a registered trademark of
# Neo4j Inc.) or as "openCypher". Extensions by implementers or prototypes or
# proposals for change that have been documented or implemented should only be
# described as "implementation extensions to Cypher" or as "proposed changes to
# Cypher that are not yet approved by the openCypher community".
#

#encoding: utf-8

Feature: Merge5 - Merge Relationships

  Scenario: Creating a relationship
    Given an empty graph
    And having executed:
      """
      CREATE (:A), (:B)
      """
    When executing query:
      """
      MATCH (a:A), (b:B)
      MERGE (a)-[r:TYPE]->(b)
      RETURN count(*)
      """
    Then the result should be, in any order:
      | count(*) |
      | 1        |
    And the side effects should be:
      | +relationships | 1 |

  Scenario: Matching a relationship
    Given an empty graph
    And having executed:
      """
      CREATE (a:A), (b:B)
      CREATE (a)-[:TYPE]->(b)
      """
    When executing query:
      """
      MATCH (a:A), (b:B)
      MERGE (a)-[r:TYPE]->(b)
      RETURN count(r)
      """
    Then the result should be, in any order:
      | count(r) |
      | 1        |
    And no side effects

  Scenario: Matching two relationships
    Given an empty graph
    And having executed:
      """
      CREATE (a:A), (b:B)
      CREATE (a)-[:TYPE]->(b)
      CREATE (a)-[:TYPE]->(b)
      """
    When executing query:
      """
      MATCH (a:A), (b:B)
      MERGE (a)-[r:TYPE]->(b)
      RETURN count(r)
      """
    Then the result should be, in any order:
      | count(r) |
      | 2        |
    And no side effects

  Scenario: Filtering relationships
    Given an empty graph
    And having executed:
      """
      CREATE (a:A), (b:B)
      CREATE (a)-[:TYPE {name: 'r1'}]->(b)
      CREATE (a)-[:TYPE {name: 'r2'}]->(b)
      """
    When executing query:
      """
      MATCH (a:A), (b:B)
      MERGE (a)-[r:TYPE {name: 'r2'}]->(b)
      RETURN count(r)
      """
    Then the result should be, in any order:
      | count(r) |
      | 1        |
    And no side effects

  Scenario: Creating relationship when all matches filtered out
    Given an empty graph
    And having executed:
      """
      CREATE (a:A), (b:B)
      CREATE (a)-[:TYPE {name: 'r1'}]->(b)
      """
    When executing query:
      """
      MATCH (a:A), (b:B)
      MERGE (a)-[r:TYPE {name: 'r2'}]->(b)
      RETURN count(r)
      """
    Then the result should be, in any order:
      | count(r) |
      | 1        |
    And the side effects should be:
      | +relationships | 1 |
      | +properties    | 1 |

  Scenario: Matching incoming relationship
    Given an empty graph
    And having executed:
      """
      CREATE (a:A), (b:B)
      CREATE (b)-[:TYPE]->(a)
      CREATE (a)-[:TYPE]->(b)
      """
    When executing query:
      """
      MATCH (a:A), (b:B)
      MERGE (a)<-[r:TYPE]-(b)
      RETURN count(r)
      """
    Then the result should be, in any order:
      | count(r) |
      | 1        |
    And no side effects

  Scenario: Creating relationship with property
    Given an empty graph
    And having executed:
      """
      CREATE (a:A), (b:B)
      """
    When executing query:
      """
      MATCH (a:A), (b:B)
      MERGE (a)-[r:TYPE {name: 'Lola'}]->(b)
      RETURN count(r)
      """
    Then the result should be, in any order:
      | count(r) |
      | 1        |
    And the side effects should be:
      | +relationships | 1 |
      | +properties    | 1 |

  Scenario: Creating relationship using merged nodes
    Given an empty graph
    And having executed:
      """
      CREATE (a:A), (b:B)
      """
    When executing query:
      """
      MERGE (a:A)
      MERGE (b:B)
      MERGE (a)-[:FOO]->(b)
      """
    Then the result should be empty
    And the side effects should be:
      | +relationships | 1 |

  Scenario: Introduce named paths 1
    Given an empty graph
    When executing query:
      """
      MERGE (a {num: 1})
      MERGE (b {num: 2})
      MERGE p = (a)-[:R]->(b)
      RETURN p
      """
    Then the result should be, in any order:
      | p                             |
      | <({num: 1})-[:R]->({num: 2})> |
    And the side effects should be:
      | +nodes         | 2 |
      | +relationships | 1 |
      | +properties    | 2 |

  Scenario: Use outgoing direction when unspecified
    Given an empty graph
    When executing query:
      """
      CREATE (a {id: 2}), (b {id: 1})
      MERGE (a)-[r:KNOWS]-(b)
      RETURN startNode(r).id AS s, endNode(r).id AS e
      """
    Then the result should be, in any order:
      | s | e |
      | 2 | 1 |
    And the side effects should be:
      | +nodes         | 2 |
      | +relationships | 1 |
      | +properties    | 2 |

  Scenario: Match outgoing relationship when direction unspecified
    Given an empty graph
    And having executed:
      """
      CREATE (a {id: 1}), (b {id: 2})
      CREATE (a)-[:KNOWS]->(b)
      """
    When executing query:
      """
      MATCH (a {id: 2}), (b {id: 1})
      MERGE (a)-[r:KNOWS]-(b)
      RETURN r
      """
    Then the result should be, in any order:
      | r        |
      | [:KNOWS] |
    And no side effects

  Scenario: Match both incoming and outgoing relationships when direction unspecified
    Given an empty graph
    And having executed:
      """
      CREATE (a {id: 2}), (b {id: 1}), (c {id: 1}), (d {id: 2})
      CREATE (a)-[:KNOWS {name: 'ab'}]->(b)
      CREATE (c)-[:KNOWS {name: 'cd'}]->(d)
      """
    When executing query:
      """
      MATCH (a {id: 2})--(b {id: 1})
      MERGE (a)-[r:KNOWS]-(b)
      RETURN r
      """
    Then the result should be, in any order:
      | r                     |
      | [:KNOWS {name: 'ab'}] |
      | [:KNOWS {name: 'cd'}] |
    And no side effects

  Scenario: Using list properties via variable
    Given an empty graph
    When executing query:
      """
      CREATE (a:Foo), (b:Bar)
      WITH a, b
      UNWIND ['a,b', 'a,b'] AS str
      WITH a, b, split(str, ',') AS roles
      MERGE (a)-[r:FB {foobar: roles}]->(b)
      RETURN count(*)
      """
    Then the result should be, in any order:
      | count(*) |
      | 2        |
    And the side effects should be:
      | +nodes         | 2 |
      | +relationships | 1 |
      | +labels        | 2 |
      | +properties    | 1 |

  Scenario: Matching using list property
    Given an empty graph
    And having executed:
      """
      CREATE (a:A), (b:B)
      CREATE (a)-[:T {numbers: [42, 43]}]->(b)
      """
    When executing query:
      """
      MATCH (a:A), (b:B)
      MERGE (a)-[r:T {numbers: [42, 43]}]->(b)
      RETURN count(*)
      """
    Then the result should be, in any order:
      | count(*) |
      | 1        |
    And no side effects

  Scenario: Aliasing of existing nodes 1
    Given an empty graph
    And having executed:
      """
      CREATE ({id: 0})
      """
    When executing query:
      """
      MATCH (n)
      MATCH (m)
      WITH n AS a, m AS b
      MERGE (a)-[r:T]->(b)
      RETURN a.id AS a, b.id AS b
      """
    Then the result should be, in any order:
      | a | b |
      | 0 | 0 |
    And the side effects should be:
      | +relationships | 1 |

  Scenario: Aliasing of existing nodes 2
    Given an empty graph
    And having executed:
      """
      CREATE ({id: 0})
      """
    When executing query:
      """
      MATCH (n)
      WITH n AS a, n AS b
      MERGE (a)-[r:T]->(b)
      RETURN a.id AS a
      """
    Then the result should be, in any order:
      | a |
      | 0 |
    And the side effects should be:
      | +relationships | 1 |

  Scenario: Double aliasing of existing nodes 1
    Given an empty graph
    And having executed:
      """
      CREATE ({id: 0})
      """
    When executing query:
      """
      MATCH (n)
      MATCH (m)
      WITH n AS a, m AS b
      MERGE (a)-[:T]->(b)
      WITH a AS x, b AS y
      MERGE (a)
      MERGE (b)
      MERGE (a)-[:T]->(b)
      RETURN x.id AS x, y.id AS y
      """
    Then the result should be, in any order:
      | x | y |
      | 0 | 0 |
    And the side effects should be:
      | +relationships | 1 |

  Scenario: Double aliasing of existing nodes 2
    Given an empty graph
    And having executed:
      """
      CREATE ({id: 0})
      """
    When executing query:
      """
      MATCH (n)
      WITH n AS a
      MERGE (c)
      MERGE (a)-[:T]->(c)
      WITH a AS x
      MERGE (c)
      MERGE (x)-[:T]->(c)
      RETURN x.id AS x
      """
    Then the result should be, in any order:
      | x |
      | 0 |
    And the side effects should be:
      | +relationships | 1 |

  @NegativeTest
  Scenario: Fail when imposing new predicates on a variable that is already bound
    Given any graph
    When executing query:
      """
      CREATE (a:Foo)
      MERGE (a)-[r:KNOWS]->(a:Bar)
      """
    Then a SyntaxError should be raised at compile time: VariableAlreadyBound