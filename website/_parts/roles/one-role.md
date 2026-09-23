<!-- #region after -->

- **Writer wins over Dispatcher.** A class that implements both roles runs only as a Writer. Its Dispatcher methods never run, and nothing warns you. Move the dispatch into its own Dispatcher class.
- **Dispatchers run where they are listed.** The shared unit of work commits once, after the last handler in the list, so every Dispatcher runs before the Writers' registrations on that unit are saved, including Writers listed before it.

<!-- #region before -->

**One role per context.** Handlers run in list order, whatever their role. A class that implements only the context's `Handler` marker compiles and fits in the handler list, but it never runs: the orchestrator adapts only the role interfaces and drops anything else without a warning. The rule applies per context, so one class can take a role in each of several contexts.

<!-- #endregion after -->

- **Populator wins over Validator.** A class that implements both roles runs only as a Populator. Its Validator methods never run, and nothing warns you. Move the validation into its own Validator class.
- **Populators first.** A Validator listed before a Populator checks values that the Populator has not set yet, so list the Populators first.

<!-- #endregion before -->
