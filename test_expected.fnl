(tset body (+ (# body) 1) stmt)

(tset (. scope.symmeta (. parts 1)) "used" true)

(tset scope.symmeta 1 true)

(global foo bar)

(tset ids k (: ast "var_declare" (. vlist k)))

(: string "match" "abc")

(each [k v (pairs {:a 1})]
  (set-forcibly! k "c"))

(print (.. (or base "") "_" append "_"))

(fn f [x y]
  (var (z zz) (values 9 8))
  (local b 99)
  (set-forcibly! x 5)
  (set z 0)
  (global a 1)
  (set y.y false))

(set-forcibly! f 59)

(. (or (attributes path) []) "mode")

