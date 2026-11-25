@echo off
rem Sony-friendly alias for find-projector.bat. It scans the LAN for ADB on port 5555
rem and writes found-projector.txt, which setup-config.bat reads.
call "%~dp0find-projector.bat"
