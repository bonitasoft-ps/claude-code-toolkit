# Code Patterns — List, Form, CRUD, Validation, Wizard

> Bonita Version: 2024.3+
> All functions use `function()` syntax — NEVER use arrow functions `() =>`

## List Pattern with Pagination

### metadata.json variables

```json
{
  "variables": [
    { "name": "data", "value": { "data": [] } },
    { "name": "totalCount", "value": { "data": 0 } },
    { "name": "currentPage", "value": { "data": 1 } },
    { "name": "pageSize", "value": { "data": 10 } },
    { "name": "isLoading", "value": { "data": false } },
    { "name": "searchText", "value": { "data": "" } },
    { "name": "sortColumn", "value": { "data": "" } },
    { "name": "sortOrder", "value": { "data": "ASC" } }
  ]
}
```

### JSEntityList.js

```javascript
export default {
  fetchData: function() {
    var self = this;
    self.isLoading.value = true;
    try {
      var page = self.currentPage - 1;
      var result = getEntityList.run({
        p: page,
        c: self.pageSize,
        s: self.searchText || '',
        o: self.sortColumn ? self.sortColumn + ' ' + self.sortOrder : ''
      });
      self.data.value = result;
      var countResult = getEntityCount.run({ s: self.searchText || '' });
      self.totalCount.value = Number(countResult) || 0;
    } catch(e) {
      self.data.value = [];
      self.totalCount.value = 0;
      showAlert('Error loading data: ' + e.message, 'error');
    } finally {
      self.isLoading.value = false;
    }
  },

  onPageChange: function(pageNo) {
    this.currentPage.value = pageNo;
    this.fetchData();
  },

  onSort: function(column, order) {
    this.sortColumn.value = column;
    this.sortOrder.value = order;
    this.currentPage.value = 1;
    this.fetchData();
  },

  onSearch: function(text) {
    this.searchText.value = text;
    this.currentPage.value = 1;
    this.fetchData();
  },

  getTotalPages: function() {
    return Math.ceil(this.totalCount / this.pageSize);
  }
}
```

## Form Pattern

### metadata.json variables

```json
{
  "variables": [
    { "name": "formData", "value": { "data": {} } },
    { "name": "errors", "value": { "data": {} } },
    { "name": "isSubmitting", "value": { "data": false } },
    { "name": "isDirty", "value": { "data": false } }
  ]
}
```

### JSEntityForm.js

```javascript
export default {
  initForm: function(entity) {
    this.formData.value = {
      field1: entity ? entity.field1 : '',
      field2: entity ? entity.field2 : '',
      amount: entity ? entity.amount : 0,
      status: entity ? entity.status : 'DRAFT'
    };
    this.errors.value = {};
    this.isDirty.value = false;
  },

  updateField: function(field, value) {
    var current = this.formData;
    var updated = {};
    var keys = Object.keys(current);
    for (var i = 0; i < keys.length; i++) {
      updated[keys[i]] = current[keys[i]];
    }
    updated[field] = value;
    this.formData.value = updated;
    this.isDirty.value = true;

    // Clear field error on update
    if (this.errors[field]) {
      var currentErrors = this.errors;
      var newErrors = {};
      var errorKeys = Object.keys(currentErrors);
      for (var j = 0; j < errorKeys.length; j++) {
        if (errorKeys[j] !== field) {
          newErrors[errorKeys[j]] = currentErrors[errorKeys[j]];
        }
      }
      this.errors.value = newErrors;
    }
  },

  validate: function() {
    var data = this.formData;
    var errors = {};
    if (!data.field1 || data.field1.trim() === '') {
      errors.field1 = 'Field 1 is required';
    }
    if (data.amount === null || data.amount === undefined || data.amount <= 0) {
      errors.amount = 'Amount must be positive';
    }
    this.errors.value = errors;
    return Object.keys(errors).length === 0;
  },

  submit: function() {
    var self = this;
    if (!self.validate()) {
      showAlert('Please fix validation errors', 'warning');
      return;
    }
    self.isSubmitting.value = true;
    try {
      createEntity.run({ data: self.formData });
      showAlert('Created successfully', 'success');
      self.initForm(null);
    } catch(e) {
      showAlert('Error: ' + e.message, 'error');
    } finally {
      self.isSubmitting.value = false;
    }
  }
}
```

## CRUD Pattern (Create + Read + Update + Delete)

```javascript
export default {
  // State: data, selectedItem, isEditing, formData, errors, isLoading

  fetchAll: function() {
    var self = this;
    self.isLoading.value = true;
    try {
      self.data.value = getAllEntities.run();
    } catch(e) {
      self.data.value = [];
      showAlert('Error loading: ' + e.message, 'error');
    } finally {
      self.isLoading.value = false;
    }
  },

  selectItem: function(item) {
    this.selectedItem.value = item;
    this.isEditing.value = false;
  },

  startCreate: function() {
    this.selectedItem.value = null;
    this.formData.value = { field1: '', field2: '', amount: 0 };
    this.errors.value = {};
    this.isEditing.value = true;
  },

  startEdit: function() {
    var item = this.selectedItem;
    this.formData.value = { field1: item.field1, field2: item.field2, amount: item.amount };
    this.errors.value = {};
    this.isEditing.value = true;
  },

  save: function() {
    var self = this;
    if (!self.validate()) return;
    self.isLoading.value = true;
    try {
      if (self.selectedItem && self.selectedItem.persistenceId) {
        updateEntity.run({ id: self.selectedItem.persistenceId, data: self.formData });
        showAlert('Updated successfully', 'success');
      } else {
        createEntity.run({ data: self.formData });
        showAlert('Created successfully', 'success');
      }
      self.isEditing.value = false;
      self.fetchAll();
    } catch(e) {
      showAlert('Error saving: ' + e.message, 'error');
    } finally {
      self.isLoading.value = false;
    }
  },

  deleteSelected: function() {
    var self = this;
    if (!self.selectedItem) return;
    self.isLoading.value = true;
    try {
      deleteEntity.run({ id: self.selectedItem.persistenceId });
      showAlert('Deleted successfully', 'success');
      self.selectedItem.value = null;
      self.fetchAll();
    } catch(e) {
      showAlert('Error deleting: ' + e.message, 'error');
    } finally {
      self.isLoading.value = false;
    }
  },

  cancel: function() {
    this.isEditing.value = false;
    this.errors.value = {};
  },

  validate: function() {
    var data = this.formData;
    var errors = {};
    if (!data.field1 || data.field1.trim() === '') errors.field1 = 'Required';
    this.errors.value = errors;
    return Object.keys(errors).length === 0;
  }
}
```

## Validation Pattern

### Field-Level Validators

```javascript
validators: {
  required: function(value, fieldName) {
    if (value === null || value === undefined || value === '') {
      return fieldName + ' is required';
    }
    return null;
  },
  minLength: function(value, min, fieldName) {
    if (value && value.length < min) {
      return fieldName + ' must be at least ' + min + ' characters';
    }
    return null;
  },
  maxLength: function(value, max, fieldName) {
    if (value && value.length > max) {
      return fieldName + ' must be at most ' + max + ' characters';
    }
    return null;
  },
  isNumber: function(value, fieldName) {
    if (value !== null && value !== undefined && isNaN(Number(value))) {
      return fieldName + ' must be a number';
    }
    return null;
  },
  isPositive: function(value, fieldName) {
    if (value !== null && value !== undefined && Number(value) <= 0) {
      return fieldName + ' must be positive';
    }
    return null;
  },
  isEmail: function(value, fieldName) {
    if (value && value.indexOf('@') === -1) {
      return fieldName + ' must be a valid email';
    }
    return null;
  }
}
```

### Using Validators

```javascript
validateForm: function() {
  var data = this.formData;
  var v = this.validators;
  var errors = {};
  var err;

  err = v.required(data.name, 'Name');
  if (err) errors.name = err;

  err = v.required(data.email, 'Email') || v.isEmail(data.email, 'Email');
  if (err) errors.email = err;

  err = v.required(data.amount, 'Amount') || v.isPositive(data.amount, 'Amount');
  if (err) errors.amount = err;

  this.errors.value = errors;
  return Object.keys(errors).length === 0;
}
```

### Widget Error Display Binding

```json
{
  "errorMessage": "{{JSEntityForm.errors.field1 || ''}}",
  "dynamicBindingPathList": [{ "key": "errorMessage" }]
}
```

## Error Handling Pattern

```javascript
handleError: function(error, context) {
  var message = 'An error occurred';
  if (error && error.message) message = error.message;
  if (error && error.statusCode) {
    if (error.statusCode === 401) message = 'Session expired. Please refresh.';
    else if (error.statusCode === 403) message = 'Permission denied.';
    else if (error.statusCode === 404) message = 'Resource not found.';
    else if (error.statusCode === 500) message = 'Server error. Try again later.';
  }
  showAlert(context + ': ' + message, 'error');
},

safeExecute: function(fn, context) {
  try {
    return fn();
  } catch(e) {
    this.handleError(e, context);
    return null;
  }
}
```

## Sequential Query Execution

```javascript
loadCaseData: function() {
  var self = this;
  self.isLoading.value = true;
  try {
    var caseData = getCaseById.run({ id: self.caseId });
    var tasks = getTasksByCase.run({ caseId: caseData.id });
    var assignees = [];
    for (var i = 0; i < tasks.length; i++) {
      if (tasks[i].assigned_id && tasks[i].assigned_id !== '') {
        var user = getUserById.run({ id: tasks[i].assigned_id });
        assignees.push(user);
      }
    }
    self.caseData.value = caseData;
    self.tasks.value = tasks;
    self.assignees.value = assignees;
  } catch(e) {
    showAlert('Error loading case: ' + e.message, 'error');
  } finally {
    self.isLoading.value = false;
  }
}
```

## Wizard (Multi-step Form) Pattern

### metadata.json variables

```json
{
  "variables": [
    { "name": "currentStep", "value": { "data": 1 } },
    { "name": "totalSteps", "value": { "data": 3 } },
    { "name": "formData", "value": { "data": {} } },
    { "name": "stepErrors", "value": { "data": {} } }
  ]
}
```

### JSWizard.js

```javascript
export default {
  nextStep: function() {
    if (this.validateCurrentStep()) {
      if (this.currentStep < this.totalSteps) {
        this.currentStep.value = this.currentStep + 1;
      }
    }
  },

  prevStep: function() {
    if (this.currentStep > 1) {
      this.currentStep.value = this.currentStep - 1;
    }
  },

  goToStep: function(step) {
    if (step >= 1 && step <= this.totalSteps) {
      this.currentStep.value = step;
    }
  },

  validateCurrentStep: function() {
    var step = this.currentStep;
    var data = this.formData;
    var errors = {};
    if (step === 1) {
      if (!data.field1) errors.field1 = 'Required';
    } else if (step === 2) {
      if (!data.field2) errors.field2 = 'Required';
    }
    this.stepErrors.value = errors;
    return Object.keys(errors).length === 0;
  },

  getProgressPercent: function() {
    return Math.round((this.currentStep / this.totalSteps) * 100);
  }
}
```

## Anti-patterns

- Using arrow functions `() =>` anywhere in JSObjects
- Using `let` or `const` (use `var`)
- Using spread operator `{...obj}` — use manual object copy loops
- Using template literals — use string concatenation
- Using optional chaining `obj?.prop` — use `obj && obj.prop`
- Not wrapping API calls in try/catch
- Forgetting `.value` when writing state variables
