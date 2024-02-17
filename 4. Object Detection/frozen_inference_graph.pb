# 2_frozen_inference_graph.pb

#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import time

import cv2
import numpy as np
import tensorflow as tf

#--------------Model preparation----------------
# Path to frozen detection graph. This is the actual model that is used for 
# the object detection.
#PATH_TO_CKPT = './frozen_inference_graph.pb'
#PATH_TO_CKPT = "/home/ravindu-aratchige/Documents/KDU/Academics/Semester 5/Image Processing and Computer Vision/IPCV on GitHub/4. Object Detection/frozen_inference_graph.pb"

# Load a (frozen) Tensorflow model into memory
detection_graph = tf.Graph()
with detection_graph.as_default():
  od_graph_def = tf.GraphDef()
  with tf.gfile.GFile(PATH_TO_CKPT, 'rb') as fid:
    serialized_graph = fid.read()
    od_graph_def.ParseFromString(serialized_graph)
    tf.import_graph_def(od_graph_def, name='')
    
image_tensor = detection_graph.get_tensor_by_name('image_tensor:0')
# Each box represents a part of the image where a particular 
# object was detected.
gboxes = detection_graph.get_tensor_by_name('detection_boxes:0')
# Each score represent how level of confidence for each of the objects.
# Score is shown on the result image, together with the class label.
gscores = detection_graph.get_tensor_by_name('detection_scores:0')
gclasses = detection_graph.get_tensor_by_name('detection_classes:0')
gnum_detections = detection_graph.get_tensor_by_name('num_detections:0')


# TODO: Add class names showing in the image
def detect_image_objects(image, sess, detection_graph):
    # Expand dimensions since the model expects images to have 
    # shape: [1, None, None, 3]
    image_np_expanded = np.expand_dims(image, axis=0)

    # Actual detection.
    (boxes, scores, classes, num_detections) = sess.run(
        [gboxes, gscores, gclasses, gnum_detections],
        feed_dict={image_tensor: image_np_expanded})

    # Visualization of the results of a detection.
    boxes = np.squeeze(boxes)
    scores = np.squeeze(scores)
    height, width = image.shape[:2]
    for i in range(boxes.shape[0]):
        if (scores is None or 
            scores[i] > 0.5):
            ymin, xmin, ymax, xmax = boxes[i]
            ymin = int(ymin * height)
            ymax = int(ymax * height)
            xmin = int(xmin * width)
            xmax = int(xmax * width)
            
            score = None if scores is None else scores[i]
            font = cv2.FONT_HERSHEY_SIMPLEX
            text_x = np.max((0, xmin - 10))
            text_y = np.max((0, ymin - 10))
            cv2.putText(image, 'Detection score: ' + str(score),
                        (text_x, text_y), font, 0.4, (0, 255, 0))
            cv2.rectangle(image, (xmin, ymin), (xmax, ymax),
                          (0, 255, 0), 2)
    return image


with detection_graph.as_default():
    with tf.Session(graph=detection_graph) as sess:
        video_path = 'path_to_your_video'
        capture = cv2.VideoCapture(video_path)
        while capture.isOpened():
            if cv2.waitKey(30) & 0xFF == ord('q'):
                break
            ret, frame = capture.read()
            if not ret:
                break

            t_start = time.clock()
            detect_image_objects(frame, sess, detection_graph)
            t_end = time.clock()
            print('detect time per frame: ', t_end - t_start)
            cv2.imshow('detected', frame)
        capture.release()
        cv2.destroyAllWindows()
