# Bonita Test Toolkit API Patterns — Detailed

## Process Lifecycle

### Deploy

```java
// From .bar file in resources
ProcessDefinition process = deployProcess("Process--1.0.bar");

// Deploy multiple processes
ProcessDefinition mainProcess = deployProcess("MainProcess--1.0.bar");
ProcessDefinition subProcess = deployProcess("SubProcess--1.0.bar");
```

### Start with simple inputs

```java
ProcessInstance instance = client.start(process)
    .with("stringVar", "value")
    .with("intVar", 42)
    .with("boolVar", true)
    .execute();
```

### Start with complex contract

```java
ComplexInputBuilder requestInput = ComplexInputBuilder.complexInput()
    .textInput("thirdParty", thirdPartyCode)
    .textInput("paymentType", paymentTypeCode)
    .textInput("invoiceNumber", "INV-" + UUID.randomUUID().toString().substring(0, 8))
    .localDateInput("invoiceDate", LocalDate.now())
    .decimalInput("invoiceAmount", 3000.0)
    .textInput("invoiceCurrency", "EUR")
    .textInput("action", "submit")
    .multipleFileInput("attachments", Collections.emptyList());

Contract contract = ContractBuilder.newContract()
    .complexInput("requestInput", requestInput)
    .build();

ProcessInstance instance = startProcess(process, user, contract);
```

## User Task Interaction

### Wait for and execute task

```java
// Simple task execution
client.waitForTask(instance, "Complete Draft")
    .with("action", "submit")
    .execute();

// Task with complex output
ComplexInputBuilder taskOutput = ComplexInputBuilder.complexInput()
    .textInput("decision", "approved")
    .textInput("comment", "Looks good");

client.waitForTask(instance, "Review Request")
    .withComplexInput("reviewOutput", taskOutput)
    .execute();
```

### Execute as specific user

```java
User reviewer = client.getUser("john.doe");
client.waitForTask(instance, "Review Request")
    .as(reviewer)
    .with("decision", "approved")
    .execute();
```

## Assertions

### Process instance assertions

```java
import static com.bonitasoft.test.toolkit.assertion.ProcessInstanceAssert.assertThat;

// Completed
assertThat(instance).isCompleted();

// Has variable
assertThat(instance).hasVariable("status", "approved");

// Is archived (completed or cancelled)
assertThat(instance).isArchived();
```

### Using Awaitility for async assertions

```java
import static org.awaitility.Awaitility.await;
import static com.bonitasoft.test.toolkit.predicate.ProcessInstancePredicates.*;

// Wait for task to appear
await().atMost(Duration.ofSeconds(30))
    .until(instance, containsPendingUserTasks("Review Request"));

// Wait for process completion
await().atMost(Duration.ofSeconds(60))
    .until(instance, ProcessInstancePredicates.isArchived());

// Custom polling
await().atMost(Duration.ofSeconds(30))
    .pollInterval(Duration.ofMillis(500))
    .until(() -> instance.getNumberOfFailedFlowNodes() == 0);
```

## Timer Handling

Timers do NOT fire automatically in test context. You must force them.

### Simple timer forcing

```java
TimerEventTrigger trigger = instance.getTimerEventTrigger("Wait Timer");
trigger.execute();
```

### Robust timer forcing with retry

```java
private void waitAndForceTimer(ProcessInstance instance, String timerName) {
    await().atMost(Duration.ofSeconds(30))
        .pollInterval(Duration.ofMillis(500))
        .until(() -> {
            if (instance.isArchived()) {
                return true;  // Process already completed
            }
            try {
                instance.getTimerEventTrigger(timerName).execute();
                return true;
            } catch (Exception e) {
                return false;  // Timer not yet available
            }
        });
}
```

## BDM Access

### Get DAO and query

```java
BusinessObjectDAO<BusinessData> dao = toolkit.getBusinessObjectDAO(
    "com.company.model.paymentRequest.ThirdParty.PRQThirdParty"
);

// Find items (offset, limit)
List<BusinessData> items = dao.find(0, 10);

// Access fields
String code = items.get(0).getStringField("codeThirdParty");
Double amount = items.get(0).getDoubleField("invoiceAmount");
LocalDate date = items.get(0).getLocalDateField("invoiceDate");
Boolean active = items.get(0).getBooleanField("isActive");
```

### Master data initialization

```java
@BeforeAll
void setUpProcess() {
    initializeMasterDataIfNeeded();
    testThirdPartyCode = findFirstThirdPartyCode();
}

private void initializeMasterDataIfNeeded() {
    BusinessObjectDAO<BusinessData> dao = toolkit.getBusinessObjectDAO(BdmTypes.PRQ_THIRD_PARTY);
    if (dao.find(0, 1).isEmpty()) {
        ProcessInstance instance = startProcess(masterDatasProcess, user);
        waitForProcessCompletion(instance);
    }
}

private String findFirstThirdPartyCode() {
    BusinessObjectDAO<BusinessData> dao = toolkit.getBusinessObjectDAO(BdmTypes.PRQ_THIRD_PARTY);
    List<BusinessData> items = dao.find(0, 1);
    assertThat(items).isNotEmpty();
    return items.get(0).getStringField("codeThirdParty");
}
```

## Process State Inspection

```java
// Check if process completed
boolean completed = instance.isArchived();

// Get failed flow nodes
int failures = instance.getNumberOfFailedFlowNodes();

// Get process variables
Map<String, Object> variables = instance.getVariables();

// Check specific variable
Object value = instance.getVariable("status");
```

## Test Constants Pattern

```java
public final class TestConstants {
    private TestConstants() {} // Utility class

    // Process names
    public static final String PROCESS_PAYMENT_REQUEST = "PaymentRequest";
    public static final String PROCESS_MASTER_DATA = "MasterDataInitializer";

    // Task names
    public static final class Tasks {
        public static final String COMPLETE_DRAFT = "Complete Draft";
        public static final String REVIEW_REQUEST = "Review & Approve Request";
        public static final String DIRECTOR_APPROVAL = "Director Approval";
    }

    // Timer names
    public static final class Timers {
        public static final String PAYMENT_DATE_WAIT = "Wait for payment date";
    }

    // Thresholds - MUST match BDM values!
    public static final class Thresholds {
        public static final double HIGH_VALUE_LIMIT = 5000.0;
        public static final double STANDARD_AMOUNT = 3000.0;
    }

    // BDM fully qualified type names
    public static final class BdmTypes {
        public static final String PRQ_THIRD_PARTY = "com.company.model.paymentRequest.ThirdParty.PRQThirdParty";
        public static final String PRQ_PAYMENT_TYPE = "com.company.model.paymentRequest.PaymentType.PRQPaymentType";
    }

    // Timeouts
    public static final Duration DEFAULT_TIMEOUT = Duration.ofSeconds(30);
    public static final Duration LONG_TIMEOUT = Duration.ofSeconds(60);
}
```

## Official Documentation

- [Process Testing Overview](https://documentation.bonitasoft.com/test-toolkit/latest/process-testing-overview)
- [Quick Start Guide](https://documentation.bonitasoft.com/test-toolkit/latest/quick-start)
- [Bonita Test Toolkit API](https://documentation.bonitasoft.com/test-toolkit/latest/)
