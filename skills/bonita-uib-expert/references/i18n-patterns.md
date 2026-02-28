# Internationalization (i18n) Patterns

> Bonita Version: 2024.3+
> Use `function()` syntax — NEVER use arrow functions `() =>`

## Overview

Bonita UI Builder uses a JSObject-based i18n approach:
- Each page has a `JSI18n` JSObject with translation dictionaries
- Widgets reference translations via `{{JSI18n.t('key')}}`
- Languages: EN (default), FR, ES (extensible)
- Language detection automatic via `appsmith.store.locale`

## JSI18n Template

**Location:** `pages/[PageName]/jsobjects/JSI18n/JSI18n.js`

```javascript
export default {
  translations: {
    en: {
      // Page
      "page.title": "Page Title",
      "page.subtitle": "Page subtitle description",

      // Form labels
      "form.name": "Name",
      "form.email": "Email",
      "form.amount": "Amount",
      "form.date": "Date",
      "form.comment": "Comment",
      "form.status": "Status",

      // Form placeholders
      "form.namePlaceholder": "Enter name",
      "form.emailPlaceholder": "Enter email",
      "form.amountPlaceholder": "Enter amount",

      // Table headers
      "table.name": "Name",
      "table.amount": "Amount",
      "table.status": "Status",
      "table.date": "Date",
      "table.actions": "Actions",

      // Status values
      "status.draft": "Draft",
      "status.submitted": "Submitted",
      "status.approved": "Approved",
      "status.rejected": "Rejected",
      "status.completed": "Completed",
      "status.cancelled": "Cancelled",

      // Actions
      "actions.submit": "Submit",
      "actions.save": "Save",
      "actions.cancel": "Cancel",
      "actions.delete": "Delete",
      "actions.edit": "Edit",
      "actions.view": "View",
      "actions.back": "Back",
      "actions.next": "Next",
      "actions.previous": "Previous",
      "actions.search": "Search",
      "actions.refresh": "Refresh",
      "actions.confirm": "Confirm",
      "actions.approve": "Approve",
      "actions.reject": "Reject",

      // Messages
      "message.success": "Operation completed successfully",
      "message.error": "An error occurred",
      "message.loading": "Loading...",
      "message.noData": "No data found",
      "message.confirmDelete": "Are you sure you want to delete?",

      // Validation
      "validation.required": "This field is required",
      "validation.email": "Please enter a valid email",
      "validation.number": "Please enter a valid number",
      "validation.positive": "Value must be positive",
      "validation.minLength": "Minimum {0} characters required"
    },
    fr: {
      "page.title": "Titre de la page",
      "page.subtitle": "Description du sous-titre",
      "form.name": "Nom",
      "form.email": "Email",
      "form.amount": "Montant",
      "form.date": "Date",
      "form.comment": "Commentaire",
      "form.status": "Statut",
      "form.namePlaceholder": "Saisir le nom",
      "form.emailPlaceholder": "Saisir l'email",
      "form.amountPlaceholder": "Saisir le montant",
      "table.name": "Nom",
      "table.amount": "Montant",
      "table.status": "Statut",
      "table.date": "Date",
      "table.actions": "Actions",
      "status.draft": "Brouillon",
      "status.submitted": "Soumis",
      "status.approved": "Approuv\u00e9",
      "status.rejected": "Rejet\u00e9",
      "status.completed": "Termin\u00e9",
      "status.cancelled": "Annul\u00e9",
      "actions.submit": "Soumettre",
      "actions.save": "Enregistrer",
      "actions.cancel": "Annuler",
      "actions.delete": "Supprimer",
      "actions.edit": "Modifier",
      "actions.view": "Voir",
      "actions.back": "Retour",
      "actions.next": "Suivant",
      "actions.previous": "Pr\u00e9c\u00e9dent",
      "actions.search": "Rechercher",
      "actions.refresh": "Actualiser",
      "actions.confirm": "Confirmer",
      "actions.approve": "Approuver",
      "actions.reject": "Rejeter",
      "message.success": "Op\u00e9ration r\u00e9alis\u00e9e avec succ\u00e8s",
      "message.error": "Une erreur est survenue",
      "message.loading": "Chargement...",
      "message.noData": "Aucune donn\u00e9e trouv\u00e9e",
      "message.confirmDelete": "\u00cates-vous s\u00fbr de vouloir supprimer ?",
      "validation.required": "Ce champ est obligatoire",
      "validation.email": "Veuillez saisir un email valide",
      "validation.number": "Veuillez saisir un nombre valide",
      "validation.positive": "La valeur doit \u00eatre positive",
      "validation.minLength": "Minimum {0} caract\u00e8res requis"
    },
    es: {
      "page.title": "T\u00edtulo de la p\u00e1gina",
      "form.name": "Nombre",
      "form.email": "Correo electr\u00f3nico",
      "form.amount": "Monto",
      "actions.submit": "Enviar",
      "actions.save": "Guardar",
      "actions.cancel": "Cancelar",
      "actions.delete": "Eliminar",
      "status.draft": "Borrador",
      "status.submitted": "Enviado",
      "status.approved": "Aprobado",
      "status.rejected": "Rechazado",
      "status.completed": "Completado",
      "status.cancelled": "Cancelado",
      "message.success": "Operaci\u00f3n realizada con \u00e9xito",
      "message.error": "Se ha producido un error",
      "message.loading": "Cargando...",
      "message.noData": "No se encontraron datos"
    }
  },

  getCurrentLocale: function() {
    var locale = appsmith.store.locale;
    if (locale && this.translations[locale]) {
      return locale;
    }
    if (locale && locale.indexOf('-') > -1) {
      var lang = locale.split('-')[0];
      if (this.translations[lang]) {
        return lang;
      }
    }
    return 'en';
  },

  t: function(key) {
    var locale = this.getCurrentLocale();
    var value = this.translations[locale][key];
    if (value !== undefined) return value;
    var fallback = this.translations['en'][key];
    if (fallback !== undefined) return fallback;
    return '[' + key + ']';
  },

  tWithParams: function(key, params) {
    var text = this.t(key);
    if (params && text) {
      for (var i = 0; i < params.length; i++) {
        text = text.replace('{' + i + '}', params[i]);
      }
    }
    return text;
  },

  translateDynamicValue: function(value, prefix) {
    if (!value) return '';
    var key = prefix + '.' + value.toLowerCase();
    var translated = this.t(key);
    if (translated && translated.indexOf('[') !== 0) {
      return translated;
    }
    return value;
  }
}
```

### JSI18n metadata.json

```json
{
  "body": "export default {}",
  "contextType": "PAGE",
  "variables": []
}
```

## Usage in Widgets

### Static Text

```json
{
  "text": "{{JSI18n.t('page.title')}}",
  "dynamicBindingPathList": [{ "key": "text" }]
}
```

### Form Labels and Placeholders

```json
{
  "labelText": "{{JSI18n.t('form.name')}}",
  "placeholderText": "{{JSI18n.t('form.namePlaceholder')}}",
  "dynamicBindingPathList": [
    { "key": "labelText" },
    { "key": "placeholderText" }
  ]
}
```

### Table Column Labels

```json
{
  "primaryColumns": {
    "name": {
      "label": "{{JSI18n.t('table.name')}}",
      "dynamicBindingPathList": [{ "key": "label" }]
    }
  }
}
```

### Button Text

```json
{
  "text": "{{JSI18n.t('actions.submit')}}",
  "dynamicBindingPathList": [{ "key": "text" }]
}
```

### Dynamic Status Values

```json
{
  "text": "{{JSI18n.translateDynamicValue(currentRow.status, 'status')}}",
  "dynamicBindingPathList": [{ "key": "text" }]
}
```

### Parameterized Text

```json
{
  "text": "{{JSI18n.tWithParams('validation.minLength', ['5'])}}",
  "dynamicBindingPathList": [{ "key": "text" }]
}
```

## Key Naming Conventions

| Scope | Pattern | Examples |
|-------|---------|----------|
| Page-level | `page.[property]` | `page.title`, `page.subtitle` |
| Forms | `form.[fieldName]` | `form.name`, `form.email` |
| Placeholders | `form.[fieldName]Placeholder` | `form.namePlaceholder` |
| Tables | `table.[columnName]` | `table.name`, `table.amount` |
| Actions | `actions.[actionName]` | `actions.submit`, `actions.cancel` |
| Status | `status.[statusValue]` | `status.draft`, `status.approved` |
| Messages | `message.[messageType]` | `message.success`, `message.error` |
| Validation | `validation.[ruleName]` | `validation.required`, `validation.email` |

## Step-by-Step: Adding i18n to a New Page

1. Create `jsobjects/JSI18n/JSI18n.js` with the template above
2. Create `jsobjects/JSI18n/metadata.json` with empty variables
3. Replace all hardcoded strings in widgets with `{{JSI18n.t('key')}}`
4. Add appropriate keys to all language dictionaries
5. Declare `dynamicBindingPathList` entries for every translated property
6. Test with different locales via `storeValue('locale', 'fr')`

## Adding a New Language

1. Add a new key in the `translations` object (e.g., `de` for German)
2. Copy all keys from `en` and translate values
3. The `getCurrentLocale()` function auto-detects it

## Anti-patterns

- Using arrow functions in JSI18n (`() =>` instead of `function()`)
- Hardcoding text in widgets instead of `JSI18n.t()`
- Forgetting `dynamicBindingPathList` for translated properties
- Inconsistent key naming across pages
- Missing fallback locale handling
- Not translating SELECT_WIDGET option labels
- Translating contract field values (must match process definition exactly)
