;;;;
;;CES system based on 'Direct Access' design.

(in-package :ces/da)

(def-class scene
    :slots ((window        nil)
	    (running?      t)
	    (renderer      nil)
	    (systems       (make-vector))
	    (entities      (make-vector))
	    (render-order  (make-vector (make-vector)
					(make-vector)
					(make-vector)
					(make-vector)
					(make-vector)))
	    (asset-manager  nil)
	    (event-manager  nil)
	    (input  nil)
	    (update nil)
	    (render nil)))

(defun attach-systems
    (scene &rest system/s)
  (loop
     for system in system/s
     do
       (vector-push-extend system (:systems scene))))

(defun attach-entities
    (scene &rest entity/ies)
  (loop
     for entity in entity/ies
     do
       (vector-push-extend entity (:entities scene))))

(defun remove-entities
    (scene &rest entity/ies)
  (loop
     for e in entity/ies
     do (setf (:entities scene) (delete e (:entities scene)))))

(defun update
    (scene);(scene ces/da:scene)
  (loop for system across (:systems scene)
     do (loop for entity across (:entities scene) do
	     (progn
	       ;;(print system)
	       ;;(print entity)

	       ;;using this eval setup, we were able to bypass 'funcall'
	       ;;(eval `(,system ,entity ,scene))
	       
	       (funcall system entity scene)))))

;(export-all-symbols-except nil)
