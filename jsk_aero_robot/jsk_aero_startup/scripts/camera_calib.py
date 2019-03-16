#!/usr/bin/env python

import rospy
from geometry_msgs.msg import Transform, Vector3, Quaternion
from tf_transform import TfTransform
from std_srvs.srv import Trigger

class CameraCalib():

    def __init__(self):
        self.initial_trans = (0, 0, 0)
        self.initial_rot = (0, 0, 0, 0)
        self.camera_frame = rospy.get_param('~camera_frame')
        self.ar_marker_frame = rospy.get_param('~ar_marker_frame')
        self.original_ar_marker_frame = rospy.get_param('~original_ar_marker_frame')
        self.optical_frame_to_camera_link = ((-0.045, 0, 0), (0.5, -0.5, 0.5, 0.5))

        self.tf_transform = TfTransform()
        self.pub = rospy.Publisher('~output', Transform, queue_size=1)
        self.motion_client = rospy.ServiceProxy('/eus_motion_server/motion_server', Trigger)

        while True:
            self.main()
            rospy.sleep(0.1)

    def main(self):
        if self.motion_client() == False:
            rospy.logerr('%' %('Failed send angle vector'))
            return False

        print('------------------------------------')
        print(self.ar_marker_frame, self.camera_frame)

        trans, rot = self.tf_transform.listen(
            self.ar_marker_frame,
            self.camera_frame)

        cnt = 0
        while True:
            rospy.logwarn('try listening ...')
            if len(trans) != 0 or len(rot) != 0:
                break

            if cnt > 10:
                rospy.logwarn('cannot detect ar_marker, finish node')
                return False

            rospy.sleep(1)
            cnt += 1

        if not self.tf_transform.broadcast(
                self.original_ar_marker_frame,
                '/target_optical_frame',
                trans,
                rot):
            return False

        self.tf_transform.broadcast(
            '/target_optical_frame',
            '/target_link',
            self.optical_frame_to_camera_link[0],
            self.optical_frame_to_camera_link[1])

        # target_trans, target_rot = self.tf_transform.listen(
        #     'r_hand_link', 'target_link', 10)

        # self.pub.publish(
        #     Transform(
        #         Vector3(target_trans[0], target_trans[1], target_trans[2]),
        #         Quaternion(target_rot[0], target_rot[1], target_rot[2], target_rot[3])))

if __name__=='__main__':
    rospy.init_node('camera_calib')
    camera_calib = CameraCalib()
    rospy.spin()
