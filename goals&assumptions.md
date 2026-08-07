1. Use as few SOQL queries as possible.
    - allow for parent data enrichment
    - allow to query child records
    - allow to query unrelated records
    - make query only for records that were qualified to reduce number of rows
    - for before insert context to query parent fields we need to make separated query for each parent
    - for before update context records have id already so instead of querying each parent type separately we can make a single query with parent relationship
    - for after insert, after update context we cannot enrich data as record is read-only. The only option is replace Trigger.new records (which have all fields) with queried records. As the record is read-only and I want to keep the same feeling for before and after context, the easiest way will be shallow copy. It doesn't consume to much apex heap size.
2. 