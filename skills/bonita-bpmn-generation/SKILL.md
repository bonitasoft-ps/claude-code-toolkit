---
name: bonita-bpmn-generation
description: |
  Generate Bonita .proc files (BPMN 2.0 + Bonita extensions) from process descriptions.
  Covers namespaces, lanes, gateways, timer events, contracts, process variables, and validation.
  Keywords: BPMN, .proc, XML, process, pool, lane, gateway, timer, contract, generation
allowed-tools: Read, Write, Grep, Glob, Bash
user-invocable: true
---

# BPMN Generation for Bonita

Generate valid `.proc` files (BPMN 2.0 + Bonita extensions) from natural language descriptions.

## When activated

1. **Gather required inputs** — process name, version, actors, steps, flows
2. **Generate the XML** following all rules below
3. **Validate** against the checklist before returning

---

## Required inputs before generating

1. **Process name** — PascalCase, no spaces (`LeaveApproval`, not `Leave Approval`)
2. **Version** — e.g. `1.0`
3. **Actors** — exhaustive list of human actors (e.g. Employee, Manager, HR)
4. **Steps** — each step with: id, name, type, actor (if human task)
5. **Flows** — all sequence flows, including conditions for XOR gateways

Ask the user for any missing item before generating.

---

## Key Bonita BPMN namespaces

```xml
xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xmlns:activiti="http://activiti.org/bpmn"
xmlns:bonita="http://bonitasoft.com/ns/process/client/7.x"
```

## Mandatory root structure

```xml
<?xml version="1.0" encoding="UTF-8"?>
<definitions
  xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:activiti="http://activiti.org/bpmn"
  xmlns:bonita="http://bonitasoft.com/ns/process/client/7.x"
  targetNamespace="http://bonitasoft.com/{ProcessName}/{Version}">

  <collaboration id="Collaboration_{ProcessName}">
    <participant id="pool_{ActorName}" name="{ActorName}" processRef="{ProcessName}"/>
  </collaboration>

  <process id="{ProcessName}" name="{Process Display Name}" isExecutable="true">
    <laneSet id="laneSet1">
      <lane id="lane_{ActorName}" name="{ActorName}">
        <flowNodeRef>{stepId}</flowNodeRef>
      </lane>
    </laneSet>
  </process>

  <bpmndi:BPMNDiagram>...</bpmndi:BPMNDiagram>
</definitions>
```

---

## Generation rules

### Rule 1 — Every process MUST have
- Exactly one `startEvent`
- At least one `endEvent`
- All elements connected (no disconnected nodes)
- Every `humanTask` assigned to a lane (actor)

### Rule 2 — Human task attributes
```xml
<userTask id="reviewRequest" name="Review Request"
          activiti:assignee="${reviewer}"
          activiti:candidateGroups="{ActorName}">
  <documentation>Task description here</documentation>
  <extensionElements>
    <bonita:contract>
      <!-- form contract variables -->
    </bonita:contract>
  </extensionElements>
</userTask>
```

### Rule 3 — XOR Gateway conditions
Conditions go on **outgoing sequence flows**, NOT on the gateway:
```xml
<exclusiveGateway id="gw_approved" name="Approved?" default="flow_rejected"/>
<sequenceFlow id="flow_approved" sourceRef="gw_approved" targetRef="notifyApproval">
  <conditionExpression xsi:type="tFormalExpression">${approved == true}</conditionExpression>
</sequenceFlow>
<sequenceFlow id="flow_rejected" sourceRef="gw_approved" targetRef="notifyRejection"/>
```

### Rule 4 — Timer boundary events
```xml
<boundaryEvent id="timer_reminder" attachedToRef="reviewRequest" cancelActivity="false">
  <timerEventDefinition>
    <timeDuration xsi:type="tFormalExpression">PT24H</timeDuration>
  </timerEventDefinition>
</boundaryEvent>
```

### Rule 5 — Unique IDs
- Pattern: `{stepType}_{stepName}` e.g. `task_reviewRequest`, `gw_approvalDecision`
- Flow IDs: `flow_{from}_{to}` e.g. `flow_reviewRequest_approvalGateway`

### Rule 6 — Bonita process variables
```xml
<process id="LeaveApproval" ...>
  <extensionElements>
    <bonita:processVariables>
      <bonita:processVariable name="approved" type="java.lang.Boolean" defaultValue="false"/>
      <bonita:processVariable name="comment" type="java.lang.String"/>
    </bonita:processVariables>
  </extensionElements>
</process>
```

---

## Validation checklist

Before returning any generated BPMN, verify:
- [ ] XML is well-formed (all tags closed)
- [ ] `startEvent` exists and has exactly one outgoing flow
- [ ] At least one `endEvent` exists with no outgoing flows
- [ ] All `humanTask` elements have an actor assigned and appear in a lane
- [ ] All `sequenceFlow` `sourceRef` and `targetRef` reference existing element IDs
- [ ] XOR gateways have conditions on outgoing flows (not on the gateway itself)
- [ ] No duplicate IDs in the document
- [ ] `targetNamespace` follows `http://bonitasoft.com/{name}/{version}`

---

## Common errors to avoid

| Error | Wrong | Correct |
|-------|-------|---------|
| Condition on gateway | `<exclusiveGateway condition="...">` | Condition on sequenceFlow |
| Missing actor | `<userTask>` without lane | Assign to lane via `<flowNodeRef>` |
| Wrong namespace | Omitting `activiti:` prefix | Always include activiti namespace |
| Spaces in ID | `id="review request"` | `id="reviewRequest"` |
| Missing default flow | XOR gateway without default | Always set `default=` attribute |

---

## Reference examples

See `bonita-bpmn-generator-toolkit/examples/` for validated examples.
