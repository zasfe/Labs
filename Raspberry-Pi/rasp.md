Official 7" Raspberry Pi Touch Screen FAQ
####Minor updates 2017/03/15

Added mention of Pi 3
Added mention of CM and CM3 plus link
Dropped note about NOOBS not working, it now does
Added note about brightness control
No. You still can’t use HDMI and the display at the same time! (Other than apps like OMXPlayer)
Either you’ve just ordered your lovely new 7" Touch Screen, or you’re thinking about it. This thread is the place to be.

We’ll be collating all the common questions, and hopefully some good answers, right here for your convenience.

You should check out our first Bilge Tank episode for an introduction to the LCD: https://www.youtube.com/watch?v=b2dYE0qic6c

TLDR
It’s easier to use a Model A+, B+, Pi 2 or Pi 3 with the TouchScreen (You can use an original Model A or B Pi, but you’ll lose i2c functionality)
You should download the latest Raspbian image from RaspberryPi.org
You really should use an official Pi power supply
Both the display driver board and the Pi need power- you can bridge them using the red and black jump wires supplied from the 5v and GND on the display driver board to the 5V and GND on the Pi ( find them here: http://pi.gadgetoid.com/pinout ) then plug the power into the display board.
If your touchscreen or display doesn’t work, triple check the FPC connectors - I’ve tested a lot of “not working” LCDs to find them working perfectly. In all cases the cables should be pushed in firmly and the clips secured fully- the larger FPC for the display ribbon takes quite a bit of force. I’ve posted a guide to the FPC connectors here: http://forums.pimoroni.com/t/raspberry-pi-official-Raspberry Pi Official 7-touchscreen-assembly/1132" Touchscreen Assembly
If you’ve got any reservations about connecting wires to your Pi’s GPIO, I recommend our split dial microB USB power cable: https://shop.pimoroni.com/products/split-microb-usb-power-cable

Before you begin
Make sure you update your Pi first, you’ll need the latest software and the Raspbian OS in order to drive the screen. A full reinstall of Raspbian Jessie works best, you can find it here: https://www.raspberrypi.org/downloads/raspbian/

Follow the linked Installation Guide, and make sure you go into Menu -> Preferences -> Raspberry Pi Configuration and expand your filesystem when you first boot up your Pi.

If you don’t want to reinstall and want to make sure you’re using the latest stable firmware, make sure you have a network connection and type this into Terminal:

sudo apt-get update
sudo apt-get install --reinstall libraspberrypi0 libraspberrypi-{bin,dev,doc} raspberrypi-bootloader
sudo reboot
This should get you back on track with stable Raspbian releases and will undo any rpi-update you might have run.

Tech Specs
There’s no better place to learn everything you might need to know about the screen than the Raspberry Pi blog post which you can find here: https://www.raspberrypi.org/blog/the-eagerly-awaited-raspberry-pi-display/

The skinny is that it’s a:

800x480 pixel display at 60fps, which despite sounding quite small, is actually pretty decent
10 point capacitive touch ( like most modern tablets ) however only one touch is detected in X at the moment
Metal back with 4 mounting holes. Note: they aren’t VESA, and we’ll look into mount kit options soon!
About 155 x 86mm viewable size
Non square pixels - about 0.19 x 0.175mm - you may notice this distorting graphics
Consumes between 455mA and 470mA
Backlight on/off control + brightness control in driver board >= v1.1
Touchscreen
###It keeps not working at boot, or getting stuck while using it

There’s a bug in the touchscreen that’s been fixed in the latest release of Raspbian.

To install it and override any pre-release versions you have installed; do this:

sudo apt-get update
sudo apt-get install --reinstall libraspberrypi0 libraspberrypi-{bin,dev,doc} raspberrypi-bootloader
sudo reboot
###How is it connected?

The touchscreen works over the DSI connector, so no extra connections are needed. It’s connected to the driver board via the smaller ribbon cable- don’t forget it!

###How does it work?

It’s capacitive touch- it senses your finger, but not pointy objects like a resitive screen. It works with stylii (styluses?) like the ones you might use with your iPad

Debugging
If your touch screen doesn’t respond:

make sure you’re running the latest OS, a fresh install usually helps
make sure the smaller ribbon is seated firmly
make sure you have a good power supply and use the GPIO wires or a split cable to power your Pi
SCREEN
###Some windows in X are cut off at the side/bottom of the screen?

This is unfortunately a side-effect of many developers assuming a minimum screen resolution of 1024x768 pixels. You can usually reveal hidden buttons and fields by;

right clicking on the edge or top of the window,
picking “move”
using the up arrow key to nudge the window up off the top of the screen
If you don’t have a mouse, see the right click fix below.

###Can I use HDMI output alongside my LCD?

Yes and no. As explained in the official Pi blog on the subject, only applications which know how to output over HDMI can be used. An example is given for OMXPlayer: https://www.raspberrypi.org/blog/the-eagerly-awaited-raspberry-pi-display/

https://www.raspberrypi.org/blog/the-eagerly-awaited-raspberry-pi-display/:
###Dual display usage

It is possible to use both display outputs at the same time, but it does require software to choose the right display. Omxplayer is one application that has been modified to enable secondary display output.

To start displaying a video onto the LCD display (assuming it is the default display) just type:

# omxplayer video.mkv
To start a second video onto the HDMI then:

# omxplayer --display=5 video.mkv
Please note, you may need to increase the amount of memory allocated to the GPU to 128MB if the videos are 1080P, adjust the gpu_mem value in config.txt for this. The Raspberry Pi headline figures are 1080P30 decode, so if you are using two 1080P clips it may not play correctly depending on the complexity of the videos.

Display numbers are:
LCD: 4
HDMI/TV: 5
Auto-select non-default display: 6
Currently you can’t run a dual display X desktop, and we don’t know when or if this will be possible. If you know how to make it happen, you can chime in on this thread: https://www.raspberrypi.org/forums/viewtopic.php?f=108&t=120541

###Can I turn it off/on from Raspbian?

You can turn on/off the backlight, see below:

###Can I control the backlight?

With the latest software you can turn the backlight on and off with the following commands:

On:

echo 0 > /sys/class/backlight/rpi_backlight/bl_power
Off:

echo 1 > /sys/class/backlight/rpi_backlight/bl_power
###Help, my screen is upside-down!

Note: An update has been pushed to Raspbian to flip the screen ( rotate it by 180 degrees ) for a better desktop viewing angle. This makes it upside-down in our stand and the official Pi stand, so you’ll need to change a setting to flip it back.

To do this, open /boot/config.txt in your favourite editor and add the line:

lcd_rotate=2
This will rotate both the LCD and the touch coordinates back to the right rotation for our display stand.

Don’t use the documented display_rotate, it performs a performance expensive rotation of the screen and does not rotate the touch input.

Getting it working with an older Raspberry Pi Model “A” or “B”
With the software updated it’s actually reasonably straight-forward to get the touchscreen working with a Model A or B Raspberry Pi. First you must make two additional connections between your Pi’s GPIO and the touchscreen: these are the SDA ( http://pinout.xyz/pinout/pin3_gpio2 ) and SCL ( http://pinout.xyz/pinout/pin5_gpio3 ) lines ( which you can connect using the supplied green and yellow wires ).

Finally, you need to enable the LCD which is normally ignored on the main i2c bus:

ignore_lcd=0
Note: This will give your i2c over to the Pi for running the LCD/Touchscreen and you wont be able to use any other i2c devices or add-on boards which require i2c.

The Stand
If you’re using one of our stands you’ll need to rotate the display.

We’ve decided to keep the current design and orientation because it’s the best out of the two and the 10 degree difference in viewing angle is very slight. ( I use these screens every day ).

If you absolutely need an extra 10 degrees of vertical viewing you can fit a Pibow Coupe to the back of the LCD screen and remove the legs. This lets it rest slightly further back while still remaining stable enough for everyday use. It also fits pretty neatly into a bag, too.

Debugging
If you get a white screen, it probably means the screen’s ribbon cable isn’t seated properly. Make sure it’s pushed firmly into place and that the connector is closed properly.

If you get a black screen, it likely means your DSI cable ( the one between the Pi and the driver board ) isn’t seated correctly or is… backwards ( I’m not even sure this is a real thing! ). We’ve had some success reversing the cable in this case- switching which end plugs into which part.

Be extremely careful when re-seating any ribbon cables, the retaining clips can be fragile. If you have a pre-assembled screen then the main ribbon cable is probably fine.

If your screens looks weird and fades out the picture like an old CRT TV when you turn off your Pi- don’t worry, this is perfectly normal!

Power & Power Options
###How much power does it use?

The screen on its own pulls between 450 and 470mA.

Combined with a Pi 2 with an Ethernet connection and running stress -c 100 to load the CPU brings it up to 925mA.

Basically, we recommend using an official Pi 2A power supply, you’ll need it!

###What’s the best way to power the Pi from the screen?

Right now it seems to be the little GPIO cable connected to 5v and GND.

We’re currently looking into better power options, since you can’t use a HAT while it’s in place.

I’ve tried a number of USB cables from the USB port on the LCD driver board to the power input of my Pi and have invariably seen the little rainbow square indicating undervoltage in the top right hand corner of the LCD. (Note: This has seen been updated to a lightning bolt indicating the same)

I have put together a prototype split cable, and we’re looking into sourcing microUSB cable splitters to use in conjunction with the official Pi power supply as the most reliable solution.

Enable Right-click ( Wheezy Only )
Chris_c on the official Pi forums has discovered how to enable right-click with a simple configuration change. This allows you to press and hold on the touchscreen to trigger a right click.

https://www.raspberrypi.org/forums/viewtopic.php?f=108&t=121602

chris_c:
odds on you don’t have an /etc/X11/xorg.conf if not its okay just to create this fragment…

/etc/X11/xorg.conf
Section "InputClass"
   Identifier "calibration"
   Driver "evdev"
   MatchProduct "FT5406 memory based driver"

   Option "EmulateThirdButton" "1"
   Option "EmulateThirdButtonTimeout" "750"
   Option "EmulateThirdButtonMoveThreshold" "30"
EndSection
chris_c:
(re)start X and you should find that a long press behaves like a right click, time to throw your mouse out?
Virtual ( On-Screen ) Keyboard
There seem to be a couple of options for this. So far I’ve seen:

Florence
Suggested on the Pi forums by Hove is Florence: http://xmodulo.com/onscreen-virtual-keyboard-linux.html. Install with:

sudo apt-get install florence
Matchbox
Suggested by Alex ( the almighty @raspitv ), and scattered on various blogs, is Matchbox, which you can install like so:

sudo apt-get install matchbox-keyboard
And then find in Accessories > Keyboard.

Find some screenshots ( of it on a smaller LCD ) here: http://ozzmaker.com/2014/06/30/virtual-keyboard-for-the-raspberry-pi/

Reverse Mount
As Clive demonstrates below, you can make a much more compact setup by flipping your Pi and mounting it with the ports facing towards the back of the LCD.

This does not currently work with our Display Frame, there’s not enough clearance for the USB ports.

A standard GPIO ribbon cable will not fit between the two metal risers, so it’s impossible to route a Black HAT Hack3r or Cobbler out from the display in this position, but there might be cables out there that fit.

If you’re going for a permanent setup, then you can just solder the power cables to the underside of the GPIO.



Image pinched from Clive Beale: https://www.raspberrypi.org/blog/dont-try-this-at-home-how-not-to-hack-the-raspberry-pi-display/

Other Stuff
I want to run my touchscreen at 90 degrees
( And have the touchscreen actually work! )

Gasp! Okay, I can see why you’d want to do this! I couldn’t put it better than the great step-by-step forum post here: https://www.raspberrypi.org/forums/viewtopic.php?f=108&t=120793

I want to make my own case/Mount it in something
You can find a technical drawing with dimensions of the display and mount hole locations here: https://github.com/raspberrypi/documentation/tree/master/hardware/display

Make sure you mount your screen by screwing, gently, into the mounting holes either side of the metal frame, or for the driver board. Don’t attempt to mount the screen by the glass front. The tape bonding the glass to the rest of the screen isn’t designed to carry the weight of the screen, your Pi and whatever else might be connected.

The touchscreen doesn’t work with Kivy!
Use this guide: https://github.com/mrichardson23/rpi-kivy-screen

OS Support
Raspbian - Supported
Ubuntu MATE Supported
RetroPie - Supported
OpenElec - Supported
OSMC - Supported
Arch - Display works, Touch may be tricky: https://www.raspberrypi.org/forums/viewtopic.php?f=108&t=128452
Kano OS - Not supported ( they cite minimum resolution at 1024x768 )
Pi Support
Model A+, B+, Pi 2 and Pi 3 are supported
Old Model B and A currently don’t work, but will be supported eventually with a software update
The Compute Module IO board (for CM and CM3) includes a connector for the screen, see: https://www.raspberrypi.org/documentation/hardware/computemodule/cmio-display.md
