# Groovy to Java Migration Patterns

## Variable Declarations

```groovy
// Groovy
def name = "John"
def age = 30
def items = [1, 2, 3]
def map = [key: "value", count: 42]
```

```java
// Java 17
var name = "John";
var age = 30;
var items = List.of(1, 2, 3);
var map = Map.of("key", "value", "count", 42);
```

## String Operations

```groovy
// Groovy GString interpolation
def message = "Hello ${user.firstName}, you have ${tasks.size()} tasks"
def multiline = """
    SELECT *
    FROM bonita_process
    WHERE id = ${processId}
"""
```

```java
// Java 17 text blocks + String.format
var message = "Hello %s, you have %d tasks".formatted(user.getFirstName(), tasks.size());
var multiline = """
    SELECT *
    FROM bonita_process
    WHERE id = %d
    """.formatted(processId);
```

## Collections

```groovy
// Groovy
def filtered = items.findAll { it.status == "active" }
def mapped = items.collect { it.name }
def found = items.find { it.id == targetId }
def grouped = items.groupBy { it.category }
```

```java
// Java 17
var filtered = items.stream().filter(i -> i.getStatus().equals("active")).toList();
var mapped = items.stream().map(Item::getName).toList();
var found = items.stream().filter(i -> i.getId() == targetId).findFirst().orElse(null);
var grouped = items.stream().collect(Collectors.groupingBy(Item::getCategory));
```

## Null Safety

```groovy
// Groovy safe navigation
def city = user?.address?.city ?: "Unknown"
```

```java
// Java 17
var city = Optional.ofNullable(user)
    .map(User::getAddress)
    .map(Address::getCity)
    .orElse("Unknown");
```

## Bonita API Patterns

```groovy
// Groovy — initProcess script
def processAPI = apiAccessor.getProcessAPI()
def identity = apiAccessor.getIdentityAPI()
def user = identity.getUser(userId)
return user.getFirstName() + " " + user.getLastName()
```

```java
// Java 17 — utility class method
public static String getUserFullName(APIAccessor apiAccessor, long userId)
        throws UserNotFoundException {
    var identity = apiAccessor.getIdentityAPI();
    var user = identity.getUser(userId);
    return user.getFirstName() + " " + user.getLastName();
}
```

## Common Gotchas

| Groovy pattern | Java equivalent | Notes |
|---------------|-----------------|-------|
| `list << item` | `list.add(item)` | Groovy operator overloading |
| `map.key` | `map.get("key")` | Groovy property access |
| `obj.with { ... }` | No direct equivalent | Use builder or local vars |
| `def` | `var` (local) or explicit type | `var` only for local variables |
| `it` (implicit param) | Explicit lambda parameter | `x -> x.method()` |
| `?.` (safe navigation) | `Optional` or null checks | More verbose in Java |
| `*. (spread)` | `.stream().map().toList()` | No spread in Java |
