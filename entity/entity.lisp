(in-package :ces/entity)

;;an empty object in which all entities will implicitly extend from.
(def-class entity :slots ((valid t)
			  ;;(unique-tag (gensym))
			  ))

(def-spel def-system
    (name class scene &rest body)  
  `(progn
     (defmethod ,name ((,class ,class) (,scene ces/da::scene)) ,@body)
     (defmethod ,name ((entity ces/entity::entity) (scene ces/da::scene)) t)
     ))

(def-spel def-entity
    (name &key
	  slots
	  ;;constructor
	  with
	  ;;dependencies
	  ;;super-args
	  )
  `(def-class ,name
       :slots ,(append slots)
       ;;:constructor ,constructor
       :with ,(append with '(entity))
       ;;:dependencies ,dependencies
       ;;:super-args ,super-args
       ) )
