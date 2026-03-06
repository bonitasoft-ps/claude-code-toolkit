# Evaluation Templates for Prompt Quality

Reference document for the prompt-quality-advisor skill. Load when the user needs to create eval rubrics or grading prompts.

## 1. Model-Based Grading Template

```xml
<instructions>
You are an expert evaluator. Grade the following response based on the rubric.
Provide your reasoning BEFORE the score.
</instructions>

<original_input>
{{ORIGINAL_INPUT}}
</original_input>

<response_to_grade>
{{MODEL_RESPONSE}}
</response_to_grade>

<rubric>
Score from 1 to 5:

5 - Excellent: [specific criteria for 5]
4 - Good: [specific criteria for 4]
3 - Adequate: [specific criteria for 3]
2 - Poor: [specific criteria for 2]
1 - Very Poor: [specific criteria for 1]

Evaluate on these dimensions:
- Accuracy: Are all facts correct?
- Completeness: Are all required elements present?
- Format: Does it match the expected structure?
- Tone: Is it appropriate for the audience?
</rubric>

<output_format>
Respond with ONLY this JSON:
{
  "reasoning": "Brief analysis of strengths and weaknesses",
  "accuracy": 1-5,
  "completeness": 1-5,
  "format": 1-5,
  "tone": 1-5,
  "overall": 1-5
}
</output_format>
```

## 2. Classification Eval Template

```python
# Test dataset structure
test_cases = [
    {
        "input": "I can't log into my account",
        "expected": "account",
        "category": "typical",
        "difficulty": "easy"
    },
    {
        "input": "I want to upgrade and also fix a bug",
        "expected": "billing",  # Primary intent
        "category": "edge_case",
        "difficulty": "hard",
        "notes": "Multi-intent, primary is billing"
    }
]

# Code-based grading
def grade_classification(output, expected):
    return {
        "exact_match": output.strip().lower() == expected.lower(),
        "valid_category": output.strip().lower() in VALID_CATEGORIES,
        "no_extra_text": len(output.split()) <= 2
    }
```

## 3. Summarization Eval Rubric

```
SUMMARIZATION QUALITY RUBRIC

5 - Excellent:
  - Captures ALL key points from the original
  - No hallucinated information
  - Appropriate length (within 10% of target)
  - Well-structured and readable
  - Could replace reading the original for a busy executive

4 - Good:
  - Captures MOST key points (>80%)
  - No hallucinations
  - Acceptable length (within 20% of target)
  - Readable and clear

3 - Adequate:
  - Captures the main idea but misses important details
  - No major hallucinations (minor inaccuracies OK)
  - Somewhat too long or too short
  - Readable but could be better organized

2 - Poor:
  - Misses key points or main idea is unclear
  - May contain minor inaccuracies
  - Significantly off target length
  - Poorly structured

1 - Very Poor:
  - Factually wrong or hallucinates information
  - Misses the main idea entirely
  - Incoherent or unusable
```

## 4. Code Generation Eval Template

```python
def grade_code_output(code_output, requirements):
    scores = {}

    # 1. Syntax validity
    try:
        compile(code_output, '<string>', 'exec')
        scores["syntax_valid"] = True
    except SyntaxError:
        scores["syntax_valid"] = False

    # 2. Required elements present
    for element in requirements.get("must_contain", []):
        scores[f"contains_{element}"] = element in code_output

    # 3. Forbidden patterns absent
    for pattern in requirements.get("must_not_contain", []):
        scores[f"avoids_{pattern}"] = pattern not in code_output

    # 4. Length compliance
    lines = code_output.strip().split('\n')
    max_lines = requirements.get("max_lines", 100)
    scores["length_ok"] = len(lines) <= max_lines

    return scores
```

## 5. Structured Output Eval Template

```python
import json

def grade_structured_output(output, schema):
    """Grade JSON output against expected schema."""
    scores = {}

    # Parse JSON
    try:
        data = json.loads(output)
        scores["valid_json"] = True
    except json.JSONDecodeError:
        return {"valid_json": False, "overall": 0}

    # Required fields
    required = schema.get("required_fields", [])
    present = [f for f in required if f in data]
    scores["required_fields"] = len(present) / len(required) if required else 1.0

    # Field types
    for field, expected_type in schema.get("field_types", {}).items():
        if field in data:
            scores[f"type_{field}"] = isinstance(data[field], expected_type)

    # Value constraints
    for field, constraint in schema.get("constraints", {}).items():
        if field in data:
            if "min" in constraint:
                scores[f"min_{field}"] = data[field] >= constraint["min"]
            if "max" in constraint:
                scores[f"max_{field}"] = data[field] <= constraint["max"]
            if "enum" in constraint:
                scores[f"enum_{field}"] = data[field] in constraint["enum"]

    return scores
```

## 6. Combined Eval Pipeline

```python
def run_full_eval(prompt, test_dataset, grading_config):
    """Run a complete eval pipeline: code + model grading."""
    results = []

    for test in test_dataset:
        # Get model response
        response = call_claude(prompt, test["input"])

        # Code-based checks
        code_scores = {}
        for check_name, check_fn in grading_config["code_checks"].items():
            code_scores[check_name] = check_fn(response, test)

        # Model-based grading (only if code checks pass)
        model_score = None
        if all(code_scores.values()):
            model_score = grade_with_model(
                test["input"],
                response,
                grading_config["rubric"]
            )

        results.append({
            "input": test["input"],
            "expected": test.get("expected"),
            "actual": response,
            "code_scores": code_scores,
            "model_score": model_score
        })

    return results
```

## 7. A/B Eval Template (Comparing Prompts)

```python
def compare_prompts(prompt_a, prompt_b, test_dataset, rubric):
    """Compare two prompt versions on the same test data."""
    results_a = run_eval(prompt_a, test_dataset)
    results_b = run_eval(prompt_b, test_dataset)

    comparison = {
        "prompt_a_accuracy": calculate_accuracy(results_a),
        "prompt_b_accuracy": calculate_accuracy(results_b),
        "improvements": [],  # Cases where B is better
        "regressions": [],   # Cases where B is worse
        "unchanged": []      # Same result
    }

    for ra, rb in zip(results_a, results_b):
        if rb["score"] > ra["score"]:
            comparison["improvements"].append((ra, rb))
        elif rb["score"] < ra["score"]:
            comparison["regressions"].append((ra, rb))
        else:
            comparison["unchanged"].append((ra, rb))

    return comparison
```

## Best Practices for Evals

1. **Define criteria BEFORE writing tests** — know what "good" looks like first
2. **Start with 20-50 test cases** — 10-20% edge cases
3. **Code-based first** — fast, free, catches obvious failures
4. **Model-based second** — for nuanced quality assessment
5. **Human validation last** — gold standard for a sample
6. **Change ONE thing at a time** — when iterating on the prompt
7. **Version your test datasets** — they evolve with your prompt
8. **Track metrics over time** — catch regressions early
