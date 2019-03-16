#!/usr/bin/env roseus
(ros::load-ros-manifest "roseus")
(ros::load-ros-manifest "std_srvs")

(defun motion-server (req)
  (format t "~A~%" "service called")
  (send *robot* :angle-vector (send *ri* :state :potentio-vector))
  (let ((res (send req :response)))
    (send *robot* :angle-vector #f(-54.5358 0.0 55.44 -69.961 89.86 0.0 -24.3298 63.0 -13.9963 1.49474 16.96 -135.038 0.01 0.0 0.0 -0.05 0.01 24.9128 0.0 0.01 0.0 0.0 29.986 -29.986 -29.986 29.986))
    (send *ri* :angle-vector (send *robot* :angle-vector))
    (send *ri* :wait-interpolation)
    (send res :success t)
    res))

(defun setup ()
  (load "package://aeroeus/aero-interface.l")
  (aero-init)
  (setq *robot* *aero*))

(ros::roseus "eus_motion_server")
(setup)
(format t "~A~%" "done setup")

(ros::advertise-service
 "/eus_motion_server/motion_server"
 std_srvs::Trigger #'motion-server)

(do-until-key
 (ros::spin-once))
