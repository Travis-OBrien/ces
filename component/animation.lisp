(in-package :ces/component)

(def-class animation
    :slots ((fps nil)
	    (frame-count 0)
	    (current-frame nil)
	    (animation-name nil))
    :constructor (lambda (animation-name)
		   (set-slots animation
			      :animation-name animation-name)))

(ces/entity:def-system :animation animation
  ((scene ces/da:scene))
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
	(set-slots animation :current-frame (aref sprite-rects ani-frame-index)))))
