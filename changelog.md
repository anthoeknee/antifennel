# Summary of user-visible changes

## 0.2.0 / ???

* Use version 0.2.1 of fnlfmt.
* Emit method calls as foo:bar where appropriate.
* Upgrade to Fennel 0.8.2-dev.
* Use `let` where appropriate to replace `do+local` or directly inside `fn`.
* Emit identifiers using kebab-case instead of camelCase or snake_case.
* Compile `local f = function()` to `fn` idiomatically.
* Emit local instead of var when binding is not changed.

## 0.1.0 / 2020-06-30

* First release! Capable of compiling Fennel itself.
