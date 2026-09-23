Every value predicate reads one field of the row described under Value Predicates. None of them throws on a null value:

| Predicate | True when | When the field is null |
|---|---|---|
| `equals(field, value)` / `doesNotEqual(field, value)` | the value is equal / different | `equals(field, null)` is true. Against any other value, `equals` is false and `doesNotEqual` is true. |
| `contains`, `startsWith`, `endsWith` (field, text) | the field's text contains / starts with / ends with the text | false |
| `doesNotContain(field, text)` | the field's text does not contain the text | true |
| `isNull` / `isNotNull` | the value is null / is not null | true / false |
| `isEmpty` / `isNotEmpty` | the value is null or `''` / is neither | true / false |
| `isBlank` / `isNotBlank` | the value is null, `''` or only whitespace / is none of these | true / false |
| `isTrue` / `isFalse` | the value is the Boolean `true` / `false` | false for both |
| `greaterThan`, `greaterThanOrEqualTo`, `lessThan`, `lessThanOrEqualTo` (field, value) | the comparison holds | false for all four |

- **Letter case.** `equals` and `doesNotEqual` compare like Apex `==`, which ignores case for text: `'Doe'` equals `'DOE'`. `contains`, `doesNotContain`, `startsWith` and `endsWith` are case-sensitive: `'Hello World'` does not contain `'world'`. For the opposite behaviour, read the value from the row and use `String.equals` (case-sensitive) or `String.containsIgnoreCase`.
- **Empty text is not null.** `isNull` and `equals(field, null)` are false for `''`. `isEmpty` and `isBlank` treat null and `''` alike, and only `isBlank` also accepts whitespace.
- **Zero and false are values.** `0` and `false` are not null, not empty and not blank. `isTrue` and `isFalse` are both false for null and for the text `'true'`.
- **Comparisons are false for null.** `lessThan(field, 100)` is false when the field is empty, so "below 100 or empty" needs `isNull(field) || lessThan(field, 100)`.
- **Number overloads** (`Integer`, `Long`, `Double`, `Decimal`) compare the field value as a `Decimal`, so they work on number, currency and percent fields whatever the type of the literal you pass.
- **Date overloads.** Pass a `Date` for a Date field and a `DateTime` for a Date/Time field: the field value is cast to the type of the overload you call.
- **Text form.** `contains`, `doesNotContain`, `startsWith` and `endsWith` read any field through its text form, so `contains(Account.NumberOfEmployees, '50')` is true for 1500.
