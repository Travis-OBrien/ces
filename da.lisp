;;;;
;;CES system based on 'Direct Access' design.

(in-package :ces/da)

(def-class scene
    :slots ((window        nil)
	    (running?      t)
	    (renderer      nil)
	    (systems       (make-vector))
	    (systems-debug (make-vector))
	    (entities      (make-vector))
	    (render-order  (make-vector (make-vector)
					(make-vector)
					(make-vector)
					(make-vector)
					(make-vector)))
	    (asset-manager  game-utilities/asset-manager::asset-manager)
	    (input        nil)
	    (update       nil)
	    (render       nil)
	    (debug-entity nil)
	    ;;quick access variables will be stored here
	    (direct-reference (make-hash-table))
	    ;;TODO;;quad-tree is a simple vector storing entities with colliders
	    (quad-tree (make-vector))
	    ))

(defun attach-systems
    (scene &rest system/s)
  (loop
     for system in system/s
     do
       (vector-push-extend system (:systems scene))))

(defun attach-systems-debug
    (scene &rest system/s)
  (loop
     for system in system/s
     do
       (vector-push-extend system (:systems-debug scene))))

(defun attach-entities
    (scene &rest entity/ies)
  (loop
     for entity in entity/ies
     do
       (progn (vector-push-extend entity (:entities scene))
	      ;;automatically try to attach this entity to the scene's :render-order
	      (if (:render-order entity)
		  ;;(attach (aref (:render-order scene) (:render-order entity)) entity)
		  (vector-push-extend entity (aref (:render-order scene) (:render-order entity)))
		  ))))

(defun remove-entities
    (scene &rest entity/ies)
  (loop
     for e in entity/ies
     do (setf (:entities scene) (delete e (:entities scene)))))

(defun find-entity
    (scene tag)
  (loop for entity across (:entities scene)
     do (if (eq (:tag entity) tag)
	    (return entity))))

(defun direct-reference
    (scene tag)
  (gethash tag (:direct-reference scene)))
(defun new-direct-reference
    (scene obj tag)
  (attach (:direct-reference scene) tag obj))

(defun update
    (scene);(scene ces/da:scene)
  (let* ((invalid-entities (make-vector)))
    (loop for system across (:systems scene)
       do (loop for entity across (:entities scene) do
	       (if (:valid? entity)
		   (progn
		     ;;(print system)
		     ;;(print entity)

		     ;;using this eval setup, we were able to bypass 'funcall'
		     ;;(eval `(,system ,entity ,scene))
		     
		     (funcall system entity scene))

		   ;;found an invalid entity
		   (progn
		     (detach (:entities scene) entity)
		     (detach (aref (:render-order scene) (:render-order entity)) entity)))))))

(defun debug-entity
    (scene)
  (loop for system across (:systems-debug scene)
     do (loop for entity across (:entities scene)
	   do (funcall system entity scene))))

(defun render
    (scene)
  (let* ((renderer (:renderer scene))
	 (camera (:rect (ces/da::direct-reference scene :camera)))
	 (camera-offset (sdl::rect-set-all (ces/da::direct-reference scene :recycle-rect)
					   0 0
					   (sdl::rect-get-w camera) (sdl::rect-get-h camera))))
    
    ;;set render draw color to black
    (set-render-draw-color (:renderer scene) 0 0 0 255)
    ;;clear renderer with color
    (render-clear (:renderer scene))

    (sdl::update-viewport (:window scene))
    
    ;;only render the screen's dimensions.
    (sdl-rendersetviewport renderer (:viewport (:window scene)))
    ;;first iteration grabs the render-order map and looks up an index wich returns an array.
    (loop
       for render-order across (:render-order scene)
       do
       ;;second iteration iterates across the array which will grab entities to render.
	 (loop
	    for entity across render-order
	    do
	      (progn
		;;set camera offsets
		(sdl::rect-set-x camera-offset
				 (- (sdl::rect-get-x (:viewport entity)) (sdl::rect-get-x camera)))
		(sdl::rect-set-y camera-offset
				 (- (sdl::rect-get-y (:viewport entity)) (sdl::rect-get-y camera)))
		;;sync camera and entity scale
		(sdl::rect-set-w camera-offset (sdl::rect-get-w  (:viewport entity)))
		(sdl::rect-set-h camera-offset (sdl::rect-get-h (:viewport entity)))
		(if (typep entity 'ces/component::animation)
		    (sdl-rendercopyex renderer
				      ;;texture to sample from.
				      ;;grab the animation's name from the entity object, then look up the animation
				      ;;within the asset-manager to find the texture it uses.
				      (gethash
				       (:texture (gethash (:animation-name entity) (:animations (:asset-manager scene))))
				       (:images (:asset-manager scene)))
				      
				      ;;entity's sprite coordinate
				      (:current-frame entity)
				      ;;control the scale & position
				      ;;(:viewport entity)
				      camera-offset
				      
				      (:angle entity)
				      (:pivot-point entity)
				      (cffi:foreign-enum-value 'sdl-rendererflip (:flip-dir entity)))
		    (sdl-rendercopyex renderer
				      ;;texture to sample from.
				      ;;grab the animation's name from the entity object, then look up the animation
				      ;;within the asset-manager to find the texture it uses.
				      (gethash
				       (:texture (gethash (:sprite-name entity) (:sprites (:asset-manager scene))))
				       (:images (:asset-manager scene)))
				      
				      ;;entity's sprite coordinate
				      (:frame entity)
				      ;;control the scale & position
				      ;;(:viewport entity)
				      camera-offset
				      
				      (:angle entity)
				      (:pivot-point entity)
				      (cffi:foreign-enum-value 'sdl-rendererflip (:flip-dir entity)))))))

    ;;render debug
    (funcall (:debug-entity scene) scene)

    ;;finally, render everything to the screen.
    (render-present renderer)))

(defun quit
    (scene)
  ;;clear memory from entities
  (loop for entity across (:entities scene) do
       (progn
	 (print entity)
	 (:mem-management entity)))

  ;;clear rects (sprite-coordinates) from asset-manager
  (loop for animation being the hash-values of (:animations (:asset-manager scene))
	      do (loop for rect across (:sprite-coordinates animation)
		      do (sdl::delete-rect rect)))
  ;;clear textures from asset-manager
  (loop for texture being the hash-values of (:images (:asset-manager scene))
     ;;using (hash-key key)
     do (sdl::sdl-destroytexture texture))
  ;;clear audio-bites from asset-manager
  (loop for audio-bite being the hash-values of (:audio-bites (:asset-manager scene))
     do (sdl::mix-freechunk audio-bite))
  ;;clear audio-music from asset-manager
  (loop for audio-music being the hash-values of (:audio-music (:asset-manager scene))
     do (sdl::mix-freemusic audio-music))

  (sdl::destroy-renderer (:renderer scene))
  (sdl::destroy-window (:address (:window scene)))
  ;;check into this and learn something, when using 'quit' which is an from our wrapper for sdl .dll
  ;;the compiler throws an error complaining about wrong number of args: 0
  ;;even when this fn is namespaced (sdl::quit) it still fails!
  ;;(sdl::quit)
  (sdl::mix-quit)
  (sdl::img-quit)
  (sdl::sdl-quit)
  (setf (:running? scene) nil))

;(export-all-symbols-except nil)
