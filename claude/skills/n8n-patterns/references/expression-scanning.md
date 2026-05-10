# Expression Scanning

When you change a node's output schema, every downstream expression that references those fields is a potential breakage. Before patching a HIGH-risk node, scan downstream node parameters recursively for any of these patterns.

## Patterns to Search

Scan every string parameter in every downstream node for any of:

- `$json` — references the current item's JSON
- `$node[` — references a specific node's output by name (legacy syntax)
- `$('NodeName')` — references a specific node's output by name (modern syntax)
- `$items(` — references all items from a node
- `$item` — single item reference
- `$input` — references the input to the current node
- `$binary` — references binary data attached to an item

## Field-Level References

Within those patterns, dig into specific field references:

| Pattern | Meaning | Breaks if |
|---|---|---|
| `$json.foo` | Read field `foo` from current item | `foo` is renamed or removed |
| `$json["foo"]` | Same as above, bracket syntax | Same |
| `$json.foo.bar` | Nested field access | `foo` or `bar` is renamed/removed, or `foo` becomes null |
| `$json.foo[0]` | Array index access | `foo` becomes empty or non-array |
| `$node["Some Node"].json.foo` | Cross-node reference | Source node is renamed, or `foo` is renamed |
| `$('Some Node').item.json.foo` | Modern cross-node single-item ref | Source node is renamed, or `foo` is renamed |
| `$('Some Node').all()` | All items from source node | Source node is renamed |
| `$('Some Node').first().json.foo` | First item from source | Source renamed, or no items, or `foo` renamed |
| `$items("Some Node")` | All items (legacy) | Source node is renamed |

## Where Expressions Hide

Expressions can appear in any string parameter on any node. Common locations:

- **Set/Edit Fields**: `parameters.values.string[].value`, `parameters.values.number[].value`, `parameters.assignments.assignments[].value`
- **HTTP Request**: `parameters.url`, `parameters.body`, `parameters.headerParameters.parameters[].value`, `parameters.queryParameters.parameters[].value`
- **IF / Switch**: `parameters.conditions.conditions[].leftValue` and `.rightValue`
- **Code**: `parameters.jsCode` (the entire script body — references can be anywhere in code)
- **Postgres / SQL**: `parameters.query`, `parameters.values` (be careful: parameter substitution is *meant* for this; expressions in the query body are different)
- **Discord / Telegram / Slack / Email**: `parameters.text`, `parameters.message`, `parameters.subject`, `parameters.body`
- **Merge**: `parameters.propertyName1`, `parameters.propertyName2`

## Detection Strategy

When given a workflow JSON and a node about to be edited:

1. Get the **transitive downstream set** for the target node (all nodes reachable by following `connections`).
2. For each downstream node, walk every string parameter recursively.
3. Match any of the patterns above.
4. For each match, extract:
   ```json
   {
     "node": "Send Alert",
     "parameterPath": "parameters.text",
     "expression": "={{ $json.dividendScore }}",
     "references": ["$json.dividendScore"]
   }
   ```
5. For each `$json.X` reference, check whether the current edit changes field `X`. If yes, that's a confirmed break point — the patch must update the reference too, or surface the impact to Dave.

## Code Node Special Handling

Code nodes are free-form JavaScript. Search the entire `parameters.jsCode` string for:
- Field accesses: `item.json.foo`, `items[i].json.foo`
- Direct destructuring: `const { foo } = item.json`
- String templates: `` `${item.json.foo}` ``
- Bracket access: `item.json["foo"]`

Code nodes are the highest false-negative risk for expression scanning — patterns can be obscured. When upstream schema changes, **always read every downstream Code node's full body**, not just grep for specific patterns.

## Renaming a Node

If a request requires renaming a node (e.g., "rename `Fetch News` to `Fetch Articles`"), every reference of the form `$node["Fetch News"].*` and `$('Fetch News').*` across the entire workflow must be updated.

A node-rename patch must include:
1. The rename itself (in the node object)
2. Updates to every `connections` entry that uses the old name as a key or target
3. Updates to every expression in every other node that references the old name

A "rename" patch that only touches the node object is **incomplete and will silently break the workflow**.
