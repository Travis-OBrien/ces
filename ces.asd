;;;; ces.asd

(asdf:defsystem :ces
  :description "Describe ces here"
  :author "Your Name <your.name@example.com>"
  :license "Specify license here"
  
  :depends-on (:utilities)
  :serial t
  :components ((:file "package")
               (:file "ces")
	       (:file "da")
	       
	       ;base-entity
	       (:file "entity/entity")

	       ;reusable components
	       (:file "component/animation")
	       (:file "component/sprite")
	       (:file "component/render")
	       (:file "component/collider")
	       (:file "component/physics")
	       ))

