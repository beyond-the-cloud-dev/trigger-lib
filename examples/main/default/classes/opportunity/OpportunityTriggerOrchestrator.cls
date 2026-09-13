public with sharing class OpportunityTriggerOrchestrator implements TriggerOrchestrator.BeforeInsert, TriggerOrchestrator.BeforeUpdate, TriggerOrchestrator.AfterUpdate, TriggerOrchestrator.RecursionGuard {
    public Integer maxRecursionDepth() {
        return 2;
    }

    public List<BeforeInsert.Handler> beforeInsertHandlers() {
        return new List<BeforeInsert.Handler>{
            new OpportunityCloseDatePopulator(),
            new OpportunityTypeFromAccountPopulator(),
            new OpportunityAmountValidator(),
            new OpportunityCloseDateValidator()
        };
    }

    public List<BeforeUpdate.Handler> beforeUpdateHandlers() {
        return new List<BeforeUpdate.Handler>{
            new OpportunityProbabilityPopulator(),
            new OpportunityForecastPopulator(),
            new OpportunityClosingPopulator(),
            new OpportunityWinAmountValidator(),
            new OpportunityReopenValidator(),
            new OpportunityLargeDealValidator(),
            new OpportunityAccountMoveValidator()
        };
    }

    public List<AfterUpdate.Handler> afterUpdateHandlers() {
        return new List<AfterUpdate.Handler>{ new OpportunityAccountTypeHandler(), new OpportunityWinTaskHandler() };
    }
}
