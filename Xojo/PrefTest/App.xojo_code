#tag Class
Protected Class App
Inherits Application
	#tag Event
		Sub Open()
		  MsgBox("PrefTest App. Hello")
		  // App Default Values
		  dim AppVersion as string = "1.0"
		  
		  // Set Default Values
		  //prefs.Value ("managepower") = true
		  //prefs.Value ("version") = AppVersion
		  
		  // Get App Values
		  dim ManagePowerPref as Boolean = prefs.Value("managepower", 1)
		  dim AppVersionPref as String = prefs.Value("version", AppVersion)
		  
		  
		  if (ManagePowerPref) then
		    MsgBox("Managepower Prefrence Key is True")
		  end
		End Sub
	#tag EndEvent


	#tag Constant, Name = kEditClear, Type = String, Dynamic = False, Default = \"&Delete", Scope = Public
		#Tag Instance, Platform = Windows, Language = Default, Definition  = \"&Delete"
		#Tag Instance, Platform = Linux, Language = Default, Definition  = \"&Delete"
	#tag EndConstant

	#tag Constant, Name = kFileQuit, Type = String, Dynamic = False, Default = \"&Quit", Scope = Public
		#Tag Instance, Platform = Windows, Language = Default, Definition  = \"E&xit"
	#tag EndConstant

	#tag Constant, Name = kFileQuitShortcut, Type = String, Dynamic = False, Default = \"", Scope = Public
		#Tag Instance, Platform = Mac OS, Language = Default, Definition  = \"Cmd+Q"
		#Tag Instance, Platform = Linux, Language = Default, Definition  = \"Ctrl+Q"
	#tag EndConstant


	#tag ViewBehavior
	#tag EndViewBehavior
End Class
#tag EndClass
