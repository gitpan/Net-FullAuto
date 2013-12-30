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
WinWaitActive, Import Wizard,,2
Loop {
   IfWinExist, Software Installation
   {
      Winactivate
      Sleep, 3000
      Send, {Enter}
   } else IfWinActive, Mozilla Firefox
   {
      Break
   } else IfWinActive, Import Wizard
   {
      Send !d
      Sleep,10
      Send !n
   } else IfWinActive, Add-ons
   {
      ControlSend, MozillaWindowClass2, {Tab}!R, Add-ons
      Break
   }

}
WinWaitActive, Add-ons,,2
Loop {
   ifWinExist, Add-ons
   {
       WinClose, Add-ons
       WinWaitActive, Mozilla Firefox,,2
       Break
   }
}
WinWaitActive, Mozilla Firefox
WinClose, Mozilla Firefox
Sleep, 1000
IfWinExist, Mozilla Firefox and IfWinNotActive, Mozilla Firefox
{
   Send, {Enter}
}
ExitApp
