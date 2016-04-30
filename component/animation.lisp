(in-package :ces/component)

(def-class animation
    :slots ((fps nil)
	    (frame-count 0)
	    (current-frame nil);;holds a reference to a rectangle within asset-manager
	    (animation-name nil)))

;(ces/entity:def-system :animation animation
;  ((scene ces/da::scene))
(ces/entity::def-system :animation
    animation scene
    (let* ((animations (:animations (:asset-manager scene)))
	   (animation-name (:animation-name animation))
	   (ani (gethash (:animation-name animation) animations)) ;(:animation-name animation)
	   (sprite-rects (:sprite-coordinates ani))
	   (sprite-count (length sprite-rects))
	   (f-c (:frame-count animation))
	   (fps (:fps (gethash animation-name (:animations (:asset-manager scene))))))
      
      (setf (:frame-count animation) [f-c + 1])
      (let* ((floored-frame-count (floor [f-c / fps]))
	     (ani-frame-index (if (> floored-frame-count (- sprite-count 1))
					;then
				  (progn
				    (setf (:frame-count animation) 0)
				    0)
					;else
				  floored-frame-count)))
	(setf (:current-frame animation) (aref sprite-rects ani-frame-index)))))

(defmethod initialize-instance :after ((animation animation) &key animation-name)
  (setf (:animation-name animation) animation-name))

(defmethod reset
    ((animation animation) scene &rest animation-names)
  (loop
     for name in animation-names
     do
       (let* ((animations (:animations (:asset-manager scene)))
	      (original-frame (aref (:sprite-coordinates (gethash (:animation-name animation) (:animations (:asset-manager scene)))) 0)))
	 (setf
	  (:frame-count   animation) 0
	  (:current-frame animation) original-frame))))
