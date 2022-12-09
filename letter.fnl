;; Transform all do+local calls into let.
;; Normally we would do this within the anticompiler, but because of how we
;; do assignment tracking, we don't know if a local call could be replaced later
;; on with a var once we realize it's a mutable local. Because of that problem,
;; it's easier to do it in a second pass.

(local fennel (require :fennel))

(fn walk-tree [root f custom-iterator]
  "Walks a tree (like the AST), invoking f(node, idx, parent) on each node.
When f returns a truthy value, recursively walks the children."
  (fn walk [iterfn parent idx node]
    (when (f idx node parent)
      (each [k v (iterfn node)]
        (walk iterfn node k v))))
  (walk (or custom-iterator pairs) nil nil root)
  root)

(fn locals-to-bindings [node bindings]
  (let [maybe-local (. node 3)]
    (when (and (= :table (type maybe-local))
               (= :local (tostring (. maybe-local 1))))
      (table.remove node 3)
      (table.insert bindings (. maybe-local 2))
      (table.insert bindings (. maybe-local 3))
      (locals-to-bindings node bindings))))

(fn move-body [fn-node do-node do-loc]
  (for [i (# fn-node) do-loc -1]
    (table.insert do-node 2 (table.remove fn-node i))))

(fn transform-do [node]
  (let [bindings []]
    (table.insert node 2 bindings)
    (tset node 1 (fennel.sym :let))
    (locals-to-bindings node bindings)
    (when (= 2 (length node))
      (table.insert node (fennel.sym :nil)))))

(fn body-start [node]
  (let [has-name? (fennel.sym? (. node 2))]
    (if has-name? 4 3)))

(fn transform-fn [node]
  (let [do-loc (body-start node)
        do-node (fennel.list (fennel.sym :do))]
    (move-body node do-node do-loc)
    (table.insert node do-loc do-node)))

(fn do-local-node? [node]
  (and (= :table (type node)) (= :do (tostring (. node 1)))
       (= :table (type (. node 2))) (= :local (tostring (. node 2 1)))))

(fn fn-local-node? [node]
  (and (= :table (type node)) (= :fn (tostring (. node 1)))
       (let [first-body (. node (body-start node))]
         (and (= :table (type first-body))
              (= :local (tostring (. first-body 1)))))))

(fn letter [idx node]
  (when (fn-local-node? node)
    (transform-fn node))
  (when (do-local-node? node)
    (transform-do node))
  (= :table (type node)))

(fn reverse-ipairs [t] ;; based on lume.ripairs
  (fn iter [t i]
    (let [i (- i 1)
          v (. t i)]
      (if (not= v nil)
          (values i v))))
  (values iter t (+ (# t) 1)))

(fn compile [ast]
  (walk-tree ast letter reverse-ipairs))
