# Summary of user-visible changes

## 0.3.0 / ???

* Fix a bug with raw iterator values in a for loop.
* Add support for comments.
* Add support for bitwise operators.

## 0.2.0 / 2023-02-18

* Use version 1.3.0 of Fennel and 0.3.0 of fnlfmt.
* Fix a bug where multi-sym assignments were broken.
* Fix a bug where sequences were emitted with curly brackets.
* Emit method calls as foo:bar where appropriate.
* Upgrade to Fennel 0.8.2-dev.
* Use `let` where appropriate to replace `do+local` or directly inside `fn`.
* Emit identifiers using kebab-case instead of camelCase or snake_case.
* Compile `local f = function()` to `fn` idiomatically.
* Emit local instead of var when binding is not changed.

## 0.1.0 / 2020-06-30

* First release! Capable of compiling Fennel itself.
