@ECHO off
::************************************************************************
::Schedule Delete in 30Days.bat
::
::Created By:
::Profound Disputes
::
::Last Updated: 05/01/2018
::Tested On: Windows 10,
::
::Purpose:
::	Dragging a folder or file on this file will cause the following:
::		1) The name of the file/folder will be used to create a task
::			in windows listed under DelFolderX, X being a incremented
::			number based on the number of existing DelFolder entries.
::			The task will be scheduled to run this same .bat file with
::			the directory path from dragged file/folder as %1 and the
::			name of the task as %2. The task is scheduled to run in a
::			month from current date.
::		2)	When the scheduled tasks runs this file executed. When
::			ran from the scheduled task, with the task name as the %2,
::			the file/folder will be deleted. Than the task will be
::			deleted.
::
::************************************************************************


::Batch is used to schedule tasks and delete scheduled task after executing
::Depending on how the batch file is called determines the correct section
::%2 will contain a task name for deletion. Otherwise %2 is NULL
if [%2]==[] ( GOTO DeleteinOneMonth ) ELSE ( GOTO AutoDelete )

::AutoDelete will delete the file directory contained in %1 then
::delete the schedule task contained in %2. Will prompt before
::deleting a file or directory in case of mistake.
:AutoDelete
ECHO The following will be done:
ECHO 1) Delete Folder/File %1
ECHO 2) Deleting Task %2
ECHO.

::Setting directory to variable for If comparison
set value=%1

::If the directory includes a '.' char than assumed to be a file
if %value%==%value:.=% (
	ECHO =======================================
	ECHO Deleting Folder:
	ECHO %1
	ECHO =======================================
	ECHO.
	rmdir /s %1
	) else (
	ECHO =======================================
	ECHO Deleting File:
	ECHO %1
	ECHO =======================================
	ECHO.
	del /P %1
	)
	
ECHO Done.

ECHO.
ECHO =======================================
ECHO Deleting Scheduled Task:
ECHO %2
ECHO =======================================
ECHO.
schtasks /delete /tn %2 /f

ECHO.
pause
exit

:DeleteinOneMonth
::===============
:: set the month
::===============
set month=%date:~4,-8%
set /a month=%month% + 1

::Formats month to include a preceding zero. Otherwise scheduled task command fails
IF %month% LSS 10 (set month=0%month%)

::store days in month with month number plus days in that month
set daysInMonth=0131 0228 0331 0430 0531 0630 0731 0831 0930 1031 1130 1231

::Loop will cycle through daysInMonth and find the matching month
::After match is found it will store the amount of days in the matched
::month
setlocal ENABLEDELAYEDEXPANSION
FOR %%G in (!daysInMonth!) DO (
	set tempData=%%G
	IF NOT !tempData!==!tempData:%month%=! (
	set totalInMonth=!tempData:%month%=!
	)
)
setlocal DISABLEDELAYEDEXPANSION

::If month is already at 12 roll back to January. The year will be incremented later
IF %month%==13 (set month=01)

::===============
:: set the day
::===============
::Removes the last 4 digits for the year and the first 6 digits for weekday and month
::Effectively give "/XX/" as the value
set day=%date:~6,-4%

::Makes sure that the day is not beyond the amount of days in month
IF %day:/=% GTR %totalInMonth% set day=/%totalInMonth%/

::===============
::    set year
::===============
::Grab the last 4 digits containing the year
set year=%date:~-4%

::If month was rolled back to 01 than make sure to increment the year
IF %date:~4,-8%==12 (set /a year=%year% + 1)

::===============
:: set new date
::===============
set NewDate=%month%%day%%year%

::Copy %1 into new variable so string EDIT/REPLACE can be run
set deletethis=%1

::Need to remove space from variable but retain spaces for later
::This creates a new variable and stores the space-less value for
::if comparison. Keeps deletethis value for command later on.
set spacelessDir=%deletethis: =%

::Now need to get the file/folder name, that will be deleted, to
::give the schedule task a unique name. Example we are retrieving
::the following contained in [] "C:\windows\system\[folder]". What
::ever is after the last backslash
::First need to remove all the original spaces and (). This is done
::because these characters will break if statements
set rmBackSlashes=%deletethis: =@%
set rmBackSlashes=%rmBackSlashes:(=%
set rmBackSlashes=%rmBackSlashes:)=%

::Secondly need to remove any " found in the directory. Very important
::when the FOR loop is run it needs to be delimited by the \ location
IF NOT %spacelessDir%==%spacelessDir:"=% (set rmBackSlashes=%rmBackSlashes:~1,-1%)

::To get the FOR loop to segment each folder in the path we need to replace
::the \ chars with a space.
set rmBackSlashes=%rmBackSlashes:\= %

::Count each folder in the directory path. This is to know when to grab
::the last folder/file. Visual Example "C:\1folder\2folder\3file.txt"
FOR %%G in (%rmBackSlashes%) DO (set /a count+=1)

::Set the last folder/file section number
set /a HitTarget=%count%

::Reset count to find and extract the folder/file
set count=0

setlocal ENABLEDELAYEDEXPANSION
FOR %%G in (!rmBackSlashes!) DO (
	set /a count+=1
	IF !count!==!HitTarget! (
	set extracted=%%G
	)
)
setLocal DISABLEDELAYEDEXPANSION

::Replace the space place holder @ from extracted folder/file name with _
set taskName=%extracted:@=_%

::Format and set the final name the task will be given
set taskName="Delete_%taskName%_in_1_month"

::Checks to ensure that deletethis doesn't contain double quotes
::Directories passed in that contain spaces are passed in with 
::double quotes. When double quotes are included in schtasks 
::command it will cause the task to fail to start.
if %spacelessDir%==%spacelessDir:"=% (
	CALL :schtasksTrue
) else (
	CALL :schtasksFalse
)

ECHO.
ECHO Will Delete The following in one Month (%NewDate%):
ECHO %deletethis%
ECHO.

pause
exit

:schtasksTrue
schtasks /create /sc once /sd 05/02/2018 /TR ""%CD%\Schedule_Delete_30Days.bat" '%deletethis%' '%taskName%'" /st 12:42 /tn %taskName%
EXIT /b

:schtasksFalse
schtasks /create /sc once /sd 05/02/2018 /TR ""%CD%\Schedule_Delete_30Days.bat" '%deletethis:~1,-1%' '%taskName%'" /st 12:42 /tn %taskName%
EXIT /b