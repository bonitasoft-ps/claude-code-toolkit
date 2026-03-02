# Event Handler Patterns

## SHandler Interface

```java
public class ProcessStateHandler implements SHandler<SEvent> {

    private static final Logger LOGGER = LoggerFactory.getLogger(ProcessStateHandler.class);

    @Override
    public void execute(SEvent event) throws SHandlerExecutionException {
        if (event instanceof SProcessInstanceStateChangedEvent stateEvent) {
            ProcessInstanceState newState = stateEvent.getProcessInstanceState();
            long processInstanceId = stateEvent.getProcessInstanceId();
            LOGGER.info("Process {} changed state to {}", processInstanceId, newState);
            try {
                handleStateChange(processInstanceId, newState);
            } catch (Exception e) {
                throw new SHandlerExecutionException(e.getMessage(), e);
            }
        }
    }

    @Override
    public boolean isInterested(SEvent event) {
        return event instanceof SProcessInstanceStateChangedEvent;
    }

    @Override
    public String getIdentifier() {
        return "com.company.handlers.ProcessStateHandler";
    }
}
```

## Common Event Types

| Event class | Level | Trigger |
|-------------|-------|---------|
| `SProcessInstanceStateChangedEvent` | Process | Process created, completed, cancelled, aborted |
| `SActivityInstanceStateChangedEvent` | Task | Task started, completed, failed, skipped |
| `SHumanTaskAssignedEvent` | Human Task | Task assigned or unassigned to/from user |
| `SConnectorEvent` | Connector | Connector started, completed, failed |

## Registration

**Bonita 7.x** — `bonita-tenant-sp-custom.xml`:
```xml
<bean id="processStateHandler" class="com.company.handlers.ProcessStateHandler"/>
<bean id="eventService" class="org.bonitasoft.engine.events.impl.EventServiceImpl">
    <property name="handlers">
        <map>
            <entry key="PROCESSINSTANCE_STATE_UPDATED">
                <set><ref bean="processStateHandler"/></set>
            </entry>
        </map>
    </property>
</bean>
```

**Bonita 2024+** — Via REST API or configuration service (check official docs for your version).
