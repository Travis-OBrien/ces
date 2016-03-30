;;;;
;;CES system based on 'Direct Access' design.

(in-package :ces/da)
;(in-package #:utilities)
;(print "kek")
;(defclass kek ()())
(def-class scene
    :slots ((window        nil)
	    (running?      t)
	    (renderer      nil)
	    (systems       (make-array 1 :adjustable t :fill-pointer 0))
	    (entities      (make-array 1 :adjustable t :fill-pointer 0))
	    (render-order  (make-map 1 (make-array 1 :adjustable t :fill-pointer 0)
				     2 (make-array 1 :adjustable t :fill-pointer 0)
				     3 (make-array 1 :adjustable t :fill-pointer 0)
				     4 (make-array 1 :adjustable t :fill-pointer 0)
				     5 (make-array 1 :adjustable t :fill-pointer 0)))
	    (asset-manager  nil)

	    (input  nil)
	    (update nil)
	    (render nil)
	    
	    ;TESTING BELOW!
	    (texture nil)
	    (ani-obj nil)
	    ))

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
    (scene)
  (loop for system across (:systems scene)
     do (loop for entity across (:entities scene) do
	     (eval `(,system ,entity)))))





(export-all-symbols-except nil)
