The handler works through the records one at a time, in the order the trigger received them. For each record, the predicate (the `…When` method) decides whether the handler acts on it. When it returns true, the action runs for that record at once, before the next record's predicate. Predicates and actions are interleaved: there is no pass that evaluates every predicate first.

- **Every record, every handler.** Each handler that is not switched off receives every record of the chunk, except that a BeforeUpdate Populator and an AfterUpdate Writer or Dispatcher skip, before the predicate, records that have used up this handler's recursion budget. A record whose predicate returns false is skipped by this handler only; later handlers still see it.
- **Data is ready before the first predicate.** This handler's RelatedQuery providers have already run over all records, and the parents that the active handlers declared are already attached.
- **The Finalizer comes last.** After the last record, the Finalizer runs once, if at least one record qualified, and receives only the qualified records.

::: warning No SOQL or DML in the predicate or the action
Both run once per record. Governor limits count per transaction, not per chunk or per handler, so a query per record throws `System.LimitException` as soon as the transaction passes 100 queries (the synchronous limit): a single 200-record chunk is enough. The count carries over from chunk to chunk and includes every other query in the transaction. DML per record runs into the 150-statement limit the same way. The `LimitException` cannot be caught: not by your `try`, not by the library, and ContinueOnError does not swallow it.

Declare what you read instead: lookup fields through the context's parent-query add-on, other records through a RelatedQuery. Work that needs the whole set belongs in the Finalizer, which runs once per chunk.
:::
