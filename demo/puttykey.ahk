;### OPEN SOURCE LICENSE - GNU AFFERO PUBLIC LICENSE Version 3.0 #######
;#
;#    Net::FullAuto - Powerful Network Process Automation Software
;#    Copyright (C) 2000-2015  Brian M. Kelly
;#
;#    This program is free software: you can redistribute it and/or modify
;#    it under the terms of the GNU Affero General Public License as
;#    published by the Free Software Foundation, either version 3 of the
;#    License, or any later version.
;#
;#    This program is distributed in the hope that it will be useful,
;#    but **WITHOUT ANY WARRANTY**; without even the implied warranty of
;#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;#    GNU Affero General Public License for more details.
;#
;#    You should have received a copy of the GNU Affero General Public
;#    License along with this program.  If not, see:
;#    <http://www.gnu.org/licenses/agpl.html>.
;#
;#######################################################################

#NoTrayIcon
#NoEnv
SetWorkingDir, %A_ScriptDir%
DetectHiddenWindows, On
Run puttygen.exe %1%
WinWait, PuTTYgen Notice, , 3
if ErrorLevel {
   return
} else {
   Send, {ENTER}
}
WinWait, PuTTY Key Generator, , 3
if ErrorLevel {
   return
} else {
   Send, !s
}
WinWait, PuTTYgen Warning, , 3
if ErrorLevel {
   return
} else {
   Send, {ENTER}
}
WinWait, Save private key as:, , 3
if ErrorLevel {
   return
} else {
   sleep 1000
   Send, fullauto{ENTER}
}
WinWait, PuTTYgen Warning, , 1
if ErrorLevel {
} else {
   Send, {ENTER}
}
WinActivate, PuTTY Key Generator
Send, !fx
