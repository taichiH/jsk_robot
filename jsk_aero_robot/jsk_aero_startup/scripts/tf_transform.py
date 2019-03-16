#!/usr/bin/env python

import rospy
import tf
import numpy as np

class TfTransform():
    
    def __init__(self):
        self.broadcaster = tf.TransformBroadcaster()
        self.listener = tf.TransformListener()

    def listen(self, parent_frame, child_frame, wait_time=3):
        try:
            self.listener.waitForTransform(parent_frame,
                                           child_frame,
                                           rospy.Time(0),
                                           rospy.Duration(wait_time))
            return self.listener.lookupTransform(parent_frame,
                                                 child_frame,
                                                 rospy.Time(0))
            
        except:
            rospy.logwarn('cannot lookup transform from %s to %s',
                          parent_frame, child_frame)
            return ((), ())

    def broadcast(self, parent_frame, child_frame, trans, rot):
        if len(trans) != 3 or len(rot) != 4:
            rospy.logerr('%s' %('input appropriate dimension'))
            return False

        try:
            self.broadcaster.sendTransform(
                trans, rot, rospy.Time.now(), child_frame, parent_frame)
            rospy.logwarn('broadcast %s to %s' %(parent_frame, child_frame))
            return True
        except:
            return False

if __name__=='__main__':
    tf_transform = TfTransform()

    
