(fn _ []
  (tset body (+ (length body) 1) stmt)
  (tset (. scope.symmeta (. parts 1)) :used true)
  (tset scope.symmeta 1 true)
  (global foo bar)
  (tset ids k (ast:var_declare (. vlist k))))

(fn noprint [])

(global SCREAMING_SNAKE true)

(: :abcdef :match :abc)

(local t {:t2 {:f (fn [x]
                    x)}})

(: (. t :t2) :f)

(each [k v (pairs {:a 1})]
  (set-forcibly! k :c))

(local append :two)

(noprint (.. (or base "") "_" append "_"))

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
  (noprint boo (+ twenty fifteen)))

(fn letter []
  (let [x 19
        y 20]
    (+ x y)))

(noprint ((fn []
            (let [x 1]
              x))))

(fn f123 [_1]
  (let [_0 :zero]
    (noprint (.. _0 _1))
    (values {} 2 3)))

(fn bcd [...]
  (let [t {1 :bcd 2 ... :a :value}]
    (assert (= (. t 3) :three) :three!)
    (when true
      (let [___antifnl_rtn_1___ (letter)
            ___antifnl_rtns_2___ [(f123 :a)]]
        (lua "return ___antifnl_rtn_1___, (table.unpack or _G.unpack)(___antifnl_rtns_2___)")))
    nil))

(local (_ _ two) (bcd :two :three))

(assert (= two 2) :two)

(local (world-objects will-o-the-wisp) nil)

(each [i ___match___ (ipairs {})]
  (noprint))

(. (or (f123 :path) {}) :mode)

