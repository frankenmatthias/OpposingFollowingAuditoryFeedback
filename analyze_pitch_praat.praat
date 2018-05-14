# Script to read data created by Audapter, and save pitch contours as TableOfReal files.
#
# MKF, 2017

form Input
	sentence path path
	word session 29
	word subject 29
	boolean female 1 
	word block rand2
endform

if female > 0
	minpitch = 100
else
	minpitch = 75
endif

Create Strings as file list: "fileList", "'path$'\'session$'\'session$'\'block$'\rep1\*.wav"

n = Get number of strings

for i to n
	select Strings fileList
	file$ = Get string: i
	Read from file: "'path$'\'session$'\'session$'\'block$'\rep1\'file$'"
	sound'i'= selected("Sound")
endfor

for i to n
	select sound'i'
	obj_name$ = selected$("Sound")
	pitch = To Pitch (ac): 0.001, 'minpitch', 15, "yes", 0.03, 0.45, 0.01, 0.35, 0.7, 600

	pitch2 = Kill octave jumps
	nframes = Get number of frames
	begintime = Get time from frame number: 1
	endtime = Get time from frame number: 'nframes'
	writeFileLine: "'path$'\'session$'\'session$'\'block$'\rep1\'obj_name$'.txt", "nframes ", 'nframes'
	appendFileLine: "'path$'\'session$'\'session$'\'block$'\rep1\'obj_name$'.txt", "begin ", 'begintime'
	appendFileLine: "'path$'\'session$'\'session$'\'block$'\rep1\'obj_name$'.txt", "end ", 'endtime'
	matrix = To Matrix

	table = To TableOfReal
	Save as short text file: "'path$'\'session$'\'session$'\'block$'\rep1\'obj_name$'.TableOfReal"
	select sound'i'
	plus pitch
	plus pitch2

	plus table
	plus matrix
	Remove
endfor