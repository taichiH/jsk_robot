(require :aero "package://aeroeus/aero.l")
(require :aero-utils "package://aeroeus/aero-utils.l")
(require :aero-hand "package://aeroeus/aero-hand.l")
(require :robot-interface "package://pr2eus/robot-interface.l")

(ros::load-ros-manifest "seedhand_std")

(defclass aero-interface
  :super robot-move-base-interface
  :slots (hand-interface)
  )
(defmethod aero-interface
  (:init
   (&rest args)
   (let ((r (instance aero-lifter-ik :init)))
     ;; make controller configuration from joint-list
     (dolist (limb (list 'larm 'rarm))
       (let ((key (intern (string limb) *keyword-package*))
             (mname (intern (string-upcase (format nil "~A-controller" limb)) *keyword-package*))
             )
         ;;
         (eval
          `(defmethod aero-interface
             (,mname
              nil
              (list
               (list
                (cons :controller-action ,(format nil "~A_controller/follow_joint_trajectory" limb) )
                (cons :controller-state  ,(format nil "~A_controller/state" limb) )
                (cons :action-type control_msgs::FollowJointTrajectoryAction)
                (cons :joint-names
                      ',(mapcar #'(lambda (j) (send j :name)) (send r key :joint-list)) )
                )
               )))
          )
         ))
     ;;
     (send-super*
      :init
      :robot r
      :move-base-action-name "move_base"
      :base-frame-id "/base_link"
      :odom-topic "/odom"
      :groupname "aero_interface" args)
     )
   ;;
   (dolist (ct (list :rarm-controller
                     :larm-controller
                     :head-controller
                     :waist-controller
                     :lifter-controller))
     (send self :add-controller ct :create-actions nil))
   (setq hand-interface
         (instance aero-hand-interface :init))
   (setq set-hand-srv
         (instance seedhand_std::SetHandRequest :init))
   )
  ;;
  (:default-controller nil
   (append (send self :rarm-controller)
           (send self :larm-controller)
           (send self :head-controller)
           (send self :waist-controller)
           (send self :lifter-controller)))
  #|
  (:rarm-controller nil
   (list
    (list
     (cons :controller-action "rarm_controller/follow_joint_trajectory")
     (cons :controller-state  "rarm_controller/state")
     (cons :action-type control_msgs::FollowJointTrajectoryAction)
     (cons :joint-names (list "r_shoulder_p_joint" "r_shoulder_r_joint" "r_shoulder_y_joint"
                              "r_elbow_joint" "r_wrist_y_joint" "r_wrist_p_joint" "r_wrist_r_joint"
                              "r_hand_y_joint"
                              ))
     ))
   )
  (:larm-controller nil
   (list
    (list
     (cons :controller-action "larm_controller/follow_joint_trajectory")
     (cons :controller-state  "larm_controller/state")
     (cons :action-type control_msgs::FollowJointTrajectoryAction)
     (cons :joint-names (list "l_shoulder_p_joint" "l_shoulder_r_joint" "l_shoulder_y_joint"
                              "l_elbow_joint" "l_wrist_y_joint" "l_wrist_p_joint" "l_wrist_r_joint"
                              "l_hand_y_joint"
                              ))
     ))
   )
  |#
  (:head-controller nil
   (list
    (list
     (cons :controller-action "head_controller/follow_joint_trajectory")
     (cons :controller-state  "head_controller/state")
     (cons :action-type control_msgs::FollowJointTrajectoryAction)
     (cons :joint-names (list "neck_y_joint" "neck_p_joint" "neck_r_joint"))
     ))
   )
  (:waist-controller nil
   (list
    (list
     (cons :controller-action "waist_controller/follow_joint_trajectory")
     (cons :controller-state  "waist_controller/state")
     (cons :action-type control_msgs::FollowJointTrajectoryAction)
     (cons :joint-names (list "waist_y_joint" "waist_p_joint" "waist_r_joint"))
     ))
   )
  (:lifter-controller nil
   (list
    (list
     (cons :controller-action "lifter_controller/follow_joint_trajectory")
     (cons :controller-state  "lifter_controller/state")
     (cons :action-type control_msgs::FollowJointTrajectoryAction)
     (cons :joint-names (list "ankle_joint" "knee_joint"))
     ))
   )
  (:start-grasp
   (&optional (arm :arms) &key ((:gain g) 0.01))
   (send hand-interface :grasp arm)
   )
  (:stop-grasp
   (&optional (arm :arms) &key (wait nil))
   (send hand-interface :ungrasp arm)
   )
  (:angle-index-finger
   (&key (arm :rarm) (angle 0.0) (time 5.0))
   (if (eq arm :rarm)
       (send set-hand-srv :arm "rarm")
     (send set-hand-srv :arm "larm"))
   (send set-hand-srv :finger "index")
   (send set-hand-srv :index_angle angle)
   (send set-hand-srv :time time)
   (send (ros::service-call "/seedhand_server/set_hand" set-hand-srv) :status)
   )
  (:angle-thumb-finger
   (&key (arm :rarm) (angle 0.0) (time 5.0))
   (cond
    ((eq arm :rarm)
     (send set-hand-srv :arm "rarm")
     (send set-hand-srv :finger "thumb")
     )
    ((eq arm :larm)
     (send set-hand-srv :arm "larm")
     (send set-hand-srv :finger "trx")
     )
    (t
     ))
   (send set-hand-srv :thumb_angle angle)
   (send set-hand-srv :time time)
   (send (ros::service-call "/seedhand_server/set_hand" set-hand-srv) :status)
   )
  (:angle-both-finger
   (&key (arm :rarm) (thumb-angle 0.0) (index-angle 0.0) (time 5.0))
   (send set-hand-srv :arm "rarm")
   (send set-hand-srv :finger "both")
   (send set-hand-srv :thumb_angle thumb-angle)
   (send set-hand-srv :index_angle index-angle)
   (send set-hand-srv :time time)
   (send (ros::service-call "/seedhand_server/set_hand" set-hand-srv) :status)
   )
  )



(defun aero-init (&rest args)
  (if (not (boundp '*ri*))
      (setq *ri* (instance* aero-interface :init args)))
  (if (not (boundp '*robot*))
      (setq *robot* (aero-robot)))
  )

#|
(aero-init)
(send *ri* :state)
(send *robot* :angle-vector (send *ri* :state :reference-vector))
(send *robot* :angle-vector (send *ri* :state :potentio-vector))

(send *ri* :angle-vector (send *robot* :angle-vector) 1000)

;; should add controllers
(send *ri* :angle-vector (send *robot* :angle-vector) 1000 :larm-controller)
(send *ri* :angle-vector (send *robot* :angle-vector) 1000 :rarm-controller)
(send *ri* :angle-vector (send *robot* :angle-vector) 1000 :waist-controller)
(send *ri* :angle-vector (send *robot* :angle-vector) 1000 :lift-controller)
(send *ri* :angle-vector (send *robot* :angle-vector) 1000 :head-controller)

(send *robot* :angle-vector (send *ri* :state :potentio-vector))

(send *robot* :larm :elbow-p :joint-angle -30)
(send *ri* :angle-vector (send *robot* :angle-vector) 4000)

(send *robot* :torso :lifter-ankle :joint-angle 30)
(send *robot* :torso :lifter-knee  :joint-angle -30)
(send *ri* :angle-vector (send *robot* :angle-vector) 4000)

(send *robot* :torso :lifter-ankle :joint-angle 45)
(send *robot* :torso :lifter-knee  :joint-angle -45)
(send *ri* :angle-vector (send *robot* :angle-vector) 4000)

(dolist (j (send *robot* :joint-list))
  (format t "\"~A\" ~5,5F ~5,5F~%"
          (send j :name)
          (deg2rad
           (+ (* 0.75 (send j :max-angle))
              (* 0.25 (send j :min-angle))))
          (deg2rad
           (+ (* 0.25 (send j :max-angle))
              (* 0.75 (send j :min-angle))))
          ))
|#

;; grasp by finger angle
(defun start-pinch (arm &optional (time 3000) (trx-angle 0.0))
  (cond
   ((eq arm :rarm)
    (send *ri* :angle-index-finger :angle 0.3 :time (* time 0.001) :arm :rarm)
    (unix:usleep (* 1000 time))
    (send *ri* :angle-thumb-finger :angle -0.05 :time (* time 0.001) :arm :rarm)
    (unix:usleep (* 1000 time))
    )
   ((eq arm :larm)
    (send *ri* :angle-thumb-finger :angle trx-angle :time (* time 0.001) :arm :larm)
    (unix:usleep (* 1000 time))
    )
   (t
    (ros::ros-warn "set arm argument {:rarm or :larm}")
    nil
    ))
  )
;;
;; open by finger angle
(defun stop-pinch (arm &optional (time 3000))
  (cond
   ((eq arm :rarm)
    (send *ri* :angle-index-finger :angle -0.9 :time (* time 0.001) :arm arm)
    (unix:usleep (* 1000 time))
    (send *ri* :angle-thumb-finger :angle 0.25 :time (* time 0.001) :arm arm)
    (unix:usleep (* 1000 time))
    )
   ((eq arm :larm)
    (send *ri* :angle-thumb-finger :angle -0.3 :time (* time 0.001) :arm arm)
    (unix:usleep (* 1000 time))
    )
   (t
    (ros::ros-warn "set arm argument {:rarm or :larm}")
    nil
    ))
  )
