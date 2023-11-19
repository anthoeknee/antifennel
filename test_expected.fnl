(fn _ []
  (let [;; haha
        abc :hi]
    (tset body (+ (length body) 1) stmt)
    (tset (. scope.symmeta (. parts 1)) :used true)
    (tset scope.symmeta 1 true)
    (global foo bar)
    (tset ids k (ast:var_declare (. vlist k)))))

(fn _G.abc [x] (+ x 9))

(fn noprint [])

(global SCREAMING_SNAKE true)

(: :abcdef :match :abc)

(local t {:t2 {:t4 {:f (fn [x] x)}}})

(: (. t :t2 :t4) :f)

(each [k v (pairs {:a 1})]
  (set-forcibly! k :c))

(local append :two)

(noprint (.. (or base "") "_" append "_"))

(fn f [x y] (var (z zz) (values 9 8)) ;; mutable local, immutable local
  (local b 99)
  ;; immutable local
  (set-forcibly! x 5)
  ;; changing function params
  (set z 0)
  ;; changing mutable local
  (global a 1)
  ;; setting a global
  (set y.y false)
  ;; table setter
  )

(set-forcibly! f 59)

(let [;; here
      (boo twenty) (values :hoo 20)
      fifteen 15]
  (noprint boo (+ twenty fifteen)))

(fn letter []
  (let [x 19
        y 20] (+ x y)))

(noprint ((fn [] (let [x 1] x))))

(fn f123 [/_1]
  (let [/_0 :zero] (noprint (.. /_0 /_1)) (values {} 2 3)))

(fn t.bcd [...]
  (let [t {1 :bcd :a :value}]
    (when true
      (let [___antifnl_rtn_1___ (letter)
            ___antifnl_rtns_2___ [(f123 :a)]]
        (lua "return ___antifnl_rtn_1___, (table.unpack or _G.unpack)(___antifnl_rtns_2___)")))
    nil))

(local (_ _ two) (t.bcd :two :three))

(assert (= two 2) :two)

(local (world-objects will-o-the-wisp) nil)

(each [i ___match___ (ipairs {})]
  (noprint ___match___))

(fn early-returns [some-var]
  (when true
    (let [___antifnl_rtn_1___ some-var] (lua "return ___antifnl_rtn_1___")))
  nil)

(local early-result (early-returns :success))

(assert (= early-result :success) early-result)

(for [outer 1 10] (for [inner 1 10 2] (noprint outer inner)))

(fn dynamic-step [] 3)

(for [dynamic 1 2 (dynamic-step)]
  (for [unnecessary-step 1 10] (noprint dynamic unnecessary-step)))

(print {1 1 2 2 :a 3})

(var (chr src) (values "" {}))

(set (chr src.line src.from-macro?) (values filename line true))

(let [isolated 9] nil)

(assert (= (rshift 50 1) 25))

(assert (= (lshift 1 2) 4))

(assert (= (band 50 25) 16))

(assert (= (bxor 1 2) 3))

(assert (= (bor 1 6) 7))

(assert (= (bor (length [1]) 6) 7))

(assert (= (bor 100 (lshift (rshift 99 2) 1)) 116))

(assert (= (bor 100 (lshift (rshift 99 2) 1)) 116))

(assert (= (lshift (rshift (bor 100 99) 2) 1) 50))

(assert (= (lshift (bor 100 (rshift 99 2)) 1) 248))

(assert (= (bor 100 (rshift 99 (lshift 2 1))) 102))

(assert (= (lshift (rshift 59 2) 127) 0))

(assert (= (lshift (rshift 59 2) 127) 0))

(assert (= (rshift 59 (lshift 2 127)) 59))

(assert (= (rshift (rshift 50 2) 1) 6))

(assert (= (rshift (rshift 50 2) 1) 6))

(assert (= (rshift 50 (rshift 2 1)) 25))

(assert (= (lshift (rshift 59 2) 127) 0))

(assert (= (rshift 59 (lshift 2 127)) 59))

(assert (= (lshift (lshift 50 2) 1) 400))

(assert (= (lshift (lshift 50 2) 1) 400))

(assert (= (lshift 50 (lshift 2 1)) 800))

(assert (= (bnot 1) (- 2)))

(assert (= (+ 1 (bnot 1)) (- 1)))

(assert (= (bor 1 2 3) 3))

(assert (= (bor 1 2 3) 3))

(assert (= (bor 1 2 3 4) 7))

(assert (= (bor 1 2 3 4) 7))

(assert (= (+ 1 2 3) 6))

(assert (= (+ 1 2 3 4) 10))

(assert (= (+ 1 2 3 4) 10))

(assert (= (* 1 2 3) 6))

(assert (= (* 1 2 3 4) 24))

(assert (= (* 1 2 3 4) 24))

(assert (= (bxor 1 2 3) 0))

(assert (= (bxor 1 2 3 4) 4))

(assert (= (bxor 1 2 3 4) 4))

(assert (= (band (bxor 1 2) (bxor 3 4))
           (bxor (band 1 3) (band 1 4) (band 2 3) (band 2 4))))

(assert (= (/ (/ 16 4) 4) 1))

(assert (= (/ 16 (/ 4 4)) 16))

(. (or (f123 :path) [:a :b :c]) :mode)

