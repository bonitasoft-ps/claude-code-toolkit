---
name: BPMN visualization in Claude.ai: always generate 3 artifacts (bpmn + svg + html)
description: "When a user requests BPMN process visualization inside Claude.ai Artifacts or as downloadable files, the correct output is always 3 complementary artifacts: (1) a .bpmn XML file for tool import, (2) a"
allowed-tools: []
user-invocable: true
---

# BPMN visualization in Claude.ai: always generate 3 artifacts (bpmn + svg + html)

> Auto-generated from learning proposal PROP-1773423475380-56c010

## Context
Claude.ai Artifact sandbox — BPMN Vacation Approval visualization session

## Description
When a user requests BPMN process visualization inside Claude.ai Artifacts or as downloadable files, the correct output is always 3 complementary artifacts: (1) a .bpmn XML file for tool import, (2) a .svg file for static embedding, and (3) a self-contained .html file with the SVG inline plus vanilla JS zoom/pan/toolbar. The HTML must never load bpmn-js or any library via CDN (unpkg.com is blocked in the Claude.ai sandbox). The SVG is reused inside the HTML — no duplication needed.

## Problem
Two separate problems: (1) bpmn-js loaded via CDN (unpkg.com) fails silently in Claude.ai sandbox with ReferenceError. (2) Generating only a .bpmn XML gives the user no visual — they need a viewer. Generating only SVG gives no interactivity. There was no consistent standard for what to generate.

## Solution
Always generate 3 files for any BPMN visualization request:
1. ProcessName.bpmn — standard BPMN 2.0 XML, importable in Bonita Studio, Camunda, Signavio, etc.
2. ProcessName.svg — pure inline SVG using standard primitives (rect, polygon, circle, polyline, text, marker). CSS classes for element types: .task-user (blue), .task-svc (green), .gw-exc (yellow), .evt-start (green), .evt-end (red). Color-coded conditional flows (green=Yes, red=No).
3. ProcessName.html — the SVG embedded inline inside an HTML shell with: header bar, zoom in/out/fit toolbar buttons, mouse wheel zoom, drag-to-pan, touch support. Zero external dependencies. Uses CSS transform scale+translate on the SVG element. All in a single file.
The skill name should be: bpmn-artifact-generator. Target toolkit: claude-code-toolkit.

## Steps
- Create skill: claude-code-toolkit/skills/bpmn-artifact-generator/SKILL.md
- Rule: never use bpmn-js CDN in Claude.ai Artifacts — embed SVG inline instead
- Rule: always output 3 files: .bpmn (XML) + .svg (static) + .html (interactive, SVG inline)
- Define CSS class palette for BPMN elements in SVG: pool, lane, userTask, serviceTask, exclusiveGateway, startEvent, endEvent
- Include reusable zoom/pan JS snippet in skill references/
- Document that unpkg.com is blocked; cdnjs.cloudflare.com is allowed if needed
- Fix skill name from 'bpmn-rendering-in-claudeai-artifacts-pure-svg-over' to 'bpmn-artifact-generator'

## References
- Category: skill
- Priority: high
