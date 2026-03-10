---
name: bonita-ui-form-generation
description: |
  Generate React forms and dashboards for Bonita Living Applications.
  Covers Bonita REST API, CSRF tokens, form types, Tailwind CSS, Living App packaging.
  Keywords: UI, form, React, Living App, dashboard, REST API, CSRF, Tailwind, generation
allowed-tools: Read, Write, Grep, Glob, Bash
user-invocable: true
---

# UI Form Generation for Bonita

Generate React forms and dashboards packaged as Bonita Living Applications.

## When activated

1. **Identify form type** — instantiation, task, or summary
2. **Generate the React component** with Bonita API integration
3. **Generate packaging** — page.properties + index.html + app.js
4. **Validate** against the checklist

---

## Bonita REST API auth from frontend

```javascript
// In Living App context, user is already logged in
// CSRF token is in the cookie 'X-Bonita-API-Token'
const token = document.cookie
  .split('; ')
  .find(r => r.startsWith('X-Bonita-API-Token='))
  ?.split('=')[1] || '';
```

All POST/PUT requests need the CSRF token header:
```javascript
headers: { 'X-Bonita-API-Token': csrfToken }
```

---

## Form types

| Type | Purpose | Submit endpoint |
|------|---------|----------------|
| Instantiation | Start a process | `/API/bpm/process/{id}/instantiation` |
| Task | Complete a human task | `/API/bpm/userTask/{taskId}/execution` |
| Summary | Read-only case data | No submit |

---

## Form generation rules

### Rule 1 — Always handle loading and error states
```jsx
const [loading, setLoading] = useState(false);
const [error, setError] = useState(null);
const [success, setSuccess] = useState(false);
```

### Rule 2 — Tailwind CSS only (no custom CSS files)
Use core Tailwind classes: `flex`, `grid`, `gap-4`, `p-4`, `border`, `rounded`, `bg-blue-600`

### Rule 3 — Form validation before submit
```jsx
const validate = (values) => {
  const errors = {};
  if (!values.startDate) errors.startDate = 'Required';
  if (values.endDate < values.startDate) errors.endDate = 'Must be after start date';
  return errors;
};
```

### Rule 4 — No hardcoded URLs
Always use relative paths: `/bonita/API/...`

---

## Living App packaging structure

```
{AppName}.zip
├── page.properties           # MANDATORY
└── resources/
    ├── index.html            # Entry point
    ├── app.js                # React (CDN, no build step)
    └── css/
        └── tailwind.min.css  # Optional (or CDN script tag)
```

### page.properties
```properties
name={AppName}
displayName={App Display Name}
description=Bonita Living Application
contentType=page
resources=[GET|living/application,GET|living/application-page,GET|living/application-menu]
```

### index.html (CDN approach)
```html
<!DOCTYPE html>
<html>
<head>
  <script src="https://unpkg.com/react@18/umd/react.production.min.js"></script>
  <script src="https://unpkg.com/react-dom@18/umd/react-dom.production.min.js"></script>
  <script src="https://cdn.tailwindcss.com"></script>
</head>
<body>
  <div id="root"></div>
  <script src="app.js"></script>
</body>
</html>
```

---

## Validation checklist

- [ ] Form handles all 3 states: loading, error, success
- [ ] CSRF token included in all POST/PUT requests
- [ ] Required field validation before submit
- [ ] Task ID read from URL params or Bonita context variable
- [ ] No hardcoded URLs — use relative paths `/bonita/...`
- [ ] `page.properties` has correct `contentType=page`
