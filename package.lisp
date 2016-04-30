;;;; package.lisp

(defpackage :ces/da
  (:use #:cl :utilities :sdl :game-utilities/event-manager))

(defpackage :ces
  (:use #:cl :utilities))

;component packages
(defpackage :ces/component
  (:use #:cl :utilities :game-utilities/event-manager))

;entity packages
(defpackage :ces/entity
  (:use #:cl :utilities :game-utilities/event-manager))
