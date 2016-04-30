(in-package :ces/component)

(def-class sprite
    :slots ((frame nil)
	    (sprite-name nil)))

(ces/entity::def-system :sprite
    sprite scene
    (setf (:frame sprite) (:sprite-coordinate (gethash (:sprite-name sprite) (:sprites (:asset-manager scene))))))
