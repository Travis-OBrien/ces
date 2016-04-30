(in-package :ces/component)

(def-class physics
    :slots ((global-gravity 0.1)
	    (local-gravity 0.0)
	    (physics-x 0)
	    (physics-y 0)))

(ces/entity::def-system :gravity
    physics scene

    
    
    (if (key-down? :w)
	(setf (:local-gravity physics) 0.0)
	
	(progn
	  ;;calculate local gravity vector
	  (setf (:local-gravity physics)
		(+ (:local-gravity physics) (:global-gravity physics)))
	  
	  (apply-force-y physics (* 1 (:local-gravity physics))))))

(defun apply-force-x
    (physics x)
  (let* ((rect (:collider-rect physics)))
    (sdl::rect-set-x rect (round (+ x (sdl::rect-get-x rect))))))
(defun apply-force-y
    (physics y)
  (let* ((rect (:collider-rect physics)))
    (sdl::rect-set-y rect (round (+ y (sdl::rect-get-y rect))))))
(defun apply-force-xy
    (physics x y)
  (let* ((rect (:collider-rect physics)))
    (sdl::rect-set-x rect (round (+ x (sdl::rect-get-x rect))))
    (sdl::rect-set-y rect (round (+ y (sdl::rect-get-y rect))))))
