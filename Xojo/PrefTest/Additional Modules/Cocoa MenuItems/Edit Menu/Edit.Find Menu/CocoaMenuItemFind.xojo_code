#tag Class
Protected Class CocoaMenuItemFind
Inherits CocoaMenuItemFindAbstract
	#tag Event
		Function CocoaTag() As Integer
		  const NSFindPanelActionShowFindPanel = 1
		  
		  return NSFindPanelActionShowFindPanel
		End Function
	#tag EndEvent


	#tag Constant, Name = LocalizedText, Type = String, Dynamic = True, Default = \"Find\xE2\x80\xA6", Scope = Public
		#Tag Instance, Platform = Any, Language = en, Definition  = \"Find\xE2\x80\xA6"
		#Tag Instance, Platform = Any, Language = de, Definition  = \"Suchen \xE2\x80\xA6"
		#Tag Instance, Platform = Any, Language = ja, Definition  = \"\xE6\xA4\x9C\xE7\xB4\xA2 ..."
		#Tag Instance, Platform = Any, Language = fr, Definition  = \"Rechercher\xE2\x80\xA6"
		#Tag Instance, Platform = Any, Language = it, Definition  = \"Cerca\xE2\x80\xA6"
		#Tag Instance, Platform = Any, Language = bn, Definition  = \"\xE0\xA6\x85\xE0\xA6\xA8\xE0\xA7\x81\xE0\xA6\xB8\xE0\xA6\xA8\xE0\xA7\x8D\xE0\xA6\xA7\xE0\xA6\xBE\xE0\xA6\xA8\xE2\x80\xA6"
		#Tag Instance, Platform = Any, Language = nl, Definition  = \"Zoek..."
	#tag EndConstant


	#tag ViewBehavior
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
