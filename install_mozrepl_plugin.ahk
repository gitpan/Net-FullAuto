;### OPEN SOURCE LICENSE - GNU PUBLIC LICENSE Version 3.0 #######
;#
;#    Net::FullAuto - Powerful Network Process Automation Software
;#    Copyright (C) 2000-2013  Brian M. Kelly
;#
;#    This program is free software: you can redistribute it and/or modify
;#    it under the terms of the GNU General Public License as published by
;#    the Free Software Foundation, either version 3 of the License, or
;#    any later version.
;#
;#    This program is distributed in the hope that it will be useful,
;#    but **WITHOUT ANY WARRANTY**; without even the implied warranty of
;#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;#    GNU General Public License for more details.
;#
;#    You should have received a copy of the GNU General Public License
;#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
;#
;################################################################

#NoTrayIcon
#NoEnv
SetWorkingDir, %A_ScriptDir%
DetectHiddenWindows, On
Run %1% %2%
;Run c:\Program Files\Mozilla Firefox\firefox c:\cygwin\fullauto\FullAuto\mozrepl-1.1-fx.xpi
sleep, 2000
IfWinExist, Import Wizard
{
   WinActivate
   Send !d
   Sleep,10
   Send !n
}
WinWaitActive, Mozilla Firefox ahk_class MozillaWindowClass
WinWaitActive, Software Installation
Sleep, 4000
Send, {Enter}
WinWaitActive, Mozilla Firefox ahk_class MozillaWindowClass
Send, {Enter up}{Tab}
Sleep, 1000
Send, {	}{Tab up}{Tab}
Sleep, 2000
Send, {	}{Tab up}{Enter}
Sleep, 2000
Send, { }
Send, {Enter up}
WinWaitActive, Mozilla Firefox ahk_class MozillaWindowClass
WinClose, Mozilla Firefox ahk_class MozillaWindowClass
ExitApp
