(in-package :ces/component)

(def-class render
    :slots ((render-order   0)
	    (should-render? t)))

(defmethod initialize-instace :after ((render render) &key render-order)
  (setf (:render-order render) render-order))
