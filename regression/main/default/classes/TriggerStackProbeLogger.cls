// Discovered automatically by TriggerOrchestrator via ApexTypeImplementor.
public with sharing class TriggerStackProbeLogger implements TriggerOrchestrator.Logger {
    public void log(TriggerOrchestrator.Error error) {
        String invocations = '';

        for (TriggerOrchestrator.Invocation invocation : error.getStack()) {
            invocations += (invocations == '' ? '' : ' > ') + TriggerStackProbe.label(invocation) +
                '(d' + invocation.getDepth() + ',seq' + invocation.getChainSequence() + ')';
        }

        TriggerStackProbe.trace.add(
            'LOG      ' + error.getException().getTypeName() + ': ' + error.getException().getMessage() +
            ' | on ' + error.getSObjectType() + '.' + error.getOperation() +
            ' ids=' + (error.getRecordIds() == null ? 0 : error.getRecordIds().size()) +
            ' | invocations: ' + invocations
        );
    }

    public void flush() {
        TriggerStackProbe.trace.add(
            'FLUSH    ' + TriggerStackProbe.describe(TriggerOrchestrator.getStack()) +
            ' dmlRows=' + Limits.getDmlRows()
        );
        TriggerStackProbe.trace.add('TREE     ' + TriggerStackProbe.renderChainTree());
    }
}
