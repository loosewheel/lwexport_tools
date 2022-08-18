LW Export Tools
	by loosewheel


Licence
=======
Code licence:
LGPL 2.1

Media licence:
CC BY-SA 3.0


Version
=======
0.1.3


Minetest Version
================
This mod was developed on version 5.6.0
(but should be compatible from 5.4.0)


Dependencies
============


Optional Dependencies
=====================
intllib
default


Installation
============
Copy the 'lwexport_tools' folder to your mods folder.


Bug Report
==========
https://forum.minetest.net/viewtopic.php?f=9&t=28534


Description
===========
Tool to export from a game map. To use this tool the 'lwexport_tools'
privilege is required. This privilege is automatically granted to admins
and singleplayer.


Export Section
Gets a block volume of the map. First right click the lower left corner
closest to the player. Then the top right corner the furthest forward.
This orientation is always assumed. If the second height is less than the
first they are switched. A chat message is sent to the player when the
first position is set, and the again when the second is set. If the volume
of the section region is greater than the Maximum section volume or the
resulting buffer is greater than Maximum buffer length setting a message
is sent to the player, and the operation is cancelled. After the second
position is selected a form opens containing the data of that section. If
the buffer is large a form is display stating that the form may take a
while|long|VERY long time to display. If Continue is clicked the buffer
form is displayed. A large buffer can take many minutes for the form to
display. The contents of the buffer form can then be copied out. A log
message is issued with the volume of nodes exported and length of the
buffer for the operation. The format of this data is compatible with
lwcreative_tools buffer tool.
** This tool does not make any alterations to the map.


The mod supports the following settings:

Maximum section volume (int)
	Maximum block volume for a export section operation.
	Default: 64000

Maximum buffer length (int)
	Maximum byte length of export section operation.
	Default: 500000


------------------------------------------------------------------------
