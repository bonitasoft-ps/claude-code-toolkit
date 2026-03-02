# Actor Filter Patterns

## AbstractUserFilter Lifecycle

```java
public class ManagerActorFilter extends AbstractUserFilter {

    public static final String INPUT_INITIATOR_ID = "initiatorId";

    @Override
    public void validateInputParameters() throws ConnectorValidationException {
        Long initiatorId = (Long) getInputParameter(INPUT_INITIATOR_ID);
        if (initiatorId == null || initiatorId <= 0) {
            throw new ConnectorValidationException(this, List.of("initiatorId must be a positive number"));
        }
    }

    @Override
    public List<Long> filter(String actorName) throws UserFilterException {
        Long initiatorId = (Long) getInputParameter(INPUT_INITIATOR_ID);
        try {
            IdentityAPI identityAPI = APIAccessor.getIdentityAPI();
            User initiator = identityAPI.getUser(initiatorId);
            // Find the manager of the initiator
            return identityAPI.getUsersByManager(initiatorId, 0, 100)
                    .stream()
                    .map(User::getId)
                    .toList();
        } catch (Exception e) {
            throw new UserFilterException("Failed to find manager for user " + initiatorId, e);
        }
    }

    @Override
    public boolean shouldAutoAssignTaskIfSingleResult() {
        return true; // Auto-assign if only one candidate found
    }
}
```

## Common Actor Filter Patterns

| Filter type | `filter()` strategy |
|-------------|---------------------|
| Manager filter | `identityAPI.getUsersByManager(initiatorId, ...)` |
| Group filter | `identityAPI.getUsersInGroup(groupId, ...)` |
| Role filter | `identityAPI.getUsersWithRole(roleId, ...)` |
| Custom attribute filter | Query users + filter by `identityAPI.getUserMemberships(...)` |
