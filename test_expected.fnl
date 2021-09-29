(tset body (+ (length body) 1) stmt)

(tset (. scope.symmeta (. parts 1)) :used true)

(tset scope.symmeta 1 true)

(global foo bar)

(tset ids k (ast:var_declare (. vlist k)))

(global SCREAMING_SNAKE true)

(string:match :abc)

(local t {:t2 {:f (fn [x]
                    x)}})

(: (. t :t2) :f)

(each [k v (pairs {:a 1})]
  (set-forcibly! k :c))

(print (.. (or base "") "_" append "_"))

(fn f [x y]
  (var (z zz) (values 9 8))
  (local b 99)
  (set-forcibly! x 5)
  (set z 0)
  (global a 1)
  (set y.y false))

(set-forcibly! f 59)

(let [(boo twenty) (values :hoo 20)
      fifteen 15]
  (print boo (+ twenty fifteen)))

(fn letter []
  (let [x 19
        y 20]
    (+ x y)))

(print ((fn []
          (let [x 1]
            x))))

(fn f123 [_1]
  (let [_0 :zero]
    (print (.. _0 _1))))

(print {1 :bcd 2 ... :a :value})

(. (or (attributes path) {}) :mode)

