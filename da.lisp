;;;;
;;CES system based on 'Direct Access' design.

(in-package :ces/da)

(def-class scene
    :slots ((window        nil)
	    (running?      t)
	    (renderer      nil)
	    (systems       (make-array 1 :adjustable t :fill-pointer 0))
	    (entities      (make-array 1 :adjustable t :fill-pointer 0))
	    (render-order  (make-vector 1
					(make-vector 1)
					(make-vector 1)
					(make-vector 1)
					(make-vector 1)
					(make-vector 1)))
	    (asset-manager  nil)
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
	       (print system)
	       (print entity)
	       (eval `(,system ,entity ,scene))))))

(export-all-symbols-except nil)
