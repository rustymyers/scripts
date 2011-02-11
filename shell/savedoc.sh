#!/bin/bash

##Set Office to save documents as .doc or .docx

#Only using .doc, we don't want to ask about .docx yet

#.docx
#defaults write com.microsoft.Word "2008\Default Save\Default Format" 'WordDocument'
#.xlsx
#defaults write com.microsoft.Excel  "2008\Default Save\Default Format" '52'
#.pptx
#defaults write com.microsoft.PowerPoint "2008\Default Save\Default Save\Default Format" 'Microsoft PowerPoint 2007 XML Presentation'

#.doc
defaults write com.microsoft.Word "2008\Default Save\Default Format" 'Doc97'

#.xls
defaults write com.microsoft.Excel  "2008\Default Save\Default Format" '57'

#.ppt
defaults write com.microsoft.PowerPoint "2008\Default Save\Default Save\Default Format" 'Microsoft PowerPoint 98 Presentation'

#Tell user to restart
osascript -e 'tell app "System Events" to display dialog "Your Office 2008 will now save in .doc." buttons "OK" default button 1 with title "Office Save"'