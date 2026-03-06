# Advanced Prompt Engineering Techniques

Reference document for the prompt-quality-advisor skill. Load on demand when the user needs advanced techniques.

## 1. XML Tag Patterns

### Basic Structure
```xml
<instructions>
Your main task description here.
</instructions>

<context>
Background information Claude needs.
</context>

<input>
{{DYNAMIC_CONTENT}}
</input>

<output_format>
How to structure the response.
</output_format>
```

### Common Tag Names

| Tag | Purpose | When to use |
|-----|---------|-------------|
| `<instructions>` | Main task description | Always for complex prompts |
| `<context>` | Background information | When Claude needs domain knowledge |
| `<input>` | Dynamic data to process | When processing user-provided content |
| `<output_format>` | Response structure | When format consistency matters |
| `<constraints>` | Rules and limitations | When boundaries are important |
| `<examples>` | Input/output demonstrations | When format is critical |
| `<persona>` | Role definition | For conversational/support prompts |
| `<rubric>` | Evaluation criteria | For grading/eval prompts |

### Nested Tags for Complex Data
```xml
<examples>
  <example>
    <input>Customer says: "Your product broke after 2 days"</input>
    <ideal_response>I'm sorry to hear about this issue. Let me help you with a replacement...</ideal_response>
    <category>complaint</category>
  </example>
</examples>
```

### Variable Injection Pattern
```xml
<instructions>
Classify the support ticket below into one of: {{CATEGORIES}}.
Respond with JSON: {"category": "...", "confidence": 0.0-1.0, "reasoning": "..."}
</instructions>

<ticket>
{{TICKET_CONTENT}}
</ticket>
```

## 2. Few-Shot Prompting

### How Many Examples?

| Scenario | Examples needed | Why |
|----------|----------------|-----|
| Simple classification | 1-2 | Just show the format |
| Multi-category | 2-3 | One per category + edge case |
| Complex extraction | 3-4 | Show variations and edge cases |
| Nuanced judgment | 4-5 | Calibrate the evaluation scale |

### Few-Shot Template
```xml
<instructions>
Extract named entities from the text. Return JSON array.
</instructions>

<examples>
<example>
<input>Apple CEO Tim Cook announced the new iPhone in Cupertino.</input>
<output>[
  {"entity": "Apple", "type": "organization"},
  {"entity": "Tim Cook", "type": "person"},
  {"entity": "iPhone", "type": "product"},
  {"entity": "Cupertino", "type": "location"}
]</output>
</example>
<example>
<input>The weather in Paris is nice today.</input>
<output>[
  {"entity": "Paris", "type": "location"}
]</output>
</example>
<example>
<input>It was a beautiful morning.</input>
<output>[]</output>
</example>
</examples>

<input>
{{USER_TEXT}}
</input>
```

### Tips for Effective Examples

1. **Show the exact format** — Claude mirrors example formatting precisely
2. **Include an edge case** — empty result, ambiguous input, boundary case
3. **Keep examples concise** — realistic but not verbose
4. **Be consistent** — all examples must follow the same format
5. **Order matters** — put the simplest example first, edge case last

## 3. Chain of Thought (CoT)

### When to Use
- Complex reasoning tasks
- Math or logic problems
- Multi-step analysis
- When you need to audit the reasoning

### Basic Pattern
```xml
<instructions>
Analyze the following business scenario and recommend a strategy.

Think through this step by step:
1. Identify the key factors
2. Analyze each factor's impact
3. Consider trade-offs
4. Make your recommendation with justification
</instructions>
```

### Explicit CoT with Tags
```xml
<instructions>
Solve the problem below. Show your work.
</instructions>

<output_format>
<thinking>
[Your step-by-step reasoning here]
</thinking>

<answer>
[Final answer only]
</answer>
</output_format>
```

## 4. Prefill Technique (API Only)

Force structured output by starting Claude's response:

```python
messages = [
    {"role": "user", "content": "Extract entities from: 'Tim Cook visited Paris'"},
    {"role": "assistant", "content": "{"}  # Forces JSON output
]
# Combined with stop_sequences: ["}"] to get clean JSON
```

### When to Use Prefill
- JSON output enforcement
- Starting a specific format (table, list)
- Preventing preamble ("Sure! Here's...")
- Category/label extraction

## 5. System Prompt vs User Prompt

### What Goes Where

| Content | System Prompt | User Prompt |
|---------|:---:|:---:|
| Persona/role definition | X | |
| Permanent rules | X | |
| Output format spec | X | |
| Domain knowledge | X | |
| Dynamic input data | | X |
| Per-request instructions | | X |
| Conversation context | | X |
| User-provided documents | | X |

### System Prompt Template
```
You are a [ROLE] specializing in [DOMAIN].

## Rules
- Always respond in [LANGUAGE]
- Keep responses under [LENGTH]
- Use [FORMAT] for structured data
- Never [RESTRICTION]

## Context
[DOMAIN_KNOWLEDGE]

## Output Format
[STRUCTURE_SPEC]
```

## 6. Meta-Prompting

Ask Claude to help write the prompt itself:

```xml
<instructions>
I need a prompt for the following task. Write an optimized prompt
that includes XML tags, clear instructions, and output format.

Task: {{TASK_DESCRIPTION}}
Target audience: {{AUDIENCE}}
Expected output: {{OUTPUT_TYPE}}

The prompt should follow these best practices:
- Use XML tags for structure
- Include 2-3 few-shot examples
- Define output format explicitly
- Handle edge cases
</instructions>
```

## 7. Iterative Refinement Workflow

```
Step 1: DRAFT — Write initial prompt based on requirements
Step 2: TEST — Run with 5-10 diverse inputs (include edge cases)
Step 3: EVALUATE — Score outputs on accuracy, format, completeness
Step 4: REFINE — Change ONE thing at a time
Step 5: REPEAT — Until consistently meeting quality targets
```

### What to Change (Priority Order)

1. **Instructions** — Are they clear and complete?
2. **Examples** — Do they show what you really want?
3. **Format spec** — Is the output structure precise enough?
4. **Constraints** — Are edge cases handled?
5. **Context** — Does Claude have all needed information?

## 8. Temperature Guidelines

| Use Case | Temperature | Why |
|----------|:-----------:|-----|
| Classification, extraction | 0.0 | Deterministic, consistent |
| Factual Q&A | 0.0-0.3 | Accuracy over creativity |
| General writing | 0.5-0.7 | Balance of quality and variation |
| Creative writing, brainstorming | 0.8-1.0 | Maximum diversity |
| Code generation | 0.0-0.2 | Correctness matters most |

## 9. Prompt Anti-Patterns

### 1. The Kitchen Sink
**Problem**: Prompt tries to do too many things at once.
**Fix**: Split into multiple focused prompts or use a pipeline.

### 2. The Invisible Format
**Problem**: User expects specific format but doesn't say so.
**Fix**: Always specify output format explicitly.

### 3. The Negative Nelly
**Problem**: "Don't be verbose. Don't use jargon. Don't give opinions."
**Fix**: State what you WANT: "Be concise. Use plain language. Present facts only."

### 4. The Context Desert
**Problem**: "Analyze this data" with no background on what matters.
**Fix**: Add context: "You are analyzing sales data for Q1. Focus on trends that affect inventory planning."

### 5. The One-Shot Wonder
**Problem**: Testing a prompt once and deploying it.
**Fix**: Test with 20+ inputs including edge cases before deployment.

### 6. The Token Burner
**Problem**: Repeating the same context in every user message.
**Fix**: Put static context in system prompt. Dynamic content in user messages.
