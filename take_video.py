from moviepy.editor import VideoFileClip
from PIL import Image
from pythonosc import udp_client
import numpy as np
import os
import time
from sklearn.cluster import KMeans
from collections import Counter
import random

SAVING_FRAMES_PER_SECOND = 0.1
client = udp_client.SimpleUDPClient("127.0.0.1", 57120) #default ip and port for SC


# not used for now
COLOR_DICT = {(0,0,0): "black", (255,255,255): "white", 
(255,0,0): "red", (128,0,128): "purple", (255,0,255): "fuchsia", (0,128,0): "green",
(255,255,0): "yellow", (0,0,255): "blue", (0,255,255): "aqua"}
# not used for now
def pick_closet_color(color):
	min_dis = 255 * 3
	res = "black"
	for key in COLOR_DICT:
		curr_dis = abs(key[0] - color[0]) + abs(key[1] - color[1]) + abs(key[1] - color[1])
		if curr_dis < min_dis:
			min_dis = curr_dis
			res = COLOR_DICT[key]
	return res


def get_frames_from_video(video_file):
    video_clip = VideoFileClip(video_file, audio=False)
    res = []
    
    # if the SAVING_FRAMES_PER_SECOND is above video FPS, then set it to FPS (as maximum)
    saving_frames_per_second = min(video_clip.fps, SAVING_FRAMES_PER_SECOND)
    # if SAVING_FRAMES_PER_SECOND is set to 0, step is 1/fps, else 1/SAVING_FRAMES_PER_SECOND
    step = 1 / video_clip.fps if saving_frames_per_second == 0 else 1 / saving_frames_per_second

    # iterate over each possible frame
    for current_duration in np.arange(0, video_clip.duration, step):
        res.append(video_clip.get_frame(current_duration))

    return res


def decide_ratio(major):
	ratio = 1
	level = 1
	# usually bright color
	if major[0] >= 200 and  major[1] >= 200 and  major[2] >= 200:
		ratio = 10
		level = 3
	elif major[0] >= 100 or  major[1] >= 100 or  major[2] >= 100:
		ratio = round(major[0]/70) + round(major[1]/70) + round(major[2]/70)
		level = 2
	# usually dull color
	else:
		ratio = random.randint(1,2)
		level = 1
	return ratio, level


def each_frame(image):
	height = len(image)
	width = len(image[0])

	# vertically split the image into 10 parts 
	ver = np.array_split(image, 10)
	notes = []
	colors = []
	dur = []
	index = random.randint(0,2)
	for v in ver:
		curr_avg = v.mean(axis=(0,1))
		# colors.append(pick_closet_color(v[0][0]))
		notes.append(round(curr_avg[index]))

	clt = KMeans(n_clusters=5)
	clt.fit(image.reshape(-1,3))
	five_main_colors = clt.cluster_centers_

	major = five_main_colors[0]
	ratio,level = decide_ratio(major)

	dur_size = ratio * random.randint(1,2)
	if ratio < 3:
		dur_size = ratio * 2
	elif ratio > 8:
		dur_size = ratio * 15
	for i in range(dur_size):
		dur.append(random.uniform(0.0,9.9))
	dur.sort()

	
	client.send_message("/notes",notes)
	client.send_message("/ratio",[ratio, len(dur), dur])
	client.send_message("/level",level)
	client.send_message("/perc_index",int(ratio-1))
	client.send_message("/perc_index2",random.randint(0,9))
	client.send_message("/compose",int(image[0][0][0]))
    


if __name__ == "__main__":

    import sys
    video_file = sys.argv[1]
    frame_array = get_frames_from_video(video_file)

    for image in frame_array:
    	each_frame(image)
    	time.sleep(8)
    

