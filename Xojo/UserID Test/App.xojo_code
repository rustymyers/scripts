#tag Class
Protected Class App
Inherits ConsoleApplication
	#tag Event
		Function Run(args() as String) As Integer
		  dim UserID as integer
		  dim ErrMsg as string
		  if App.GetEffectiveUserID(UserID, ErrMsg) then
		    print("UserID: "+str(UserID))
		  end
		End Function
	#tag EndEvent


	#tag Method, Flags = &h0
		Function GetEffectiveUserID(byRef paramUserIDInt as integer, ByRef paramErrMsg as string) As Boolean
		  declare function getuid lib "System" () as integer
		  
		  dim mUID as integer
		  
		  try
		    
		    mUID = getuid()
		    
		  catch
		    
		    paramErrMsg = "ERROR: Failed to get effective USER ID."
		    
		    return false
		    
		  end try
		  
		  paramUserIDInt = mUID
		  
		  paramErrMsg = ""
		  return true
		End Function
	#tag EndMethod


	#tag ViewBehavior
	#tag EndViewBehavior
End Class
#tag EndClass
