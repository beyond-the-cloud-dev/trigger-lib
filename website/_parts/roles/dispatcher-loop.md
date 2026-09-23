A Dispatcher does not act per record. It goes through the records in the order the trigger received them and only collects the ones its predicate (the `…When` method) accepts.

- **One dispatch per run.** After the loop, the dispatch method runs once with all the qualified records, and only if at least one record qualified. The platform runs a trigger once per chunk of up to 200 records, so a statement of 1,000 records can dispatch 5 times.
- **The Finalizer runs after the dispatch.** If the Dispatcher has one, it receives the same qualified records.
- **Data is ready before the loop.** This Dispatcher's RelatedQuery providers have already run over all records, and the parents that the active handlers declared are already attached.
- **It runs at its list position, before the shared commit.** The shared unit of work commits only after the last handler, so what the Writers registered on it is not in the database yet, even for Writers listed earlier. An earlier Writer with its own or a private unit (OwnUnitOfWork, ContinueOnError) has already committed, provided at least one of its records qualified and it did not fail. A Queueable enqueued here starts only after the transaction commits.

::: warning No SOQL or DML in the predicate
The predicate runs once per record. Governor limits count per transaction, not per chunk or per handler, so a query per record throws `System.LimitException` as soon as the transaction passes 100 queries (the synchronous limit): a single 200-record chunk is enough. The count carries over from chunk to chunk and includes every other query in the transaction. The `LimitException` cannot be caught: not by your `try`, not by the library, and ContinueOnError does not swallow it.

Query once in the dispatch method, where you have all the qualified records, or declare what you read: lookup fields through the context's parent-query add-on, other records through a RelatedQuery.
:::
