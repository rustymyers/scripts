#tag Window
Begin Window Window1
   BackColor       =   &cFFFFFF00
   Backdrop        =   0
   CloseButton     =   True
   Compatibility   =   ""
   Composite       =   False
   Frame           =   0
   FullScreen      =   False
   FullScreenButton=   False
   HasBackColor    =   False
   Height          =   400
   ImplicitInstance=   True
   LiveResize      =   True
   MacProcID       =   0
   MaxHeight       =   32000
   MaximizeButton  =   True
   MaxWidth        =   32000
   MenuBar         =   35270120
   MenuBarVisible  =   True
   MinHeight       =   64
   MinimizeButton  =   True
   MinWidth        =   64
   Placement       =   1
   Resizeable      =   True
   Title           =   "Check Sleep Times"
   Visible         =   True
   Width           =   600
   Begin PushButton PushButton1
      AutoDeactivate  =   True
      Bold            =   False
      ButtonStyle     =   "0"
      Cancel          =   False
      Caption         =   "Check"
      Default         =   True
      Enabled         =   True
      Height          =   20
      HelpTag         =   ""
      Index           =   -2147483648
      InitialParent   =   ""
      Italic          =   False
      Left            =   260
      LockBottom      =   False
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   False
      LockTop         =   True
      Scope           =   0
      TabIndex        =   0
      TabPanelIndex   =   0
      TabStop         =   True
      TextFont        =   "System"
      TextSize        =   0.0
      TextUnit        =   0
      Top             =   127
      Underline       =   False
      Visible         =   True
      Width           =   80
   End
   Begin Label StatusLabel
      AutoDeactivate  =   True
      Bold            =   False
      DataField       =   ""
      DataSource      =   ""
      Enabled         =   True
      Height          =   20
      HelpTag         =   ""
      Index           =   -2147483648
      InitialParent   =   ""
      Italic          =   False
      Left            =   20
      LockBottom      =   False
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   False
      LockTop         =   True
      Multiline       =   False
      Scope           =   0
      Selectable      =   False
      TabIndex        =   1
      TabPanelIndex   =   0
      Text            =   "-"
      TextAlign       =   1
      TextColor       =   &c00000000
      TextFont        =   "System"
      TextSize        =   0.0
      TextUnit        =   0
      Top             =   190
      Transparent     =   False
      Underline       =   False
      Visible         =   True
      Width           =   560
   End
End
#tag EndWindow

#tag WindowCode
	#tag Event
		Sub Open()
		  
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h21
		Private Function NumSecondsFromMidnightGet(paramHour as integer, paramMinute as integer) As Double
		  dim mNumSecondsAtLastMidnight as new date
		  
		  // Reset the hour, minute and seconds to 12:00:00:
		  
		  mNumSecondsAtLastMidnight.Hour = 0
		  mNumSecondsAtLastMidnight.Minute = 0
		  mNumSecondsAtLastMidnight.Second = 0
		  
		  // Get the number of seconds at mid-night of the previous night:
		  
		  dim mHourMinuteToCalcDate as new date( mNumSecondsAtLastMidnight.Year, mNumSecondsAtLastMidnight.Month, mNumSecondsAtLastMidnight.Day, paramHour, paramMinute )
		  
		  return mHourMinuteToCalcDate.TotalSeconds - mNumSecondsAtLastMidnight.TotalSeconds
		End Function
	#tag EndMethod


	#tag Property, Flags = &h21
		Private pSleepTimesEnd(-1) As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private pSleepTimesStart(-1) As Double
	#tag EndProperty


#tag EndWindowCode

#tag Events PushButton1
	#tag Event
		Sub Action()
		  // <array>
		  // <string>06:30-07:30</string>
		  // <string>09:30-10:30</string>
		  // <string>15:30-16:30</string>
		  // <string>19:30-20:30</string>
		  // <string>00:00-00:30</string>
		  // </array>
		  
		  // Add the time frames:
		  
		  pSleepTimesStart.Append( NumSecondsFromMidnightGet( 6, 30) )
		  pSleepTimesEnd.Append( NumSecondsFromMidnightGet( 7, 30) )
		  
		  pSleepTimesStart.Append( NumSecondsFromMidnightGet( 9, 30) )
		  pSleepTimesEnd.Append( NumSecondsFromMidnightGet( 10, 30) )
		  
		  // Now check if the current hour and minute are within any of the ranges:
		  
		  dim mCurrentDateTimeNow as new date
		  dim mCurrentNumSecondsFromMidnight as double = NumSecondsFromMidnightGet( mCurrentDateTimeNow.Hour, mCurrentDateTimeNow.Minute)
		  
		  dim mLoopVar as integer
		  dim mNumTimes as integer = pSleepTimesStart.Ubound
		  
		  dim mFoundSleepTimeMatch as Boolean = false
		  
		  for mLoopVar = 0 to mNumTimes
		    
		    if ( mCurrentNumSecondsFromMidnight >= pSleepTimesStart(mLoopVar) ) and ( mCurrentNumSecondsFromMidnight <= pSleepTimesEnd(mLoopVar) ) then
		      
		      mFoundSleepTimeMatch = true
		      
		      exit // No need to keep checking ranges, we are in one right now
		      
		    end if
		    
		  next
		  
		  if ( mFoundSleepTimeMatch ) then
		    
		    StatusLabel.Text = "Time to sleep!"
		    
		  else
		    
		    StatusLabel.Text = "It's not time to sleep."
		    
		  end if
		  
		End Sub
	#tag EndEvent
#tag EndEvents
