screenCapture - captures the screen or the active window and saves it to a file
===

```
Usage:
screenCapture  filename.format [WindowTitle]
```

* filename - the file where the screen capture will be saved
* format - Bmp,Emf,Exif,Gif,Icon,Jpeg,Png,Tiff and are supported - default is bmp
* WindowTitle - instead of capturing the whole screen will capture the only a window with the given title if there's such


Examples:
====

```
call screenCapture notepad.jpg "Notepad"
call screenCapture screen.png
screenCapture.bat screen_rdp.png "zasfe.com: 원격 데스크톱 연결"
```

Original
====
* https://github.com/npocmaka/batch.scripts/blob/master/hybrids/.net/c/screenCapture.bat
* https://superuser.com/questions/75614/take-a-screen-shot-from-command-line-in-windows
