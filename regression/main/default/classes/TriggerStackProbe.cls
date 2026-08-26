public with sharing class TriggerStackProbe {
    // Scenario switches — set from anonymous Apex before the DML under test.
    public static Boolean enabled = false;
    public static Boolean chainEnabled = true;
    public static Boolean failMarkedRecords = false;
    public static Boolean dmlFromBeforeUpdate = false;
    public static Boolean twoInsertsFromAccount = false;
    public static Integer remainingLaps = 0;
    public static Integer maxDepth = 3;

    public static Boolean bulkMode = false;
    public static List<Id> bulkOpportunityIds;
    public static List<Id> bulkCaseIds;
    public static List<Id> bulkCampaignIds;
    public static Boolean throwInCampaignHandler = false;

    public static Id accountId;
    public static Id contactId;
    public static Id opportunityId;
    public static Id caseId;
    public static Id campaignId;
    public static Id productId;
    public static Id assetId;

    public static List<String> trace = new List<String>();

    private static TriggerOrchestrator.Invocation lastTracedInvocation;
    private static Integer hopCounter = 0;

    public static void start() {
        trace.clear();
        lastTracedInvocation = null;
        enabled = true;
    }

    public static void note(String message) {
        trace.add('NOTE     ' + message);
    }

    public static String report() {
        String out = '\n===== PROBE TRACE (' + trace.size() + ' events) =====\n';

        for (Integer i = 0; i < trace.size(); i++) {
            out += String.valueOf(i + 1).leftPad(3) + '. ' + trace[i] + '\n';
        }

        return out + '===== END TRACE =====';
    }

    // One line per invocation rather than per record, so a 201-record run stays readable.
    public static void recordInvocation(String label) {
        List<TriggerOrchestrator.Invocation> stack = TriggerOrchestrator.getStack();

        if (Trigger.isBefore) {
            List<SObject> rows = Trigger.new ?? Trigger.old;
            String nesting = stack.isEmpty() ? 'root' : 'under ' + label(stack[stack.size() - 1]);
            trace.add('BEFORE   ' + rows.getSObjectType() + '.' + shortOperation(Trigger.operationType) + '[' + rows.size() + '] ' + nesting + '  <- ' + label);
            return;
        }

        if (stack.isEmpty()) {
            trace.add('ORPHAN   ' + label + ' — handler ran with an empty stack');
            return;
        }

        TriggerOrchestrator.Invocation top = stack[stack.size() - 1];

        if (top == lastTracedInvocation) {
            return;
        }

        lastTracedInvocation = top;
        trace.add('INVOKE   ' + describe(stack) + '  <- ' + label);
    }

    public static String describe(List<TriggerOrchestrator.Invocation> stack) {
        if (stack.isEmpty()) {
            return 'depth=0 stack=[]';
        }

        TriggerOrchestrator.Invocation top = stack[stack.size() - 1];
        String path = '';

        for (TriggerOrchestrator.Invocation invocation : stack) {
            path += (path == '' ? '' : ' > ') + label(invocation);
        }

        return 'd' + top.getDepth() +
            ' seq' + top.getChainSequence() +
            ' rows=' + top.getRecordCount() +
            ' ending=' + TriggerOrchestrator.isChainEnding() +
            ' rootEnding=' + stack[0].isChainEnding() +
            ' [' + path + ']';
    }

    public static String label(TriggerOrchestrator.Invocation invocation) {
        return String.valueOf(invocation.getSObjectType()) + '.' + shortOperation(invocation.getOperation());
    }

    private static String shortOperation(System.TriggerOperation operation) {
        return operation.name().replace('BEFORE_', 'b').replace('AFTER_', 'a').toLowerCase();
    }


    public static String renderChainTree() {
        List<String> parts = new List<String>();

        for (TriggerOrchestrator.Invocation root : TriggerOrchestrator.getChainTree()) {
            parts.add(describeSubtree(root));
        }

        return String.join(parts, ', ');
    }

    private static String describeSubtree(TriggerOrchestrator.Invocation node) {
        String out = label(node) + '[' + node.getRecordCount() + ']';
        List<String> childParts = new List<String>();

        for (TriggerOrchestrator.Invocation child : node.getChildren()) {
            childParts.add(describeSubtree(child));
        }

        return childParts.isEmpty() ? out : out + '(' + String.join(childParts, ', ') + ')';
    }

    private static String stamp() {
        hopCounter++;
        return 'probe hop ' + hopCounter;
    }

    // Records the invocation, then performs this object's nested DML — the "fake operation"
    // that makes one trigger invoke the next.
    public class ChainHandler implements TriggerHandler.AfterUpdate, TriggerHandler.AfterInsert {
        private String hop;

        public ChainHandler(String hop) {
            this.hop = hop;
        }

        public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.Record record) {
            return enabled && chainEnabled && !bulkMode;
        }

        public void onAfterUpdate(TriggerHandler.Record record) {
            this.execute();
        }

        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.Record record) {
            return enabled && chainEnabled && !bulkMode;
        }

        public void onAfterInsert(TriggerHandler.Record record) {
            this.execute();
        }

        private void execute() {
            recordInvocation(this.hop + ' chain handler');

            switch on this.hop {
                when 'ACCOUNT' {
                    update new Contact(Id = contactId, Description = stamp());
                }
                when 'CONTACT' {
                    update new Opportunity(Id = opportunityId, Description = stamp());
                }
                when 'OPPORTUNITY' {
                    if (remainingLaps > 0) {
                        remainingLaps--;
                        note('cycle: Opportunity -> Account (laps left after this: ' + remainingLaps + ')');
                        update new Account(Id = accountId, Description = stamp());
                    } else {
                        note('cycle: stopped at Opportunity, no laps left');
                    }
                }
                when 'LEAD' {
                    insert new Task(Subject = 'Probe task', Description = stamp());
                }
                when 'TASK' {
                    update new Case(Id = caseId, Description = stamp());
                }
                when 'CASE' {
                    update new Campaign(Id = campaignId, Description = stamp());
                }
                when 'CAMPAIGN' {
                    if (throwInCampaignHandler) {
                        note('campaign handler is about to throw');
                        throw new ProbeException('Deliberate probe failure inside the Campaign handler');
                    }
                    update new Product2(Id = productId, Description = stamp());
                }
                when 'PRODUCT' {
                    update new Asset(Id = assetId, Description = stamp());
                }
                when 'ASSET' {
                    insert new Event(Subject = 'Probe event', StartDateTime = System.now(), DurationInMinutes = 15);
                }
            }
        }
    }

    // Bulk variant of the chain: each invocation performs ONE nested DML of many records, rather than
    // one per record. The instance is rebuilt per run(), so the flag is naturally per-invocation —
    // which is the only way to do bulk work through the library's per-record handler API.
    public class BulkChainHandler implements TriggerHandler.AfterUpdate {
        private String hop;
        private Boolean alreadyRanForThisInvocation = false;

        public BulkChainHandler(String hop) {
            this.hop = hop;
        }

        public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.Record record) {
            return enabled && bulkMode;
        }

        public void onAfterUpdate(TriggerHandler.Record record) {
            recordInvocation(this.hop + ' bulk handler');

            if (this.alreadyRanForThisInvocation) {
                return;
            }

            this.alreadyRanForThisInvocation = true;

            switch on this.hop {
                when 'ACCOUNT' {
                    this.push(bulkOpportunityIds, Opportunity.SObjectType);
                }
                when 'OPPORTUNITY' {
                    this.push(bulkCaseIds, Case.SObjectType);
                }
                when 'CASE' {
                    this.push(bulkCampaignIds, Campaign.SObjectType);
                }
            }
        }

        private void push(List<Id> recordIds, SObjectType targetType) {
            if (recordIds == null || recordIds.isEmpty()) {
                return;
            }

            List<SObject> records = new List<SObject>();

            for (Id recordId : recordIds) {
                SObject record = targetType.newSObject(recordId);
                record.put('Description', stamp());
                records.add(record);
            }

            note(this.hop + ' -> ' + recordIds.size() + ' ' + targetType + ' (dmlRows so far ' + Limits.getDmlRows() + ')');
            update records;
        }
    }

    // Records the invocation without performing any DML.
    public class Tracer implements TriggerHandler.BeforeUpdate, TriggerHandler.AfterUpdate, TriggerHandler.BeforeInsert, TriggerHandler.AfterInsert {
        private String label;
        private Boolean recorded = false;

        public Tracer(String label) {
            this.label = label;
        }

        private void recordOnce() {
            if (this.recorded) {
                return;
            }

            this.recorded = true;
            recordInvocation(this.label);
        }

        public Boolean qualifiesForBeforeUpdateWhen(TriggerHandler.Record record) {
            return enabled;
        }

        public void onBeforeUpdate(TriggerHandler.Record record) {
            this.recordOnce();
        }

        public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.Record record) {
            return enabled;
        }

        public void onAfterUpdate(TriggerHandler.Record record) {
            recordInvocation(this.label);
        }

        public Boolean qualifiesForBeforeInsertWhen(TriggerHandler.Record record) {
            return enabled;
        }

        public void onBeforeInsert(TriggerHandler.Record record) {
            this.recordOnce();
        }

        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.Record record) {
            return enabled;
        }

        public void onAfterInsert(TriggerHandler.Record record) {
            recordInvocation(this.label);
        }
    }


    // Proves DML from a before context is legal and re-enters triggers synchronously.
    public class BeforeDmlHandler implements TriggerHandler.BeforeUpdate {
        public Boolean qualifiesForBeforeUpdateWhen(TriggerHandler.Record record) {
            return enabled && dmlFromBeforeUpdate;
        }

        public void onBeforeUpdate(TriggerHandler.Record record) {
            dmlFromBeforeUpdate = false;
            update new Case(Id = caseId, Description = stamp());
        }
    }


    // Mutates the trigger rows the way a real before-insert populator does.
    public class EventMutationHandler implements TriggerHandler.BeforeInsert {
        public Boolean qualifiesForBeforeInsertWhen(TriggerHandler.Record record) {
            return enabled;
        }

        public void onBeforeInsert(TriggerHandler.Record record) {
            record.put(Event.Description, 'mutated by populator');
        }
    }


    // Two statements from one handler: both nested trees must hang under the same parent.
    public class TwoInsertsHandler implements TriggerHandler.AfterUpdate {
        public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.Record record) {
            return enabled && twoInsertsFromAccount;
        }

        public void onAfterUpdate(TriggerHandler.Record record) {
            twoInsertsFromAccount = false;
            insert new Task(Subject = 'Probe task', Description = stamp());
            insert new Event(Subject = 'Probe event', StartDateTime = System.now(), DurationInMinutes = 15);
        }
    }

    // Vetoes records marked FAIL, so Database.update(..., false) produces a real partial save.
    public class FailMarkerHandler implements TriggerHandler.BeforeUpdate {
        public Boolean qualifiesForBeforeUpdateWhen(TriggerHandler.Record record) {
            return enabled && failMarkedRecords && record.startsWith(Account.Description, 'FAIL');
        }

        public void onBeforeUpdate(TriggerHandler.Record record) {
            note('addError on ' + record.getId());
            record.getNewSObject().addError('Probe veto — forces a partial save');
        }
    }

    // Orchestrators — one per probed object.

    public class AccountOrchestrator implements TriggerOrchestrator.BeforeUpdate, TriggerOrchestrator.AfterUpdate, TriggerOrchestrator.RecursiveUpdateGuard {
        public Integer maxRecursionDepth() {
            return maxDepth;
        }

        public Boolean muteRecursionDepthExceededException() {
            return false;
        }

        public List<TriggerHandler.BeforeUpdate> beforeUpdateHandlers() {
            return new List<TriggerHandler.BeforeUpdate>{ new Tracer('Account tracer'), new FailMarkerHandler(), new BeforeDmlHandler() };
        }

        public List<TriggerHandler.AfterUpdate> afterUpdateHandlers() {
            return new List<TriggerHandler.AfterUpdate>{ new Tracer('Account tracer'), new ChainHandler('ACCOUNT'), new BulkChainHandler('ACCOUNT'), new TwoInsertsHandler() };
        }
    }

    public class ContactOrchestrator implements TriggerOrchestrator.BeforeUpdate, TriggerOrchestrator.AfterUpdate, TriggerOrchestrator.RecursiveUpdateGuard {
        public Integer maxRecursionDepth() {
            return maxDepth;
        }

        public Boolean muteRecursionDepthExceededException() {
            return false;
        }

        public List<TriggerHandler.BeforeUpdate> beforeUpdateHandlers() {
            return new List<TriggerHandler.BeforeUpdate>{ new Tracer('Contact tracer') };
        }

        public List<TriggerHandler.AfterUpdate> afterUpdateHandlers() {
            return new List<TriggerHandler.AfterUpdate>{ new Tracer('Contact tracer'), new ChainHandler('CONTACT') };
        }
    }

    public class OpportunityOrchestrator implements TriggerOrchestrator.BeforeUpdate, TriggerOrchestrator.AfterUpdate, TriggerOrchestrator.RecursiveUpdateGuard {
        public Integer maxRecursionDepth() {
            return maxDepth;
        }

        public Boolean muteRecursionDepthExceededException() {
            return false;
        }

        public List<TriggerHandler.BeforeUpdate> beforeUpdateHandlers() {
            return new List<TriggerHandler.BeforeUpdate>{ new Tracer('Opportunity tracer') };
        }

        public List<TriggerHandler.AfterUpdate> afterUpdateHandlers() {
            return new List<TriggerHandler.AfterUpdate>{ new Tracer('Opportunity tracer'), new ChainHandler('OPPORTUNITY'), new BulkChainHandler('OPPORTUNITY') };
        }
    }

    public class LeadOrchestrator implements TriggerOrchestrator.AfterUpdate {
        public List<TriggerHandler.AfterUpdate> afterUpdateHandlers() {
            return new List<TriggerHandler.AfterUpdate>{ new Tracer('Lead tracer'), new ChainHandler('LEAD') };
        }
    }

    public class TaskOrchestrator implements TriggerOrchestrator.AfterInsert {
        public List<TriggerHandler.AfterInsert> afterInsertHandlers() {
            return new List<TriggerHandler.AfterInsert>{ new Tracer('Task tracer'), new ChainHandler('TASK') };
        }
    }

    public class CaseOrchestrator implements TriggerOrchestrator.AfterUpdate, TriggerOrchestrator.RecursiveUpdateGuard {
        public Integer maxRecursionDepth() {
            return maxDepth;
        }

        public Boolean muteRecursionDepthExceededException() {
            return false;
        }

        public List<TriggerHandler.AfterUpdate> afterUpdateHandlers() {
            return new List<TriggerHandler.AfterUpdate>{ new Tracer('Case tracer'), new ChainHandler('CASE'), new BulkChainHandler('CASE') };
        }
    }

    public class CampaignOrchestrator implements TriggerOrchestrator.AfterUpdate, TriggerOrchestrator.RecursiveUpdateGuard {
        public Integer maxRecursionDepth() {
            return maxDepth;
        }

        public Boolean muteRecursionDepthExceededException() {
            return false;
        }

        public List<TriggerHandler.AfterUpdate> afterUpdateHandlers() {
            return new List<TriggerHandler.AfterUpdate>{ new Tracer('Campaign tracer'), new ChainHandler('CAMPAIGN') };
        }
    }

    public class ProductOrchestrator implements TriggerOrchestrator.AfterUpdate {
        public List<TriggerHandler.AfterUpdate> afterUpdateHandlers() {
            return new List<TriggerHandler.AfterUpdate>{ new Tracer('Product2 tracer'), new ChainHandler('PRODUCT') };
        }
    }

    public class AssetOrchestrator implements TriggerOrchestrator.AfterUpdate {
        public List<TriggerHandler.AfterUpdate> afterUpdateHandlers() {
            return new List<TriggerHandler.AfterUpdate>{ new Tracer('Asset tracer'), new ChainHandler('ASSET') };
        }
    }

    // Leaf of the chain, and the library's documented before-only case.
    public class EventOrchestrator implements TriggerOrchestrator.BeforeInsert {
        public List<TriggerHandler.BeforeInsert> beforeInsertHandlers() {
            return new List<TriggerHandler.BeforeInsert>{ new Tracer('Event tracer (before-only object)'), new EventMutationHandler() };
        }
    }

    // Second orchestrator on Campaign, used to probe two trigger-lib triggers on one object.
    public class CampaignSecondOrchestrator implements TriggerOrchestrator.AfterUpdate {
        public List<TriggerHandler.AfterUpdate> afterUpdateHandlers() {
            return new List<TriggerHandler.AfterUpdate>{ new Tracer('Campaign SECOND trigger') };
        }
    }


    public class EventSecondOrchestrator implements TriggerOrchestrator.BeforeInsert {
        public List<TriggerHandler.BeforeInsert> beforeInsertHandlers() {
            return new List<TriggerHandler.BeforeInsert>{ new Tracer('Event SECOND trigger') };
        }
    }


    public class CampaignThirdOrchestrator implements TriggerOrchestrator.AfterUpdate {
        public List<TriggerHandler.AfterUpdate> afterUpdateHandlers() {
            return new List<TriggerHandler.AfterUpdate>{ new Tracer('Campaign THIRD orchestrator (same trigger as SECOND)') };
        }
    }

    public class ProbeException extends Exception {}
}
