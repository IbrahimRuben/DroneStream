import json

import paho.mqtt.client as mqtt

import cv2 as cv
import numpy as np


import base64
import time
import threading


def SendVideoStream ():
    global sendingVideoStream
    global cap
    global client
    

    while sendingVideoStream:
        fps = 1/20
        width = 640
        height = 480
        quality = 75
       
        # Read Frame
        _, frame = cap.read()
        
        # Reducing resolution (e.g., to 640x480)
        resized_frame = cv.resize(frame, (width, height))

        # Check actual resolution
        #height, width, _ = resized_frame.shape
        print(f"Resolución actual: {width}x{height}")

        # Take a JPG picture
        _, buffer = cv.imencode('.jpg', resized_frame, [int(cv.IMWRITE_JPEG_QUALITY), quality])
        
        # Converting into encoded bytes
        jpg_as_text = base64.b64encode(buffer)
        client.publish('videoFrame', jpg_as_text)
        print(len(jpg_as_text))
        time.sleep(fps)

def on_connect(client, userdata, flags, rc):
    if rc==0:
        print("connected OK Returned code =",rc)
    else:
        print("Bad connection Returned code =",rc)

def on_message(cli, userdata, message):

    global sendingVideoStream
    global client

    if message.topic == 'Connect':
        print ('connected')
        #client.subscribe('getValue')
        #client.subscribe('writeParameters')
        client.subscribe('StartVideoStream')

    '''if message.topic == 'getValue':
        print ('envio valor')
        client.publish('Value', 25)
    if message.topic == 'writeParameters':
        parameters = json.loads(message.payload.decode("utf-8"))
        print (parameters)'''
    if message.topic == 'StartVideoStream':
        print ('start video stream')
        client.subscribe('StopVideoStream')
        sendingVideoStream = True
        w = threading.Thread(target=SendVideoStream)
        w.start()
    if message.topic == 'StopVideoStream':
        print ('stop video stream')
        sendingVideoStream = False


def DummyService ():
    global cap
    global client
    
    #this.client = mqtt.connect("ws://broker.emqx.io:8083/mqtt")
    broker_address = "classpip.upc.edu"
    broker_port = 8000
    
    #broker_address = "broker.emqx.io"
    #broker_port = 8083


    cap = cv.VideoCapture(0)
    
    client = mqtt.Client(transport="websockets")
    client.username_pw_set(username='*********',password='**********')
    client.on_message = on_message
    client.on_connect = on_connect
    client.connect(broker_address, broker_port)
    client.subscribe('Connect')
    print ('Waiting connection')
    client.loop_forever()

if __name__ == '__main__':
    # test1.py executed as script
    # do something
    DummyService()
