(in-package :ces/component)

(def-class collider-rect
    :slots ((collider-rect nil);initialized to sdl::Rect
	    (resolve-x 0)
	    (resolve-y 0)
	    (previous-position nil);initilized to Point
	    
	    ;;collider types
	    ;;:dynamic
	    ;;:kinematic
	    ;;:movable
	    ;;:static
	    (collider-type :static)
	    ;;collider category
	    ;;:ground
	    ;;:wall
	    ;;:edge-case
	    (collider-category :edge-case)
	    ))

(defmethod initialize-instance :after
    ((collider-rect collider-rect) &key collider)
  (let* ((px (sdl::rect-get-x collider))
	 (py (sdl::rect-get-y collider)))
    (setf (:collider-rect collider-rect) collider
	  (:previous-position collider-rect) (math::point :px px :py py))))

;;TODO;;atm build-quad-tree only collects entities with colliders and stores them within scene as a vector of entities
(defun rebuild-quadtree
    (scene)
  ;;reset quadtree
  (setf (:quadtree scene) (make-vector))
  ;;attach collidable entities to quadtree
  (loop for entity across (:entities scene)
     do (if (typep entity 'collider-rect)
	    (attach (:quadtree scene) entity))))

(defun get-collider-direction
    (entity)
  (let* ((current-pos (sdl::rect-get-position (:collider-rect entity)))
	 (previous-pos (:previous-position entity))
	 (x (if (< (:px current-pos) (:px previous-pos))
		1 -1))
	 (y (if (< (:py current-pos) (:py previous-pos))
		1 -1)))
    (list x y)))

;;TODO;;atm there are no segments of a quadtree, currently just grabbing all entities within quadtree and sorting.
(defun sort-quadtree-segment
    (entities dir)
  ;;"NOTICE WE SORT Y IN TERMS OF X"
  (let* ((x (if (< (first dir) 0)
		(sort (loop
			 for entity across entities
			 when (typep entity 'ces/component::collider-rect)
			 collect entity)
		      #'ces/component::collider-x-<)
		(sort (loop
			 for entity across entities
			 when (typep entity 'ces/component::collider-rect)
			 collect entity)
		      #'ces/component::collider-x->)))
	 (y (if (< (second dir) 0)
		(sort (loop
			 for entity in x;;entities
			 when (typep entity 'ces/component::collider-rect)
			 collect entity)
		      #'ces/component::collider-y-<)
		(sort (loop
			 for entity in x;;entities
			 when (typep entity 'ces/component::collider-rect)
			 collect entity)
		      #'ces/component::collider-y->))))
    (map 'vector #'identity y)))

(ces/entity::def-system :resolve-collision-phase1
    collider-rect scene
  (cond ((eq :dynamic (:collider-type collider-rect)) (find-resolve-vectors collider-rect scene)
	 )))

(ces/entity::def-system :resolve-collision-phase2
    collider-rect scene
    (cond ((eq :dynamic (:collider-type collider-rect)) (apply-resolve-vectors collider-rect scene)
	 )))

(defun find-resolve-vectors
    (collider-rect scene)
  (loop for entity across (remove collider-rect (:quadtree scene))
     do (let* ((this-c-r (:collider-rect collider-rect))
	       (this-y (sdl::rect-get-y this-c-r))
	       (this-height (sdl::rect-get-h this-c-r))

	       (other-c-r (:collider-rect entity))
	       (other-y (sdl::rect-get-y other-c-r))
	       (other-height (sdl::rect-get-h other-c-r)))
	  (cond ((> (+ this-y this-height) other-y)
		 (progn
		   (setf (:resolve-y collider-rect) (- other-y (+ this-y this-height)))))))))

(defun apply-resolve-vectors
    (e scene)
  (loop for entity across (remove e (:quadtree scene))
     do (let* ((c-r (:collider-rect e)))
	  (sdl::rect-set-x c-r (+ (:resolve-x e) (sdl::rect-get-x c-r)))
	  (sdl::rect-set-y c-r (+ (:resolve-y e) (sdl::rect-get-y c-r)))
	  ;;reset resolve vectors
	  (setf (:resolve-x e) 0)
	  (setf (:resolve-y e) 0))))

(defun resolve-dynamic
    (scene collider other-colliders)
  (let* ((collider-path (math::line ;;:p1 (math::point :px (nth 0 (mouse-coordinate)) :py (nth 1 (mouse-coordinate)))
			  :p1 (:previous-position collider)
			  :p2 (sdl::rect-get-position (:collider-rect collider)))))
    ;;points of collider-path are currently calculated directly from rects (upper-left).
    ;;offsetting points of collider-path to center of rect (hit-box position).
    (setf (:px (:p1 collider-path)) (+ (:px (:p1 collider-path)) (/ (sdl::rect-get-w (:collider-rect collider)) 2))
	  (:py (:p1 collider-path)) (+ (:py (:p1 collider-path)) (/ (sdl::rect-get-h (:collider-rect collider)) 2))
	  (:px (:p2 collider-path)) (+ (:px (:p2 collider-path)) (/ (sdl::rect-get-w (:collider-rect collider)) 2))
	  (:py (:p2 collider-path)) (+ (:py (:p2 collider-path)) (/ (sdl::rect-get-h (:collider-rect collider)) 2)))
    (loop for c across other-colliders
       do
	 (if (AABB-collision? (:collider-rect collider) (:collider-rect c))
	     (let* ((c-expand (ces/component::AABB-expand (:collider-rect collider) (:collider-rect c))))

	       (print "AABB COLLISION")

	       (sdl::draw-lines-INGAME scene (:rect (ces/da::direct-reference scene :camera)) (list collider-path) (list '(255 255 255 255)))
	       
	       (multiple-value-bind
		     (line1 line2 line3 line4)
		   (ces/component::AABB-decompose-lines c-expand)
		 (loop for line in (list line1 line2 line3 line4)
		    do (progn
			 (if (math::line-collision? collider-path line)
			     (progn
			       (print "LINE COLLISION")
			       (multiple-value-bind
				     (normal-up normal-down)
				   (math::normal-of-line line)
				 (math::normalize-vector normal-up)
				 (math::scale-vector normal-up 100)
				 (let* ((collider-x (+ (sdl::rect-get-x (:collider-rect collider)) (/ (sdl::rect-get-w (:collider-rect collider)) 2)))
					(collider-y (+ (sdl::rect-get-y (:collider-rect collider)) (/ (sdl::rect-get-h (:collider-rect collider)) 2)))
					(new-collision-ray (math::line :p1 (math::point :px collider-x :py collider-y)
								       :p2 (math::point :px (+ collider-x (:vx normal-up))
											:py (+ collider-y (:vy normal-up))))))
				   
				   (multiple-value-bind
					 (point)
				       (math::line-intersection-point new-collision-ray line)
				     (let* ((x (:px point))
					    (y (:py point))
					    (r (sdl::new-rect (round x) (round y) 10 10)))
				       (if (and x y) (progn
						       (sdl::rect-set-position (:collider-rect collider)
									       ;;rounding values to convert from double to int
									       (round [ x - (/ (sdl::rect-get-w
												(:collider-rect collider)) 2)])
									       (round [ y - (/ (sdl::rect-get-h
												(:collider-rect collider)) 2)])))
					   ;;(print "denom 0")
					   )))))

			       ;;TEST;;return after first line collision for debugging
			       ;;how is this working properly?? it's working the same as if there is no return!
			       ;;is return actually exiting the loop?
			       (return))
			     (print "no collision..."))))))))))

(ces/entity::def-system :collider-sync-viewport
    collider-rect scene
    (let* ((x (sdl::rect-get-x (:collider-rect collider-rect)))
	   (y (sdl::rect-get-y (:collider-rect collider-rect)))
	   (x-offset (:offset-x collider-rect))
	   (y-offset (:offset-y collider-rect)))
      (sdl::rect-set-position (:viewport collider-rect) (+ x x-offset) (+ y y-offset))))

(ces/entity::def-system :collider-previous-position
    collider-rect scene
    ;;store previous position
    (setf (:previous-position collider-rect) (sdl::rect-get-position (:collider-rect collider-rect))))

(ces/entity::def-system :debug-collider-rect
    collider-rect scene
    (let* ((collider (:collider-rect collider-rect))
	   (camera (:rect (ces/da::direct-reference scene :camera)))
	   (camera-offset (ces/da::direct-reference scene :recycle-rect)))
      ;;set camera offsets
      (sdl::rect-set-x camera-offset
		       (- (sdl::rect-get-x collider) (sdl::rect-get-x camera)))
      (sdl::rect-set-y camera-offset
		       (- (sdl::rect-get-y collider) (sdl::rect-get-y camera)))
      ;;sync camera and entity scale
      
      (sdl::rect-set-w camera-offset (sdl::rect-get-w  collider))
      (sdl::rect-set-h camera-offset (sdl::rect-get-h collider))
      (sdl::set-render-draw-color (:renderer scene) 0 255 0 255)
      (sdl::sdl-renderdrawrect (:renderer scene) camera-offset)))

(defun AABB-expand
    (rect-1 rect-2)
  (let* ((r1-/w  (/ (sdl::rect-get-w rect-1) 2))
	 (r1-/h  (/ (sdl::rect-get-h rect-1) 2))
	 (r1-w      (sdl::rect-get-w rect-1))
	 (r1-h      (sdl::rect-get-h rect-1))
	 (r2-w      (sdl::rect-get-w rect-2))
	 (r2-h      (sdl::rect-get-h rect-2))
	 (r2-x      (sdl::rect-get-x rect-2))
	 (r2-y      (sdl::rect-get-y rect-2))
	 (r2-x-c (+ r2-x (/ r2-w 2)))
	 (r2-y-c (+ r2-y (/ r2-h 2)))
	 (r3        (sdl::new-rect 0 0 (+ r1-w r2-w) (+ r1-h r2-h)))
	 (r3-/2w (/ (sdl::rect-get-w r3) 2))
	 (r3-/2h (/ (sdl::rect-get-h r3) 2)))
    (sdl::rect-set-position r3 (- r2-x-c r3-/2w) (- r2-y-c r3-/2h))))

(defun AABB-decompose-lines
    (rect)
  (let* ((x (sdl::rect-get-x rect))
	 (y (sdl::rect-get-y rect))
	 (w (sdl::rect-get-w rect))
	 (h (sdl::rect-get-h rect))
	 ;;clockwise
	 (p1 (math::point :px x       :py y))
	 (p2 (math::point :px (+ x w) :py y))
	 (p3 (math::point :px (+ x w) :py (+ y h)))
	 (p4 (math::point :px x       :py (+ y h)))
	 (line1 (math::line :p1 p1 :p2 p2))
	 (line2 (math::line :p1 p2 :p2 p3))
	 (line3 (math::line :p1 p3 :p2 p4))
	 (line4 (math::line :p1 p4 :p2 p1)))
    (values line1 line2 line3 line4)))

(defun AABB-collision?
    (c1 c2)
  (let* ((c1-x  (sdl::rect-get-x c1))
	 (c1-y  (sdl::rect-get-y c1))
	 (c1-w  (sdl::rect-get-w c1))
	 (c1-h  (sdl::rect-get-h c1))

	 (c2-x  (sdl::rect-get-x c2))
	 (c2-y  (sdl::rect-get-y c2))
	 (c2-w  (sdl::rect-get-w c2))
	 (c2-h  (sdl::rect-get-h c2))

	 (x-axis (cond ((and (> (+ c1-x c1-w) c2-x) (< c1-x (+ c2-x c2-w))) t)
		       (:didnt-find-sheeeeeeeeeeeit nil)))
	 (y-axis (cond ((and (> (+ c1-y c1-h) c2-y) (< c1-y (+ c2-y c2-h))) t)
		       (:didnt-find-sheeeeeeeeeeeit nil))))
    (and x-axis y-axis)))

(defun collider-x-<
    (&rest objs)
  (eval (cons '< (loop for obj in objs collect
		      `(sdl::rect-get-x (:collider-rect ,obj))))))
(defun collider-x->
    (&rest objs)
  (eval (cons '> (loop for obj in objs collect
		      `(sdl::rect-get-x (:collider-rect ,obj))))))
(defun collider-y-<
    (&rest objs)
  (eval (cons '< (loop for obj in objs collect
		      `(sdl::rect-get-y (:collider-rect ,obj))))))
(defun collider-y->
    (&rest objs)
  (eval (cons '> (loop for obj in objs collect
		      `(sdl::rect-get-y (:collider-rect ,obj))))))
