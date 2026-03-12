---
name: bonita-mutation-testing
description: |
  Mutation testing with PIT/pitest (Java) and Stryker (JavaScript). Measures test effectiveness
  by introducing code mutations. Use when verifying test quality, improving test suites, or
  setting quality gates in CI/CD. Minimum threshold: 80% mutation score.
  Trigger: "mutation test", "pitest", "PIT", "stryker", "mutation score", "test quality"
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
user_invocable: true
---

# Mutation Testing for Bonita

## Concept
Mutation testing modifies your code (mutants) and runs tests. If tests fail = mutant killed (good).
If tests pass = mutant survived (your tests missed something).

**Target: 80%+ mutation score** (killed / total mutants).

## Java — PIT (pitest)

### Maven Plugin
```xml
<plugin>
    <groupId>org.pitest</groupId>
    <artifactId>pitest-maven</artifactId>
    <version>1.15.8</version>
    <dependencies>
        <dependency>
            <groupId>org.pitest</groupId>
            <artifactId>pitest-junit5-plugin</artifactId>
            <version>1.2.1</version>
        </dependency>
    </dependencies>
    <configuration>
        <targetClasses>
            <param>com.bonitasoft.ps.*</param>
        </targetClasses>
        <excludedClasses>
            <param>*DTO</param>
            <param>*Config</param>
            <param>*Constants</param>
        </excludedClasses>
        <mutationThreshold>80</mutationThreshold>
        <outputFormats>
            <outputFormat>HTML</outputFormat>
            <outputFormat>XML</outputFormat>
        </outputFormats>
    </configuration>
</plugin>
```

### Run
```bash
mvn org.pitest:pitest-maven:mutationCoverage
```
Report: `target/pit-reports/index.html`

### What to Mutate
| Mutate | Don't Mutate |
|--------|-------------|
| Business logic | DTOs / Records |
| Validators | Constants classes |
| Service classes | Configuration |
| Connector logic | Generated code |
| Filter logic | Test utilities |

### Common Survived Mutants & How to Kill Them
| Mutant Type | Example | Fix |
|-------------|---------|-----|
| Negated conditional | `if (x > 0)` → `if (x <= 0)` | Add test for boundary |
| Changed return value | `return true` → `return false` | Assert return value |
| Removed method call | `list.add(x)` removed | Assert side effect |
| Changed math operator | `a + b` → `a - b` | Assert exact result |
| Changed equality | `==` → `!=` | Test both equal and not-equal |

## JavaScript — Stryker

### Setup
```bash
npm install --save-dev @stryker-mutator/core @stryker-mutator/jest-runner
npx stryker init
```

### stryker.config.mjs
```javascript
export default {
    mutator: {
        excludedMutations: ['StringLiteral']
    },
    testRunner: 'jest',
    reporters: ['html', 'clear-text', 'progress'],
    thresholds: { high: 90, low: 80, break: 75 },
    mutate: [
        'src/**/*.js',
        '!src/**/*.test.js',
        '!src/**/dto/**',
        '!src/**/config/**'
    ]
};
```

### Run
```bash
npx stryker run
```
Report: `reports/mutation/html/index.html`

## CI/CD Integration

### Maven (GitHub Actions)
```yaml
- name: Mutation Testing
  run: mvn org.pitest:pitest-maven:mutationCoverage -B
- name: Check Mutation Score
  run: |
    score=$(grep -oP 'mutation score: \K[0-9]+' target/pit-reports/*/mutations.xml || echo "0")
    if [ "$score" -lt 80 ]; then
      echo "Mutation score $score% below 80% threshold"
      exit 1
    fi
```

### npm (GitHub Actions)
```yaml
- name: Mutation Testing
  run: npx stryker run
```

## When to Run
- Before PR merge (quality gate)
- After adding new features (verify new tests are effective)
- Periodically (weekly) on main branch
- NOT on every commit (too slow for CI)
