---
name: bonita-e2e-testing
description: |
  End-to-end testing with Playwright against running Bonita server. Tests complete user flows:
  login, process instantiation, task execution, form submission, dashboard verification.
  Use for UI Builder pages, React forms, Living Applications, and process flow validation.
  Trigger: "e2e test", "playwright", "end to end", "browser test", "UI test", "flow test"
allowed-tools: Read, Grep, Glob, Edit, Write, Bash, mcp__playwright__browser_navigate, mcp__playwright__browser_snapshot, mcp__playwright__browser_click, mcp__playwright__browser_fill_form
user_invocable: true
---

# End-to-End Testing with Playwright for Bonita

## Setup

### Dependencies
```bash
npm install --save-dev @playwright/test
npx playwright install chromium
```

### Bonita Docker (prerequisite)
Use `bonita-runtime-toolkit` to start a Bonita instance:
- `runtime-start-bonita` skill or Docker Compose directly
- Default: http://localhost:8080/bonita
- Credentials: install/install (admin)

## Authentication Pattern

### Login
```typescript
async function loginToBonita(page: Page, user = 'install', pass = 'install') {
    await page.goto('http://localhost:8080/bonita/login.jsp');
    await page.fill('#username', user);
    await page.fill('#password', pass);
    await page.click('#submitButton');
    await page.waitForURL('**/portal/**');
}
```

### CSRF Token (for API calls within tests)
```typescript
async function getCsrfToken(page: Page): Promise<string> {
    const response = await page.request.get('http://localhost:8080/bonita/API/session/unusedId');
    return response.headers()['x-bonita-api-token'];
}
```

## Test Patterns

### Process Instantiation
```typescript
test('should start a new case', async ({ page }) => {
    await loginToBonita(page);
    await page.goto('http://localhost:8080/bonita/portal/form/process/MyProcess/1.0');
    await page.fill('[data-testid="firstName"]', 'John');
    await page.fill('[data-testid="lastName"]', 'Doe');
    await page.click('[data-testid="submit"]');
    await expect(page.locator('.confirmation')).toBeVisible();
});
```

### Task Execution
```typescript
test('should execute pending task', async ({ page }) => {
    await loginToBonita(page);
    await page.goto('http://localhost:8080/bonita/portal/tasklist');
    await page.click('text=Review Request');
    await page.fill('[data-testid="decision"]', 'approved');
    await page.click('[data-testid="submit"]');
    await expect(page.locator('.task-completed')).toBeVisible();
});
```

### Dashboard Verification
```typescript
test('should display KPIs', async ({ page }) => {
    await loginToBonita(page);
    await page.goto('http://localhost:8080/bonita/apps/myapp/dashboard');
    await expect(page.locator('[data-testid="open-cases"]')).toHaveText(/\d+/);
    await expect(page.locator('[data-testid="pending-tasks"]')).toHaveText(/\d+/);
});
```

### REST API Verification
```typescript
test('should return data from REST API extension', async ({ page }) => {
    await loginToBonita(page);
    const csrfToken = await getCsrfToken(page);
    const response = await page.request.get(
        'http://localhost:8080/bonita/API/extension/myapi?p=0&c=10',
        { headers: { 'X-Bonita-API-Token': csrfToken } }
    );
    expect(response.status()).toBe(200);
    const data = await response.json();
    expect(data.length).toBeGreaterThan(0);
});
```

## Visual Regression
```typescript
test('should match dashboard screenshot', async ({ page }) => {
    await loginToBonita(page);
    await page.goto('http://localhost:8080/bonita/apps/myapp/dashboard');
    await expect(page).toHaveScreenshot('dashboard.png', { maxDiffPixels: 100 });
});
```

## CI/CD Integration
```yaml
- name: Start Bonita
  run: docker compose -f docker/docker-compose.bonita-h2.yml up -d
- name: Wait for Bonita
  run: |
    for i in $(seq 1 30); do
      curl -s http://localhost:8080/bonita/login.jsp && break
      sleep 5
    done
- name: Run E2E Tests
  run: npx playwright test
- name: Stop Bonita
  run: docker compose -f docker/docker-compose.bonita-h2.yml down
```

## Best Practices
- Always clean state between tests (create fresh cases)
- Use data-testid attributes for selectors (not CSS classes)
- Set reasonable timeouts (Bonita can be slow to start)
- Run against H2 for speed, PostgreSQL for production-like behavior
- Capture screenshots on failure for debugging
