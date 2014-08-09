#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
SYSBUILDER_FOLDER=`dirname "${0}"`
VERSION=1.40

########################################################
# Functions
########################################################

print_usage() {
  echo "Usage: ${SCRIPT_NAME} -type=local -volume=<volume name> [-erasedisk][-loc=<language>][-serverurl=<server url>][-serverurl2=<server url 2>][-login=<login>][-password=<password>][-ardlogin=<login>][-ardpassword=<password>][-displaylogs][-timeout=<duration in seconds>][-displaysleep=<duration in minutes>][-enableruby][-enablepython][-enablecustomtcpstacksettings][-disablewirelesssupport][-disableadviewer][-ntp=<network time server>][-customtitle=<Runtime mainwindow title>][-custombackground=<Runtime custom background image path>]"
  echo "       ${SCRIPT_NAME} -type=netboot -id=<ID> -name=<name> -dest=<destination> [-loc=<language>][-serverurl=<server url>][-serverurl2=<server url 2>][-login=<login>][-password=<password>][-ardlogin=<login>][-ardpassword=<password>][-displaylogs][-timeout=<duration in seconds>][-displaysleep=<duration in minutes>][-enableruby][-enablepython][-enablecustomtcpstacksettings][-disablewirelesssupport][-ntp=<network time server>][-customtitle=<Runtime mainwindow title>][-custombackground=<Runtime custom background image path>]"
}

ditto_file_at_path() {
  ditto --rsrc "${2}/${1}" "${TMP_MOUNT_PATH}${2}/${1}" 2>&1
}

enable_custom_tcp_stack_settings() {
  echo "# kernel options that should improve tcp performance" > "${TMP_MOUNT_PATH}"/etc/sysctl.conf
  echo "kern.ipc.maxsockbuf=1048576"        >> "${TMP_MOUNT_PATH}"/etc/sysctl.conf
  echo "kern.ipc.somaxconn=512"             >> "${TMP_MOUNT_PATH}"/etc/sysctl.conf
  echo "net.local.stream.recvspace=98304"	>> "${TMP_MOUNT_PATH}"/etc/sysctl.conf
  echo "net.local.stream.sendspace=98304"	>> "${TMP_MOUNT_PATH}"/etc/sysctl.conf
  echo "net.inet.udp.maxdgram=57344"        >> "${TMP_MOUNT_PATH}"/etc/sysctl.conf
  echo "net.inet.udp.recvspace=42080"       >> "${TMP_MOUNT_PATH}"/etc/sysctl.conf
  echo "net.inet.tcp.delayed_ack=0"         >> "${TMP_MOUNT_PATH}"/etc/sysctl.conf
  echo "net.inet.tcp.mssdflt=1460"          >> "${TMP_MOUNT_PATH}"/etc/sysctl.conf
  echo "net.inet.tcp.newreno=1"             >> "${TMP_MOUNT_PATH}"/etc/sysctl.conf
  echo "net.inet.tcp.recvspace=98304"       >> "${TMP_MOUNT_PATH}"/etc/sysctl.conf
  echo "net.inet.tcp.rfc1323=1"             >> "${TMP_MOUNT_PATH}"/etc/sysctl.conf
  echo "net.inet.tcp.rfc1644=1"             >> "${TMP_MOUNT_PATH}"/etc/sysctl.conf
  echo "net.inet.tcp.sendspace=98304"       >> "${TMP_MOUNT_PATH}"/etc/sysctl.conf
  chmod 644 "${TMP_MOUNT_PATH}"/etc/sysctl.conf 2>&1
  chown -R root:wheel "${TMP_MOUNT_PATH}"/etc/sysctl.conf 2>&1
}

fill_volume_1080() {
  # disable spotlight indexing
  mdutil -i off "${TMP_MOUNT_PATH}"
  mdutil -E "${TMP_MOUNT_PATH}"
  defaults write "${TMP_MOUNT_PATH}"/.Spotlight-V100/_IndexPolicy Policy -int 3

  # build BaseSystem bom
  lsbom -s /var/db/receipts/com.apple.pkg.BaseSystemBinaries.bom   > /tmp/dss_bs.txt
  lsbom -s /var/db/receipts/com.apple.pkg.BaseSystemResources.bom >> /tmp/dss_bs.txt
  sort -u /tmp/dss_bs.txt > /tmp/dss_bs_sorted.txt
  mkbom -s -i /tmp/dss_bs_sorted.txt /tmp/dss_bs.bom
  
  # start adding content to the volume
  ditto -bom /tmp/dss_bs.bom / "${TMP_MOUNT_PATH}" 2>&1
  
  # temp files cleanup
  rm /tmp/dss_bs.txt /tmp/dss_bs_sorted.txt /tmp/dss_bs.bom

  # add extra content
  # ETC_CONF="pam.d smb.conf smb.conf.template"
  # for A_ETC_CONF in ${ETC_CONF}
  # do
  #   ditto_file_at_path "${A_ETC_CONF}" /etc
  # done
  # ditto /var/db/smb.conf "${TMP_MOUNT_PATH}/var/db/smb.conf" 2>&1
  # 
  USR_LIB_SYS="libsystem_notify.dylib"
  for A_LIB_SYS in ${USR_LIB_SYS}
  do
    ditto_file_at_path "${A_LIB_SYS}" /usr/lib/system
  done

  cp -p -R /usr/lib/libsvn_* "${TMP_MOUNT_PATH}"/usr/lib/ 2>&1
  cp -p -R /usr/lib/libxar* "${TMP_MOUNT_PATH}"/usr/lib/ 2>&1

  USR_BIN="afconvert afinfo afplay atos auval auvaltool basename cd chgrp curl diff dirname dscl du egrep \
           erb expect false fgrep fs_usage grep gunzip gzip irb lsbom mkbom open printf rails rake rdoc ri rsync \
           ruby say smbutil srm sw_vers syslog testrb xattr xattr-2.5 xattr-2.6 xattr-2.7 xxd"
  for A_BIN in ${USR_BIN}
  do
    ditto_file_at_path "${A_BIN}" /usr/bin
  done

  USR_SBIN="gssd hwmond iostat ntpdate smbd systemkeychain vsdbutil"
  for A_SBIN in ${USR_SBIN}
  do
    ditto_file_at_path "${A_SBIN}" /usr/sbin
  done
  
  # USR_SHARE="sandbox terminfo zoneinfo"
  # for A_SHARE in ${USR_SHARE}
  # do
  #   ditto_file_at_path "${A_SHARE}" /usr/share
  # done
  # 
  USR_LIBEXEC="launchdadd samba security-checksystem"
  for A_LIBEXEC in ${USR_LIBEXEC}
  do
    ditto_file_at_path "${A_LIBEXEC}" /usr/libexec
  done
  
  ditto --rsrc "${SYSBUILDER_FOLDER}"/common/StartupDisk.app "${TMP_MOUNT_PATH}"/Applications/Utilities/StartupDisk.app
  if [ -z ${DISABLE_AD_VIEWER} ]
  then
    ditto --rsrc "${SYSBUILDER_FOLDER}"/common/AdViewer.app "${TMP_MOUNT_PATH}"/Applications/AdViewer.app
  fi
  # 
  # LIB_MISC="ColorSync Perl"
  # for A_LIB in ${LIB_MISC}
  # do
  #   ditto_file_at_path "${A_LIB}" /Library
  # done
  # 
  ditto_file_at_path smb.bundle /Library/Filesystems/NetFSPlugins
  # 
  # SYS_LIB="Displays KerberosPlugins LoginPlugins Perl Sandbox"
  SYS_LIB="DirectoryServices OpenDirectory"
  for A_SYS_LIB in ${SYS_LIB}
  do
    ditto_file_at_path "${A_SYS_LIB}" /System/Library
  done

  # SYS_LIB_CORE="CoreTypes.bundle KernelEventAgent.bundle RemoteManagement SecurityAgentPlugins"
  SYS_LIB_CORE="ZoomWindow.app RemoteManagement"
  for A_SYS_LIB_CORE in ${SYS_LIB_CORE}
  do
    ditto_file_at_path "${A_SYS_LIB_CORE}" /System/Library/CoreServices
  done

  ditto_file_at_path Sounds /System/Library

  SYS_LIB_EXT="IOPlatformPluginFamily AppleIntelHD3000Graphics"
  for A_SYS_LIB_EXT in ${SYS_LIB_EXT}
  do
    ditto_file_at_path "${A_SYS_LIB_EXT}.kext" /System/Library/Extensions
  done
  # 
  # SYS_LIB_EXT_BDL="ATIRadeonX2000GLDriver ATIRadeonX2000VADriver ATIRadeonX3000GLDriver ATIRadeonX3000VADriver \
  #                  AppleIntelHD3000GraphicsGLDriver AppleIntelHD3000GraphicsVADriver AppleIntelHDGraphicsGLDriver \
  #                  GeForceGLDriver"
  # for A_SYS_LIB_EXT_BDL in ${SYS_LIB_EXT_BDL}
  # do
  #   ditto_file_at_path "${A_SYS_LIB_EXT_BDL}.bundle" /System/Library/Extensions
  # done
  # 
  # SYS_LIB_EXT_PLUG="ATIRadeonX2000GA ATIRadeonX3000GA AppleIntelHD3000GraphicsGA"
  # for A_SYS_LIB_EXT_PLUG in ${SYS_LIB_EXT_PLUG}
  # do
  #   ditto_file_at_path "${A_SYS_LIB_EXT_PLUG}.plugin" /System/Library/Extensions
  # done
  # 
  SYS_LIB_FRK="AppleScriptObjC AVFoundation AddressBook Automator CalendarStore Carbon CoreMIDI FWAUserLib IMServicePlugIn \
               IOBluetooth InstantMessage Message nt OpenAL OpenGL OSAKit QuickTime Ruby RubyCocoa ScriptingBridge \
               ServerNotification Tcl"
  for A_SYS_LIB_FRK in ${SYS_LIB_FRK}
  do
    ditto_file_at_path "${A_SYS_LIB_FRK}.framework" /System/Library/Frameworks
  done
	# 
	#   SYS_LIB_PREF_PANES="StartupDisk"
	#   for A_SYS_LIB_PREF_PANE in ${SYS_LIB_PREF_PANES}
	#   do
	#     ditto_file_at_path "${A_SYS_LIB_PREF_PANE}.prefPane" /System/Library/PreferencePanes
	#   done
	# 
  SYS_LIB_PRIV_FRK="AOSMigrate ByteRangeLocking CalDAV CaptiveNetwork ClockMenuExtraPreferences ConfigProfileHelper ConfigurationProfiles \
                    CoreDaemon CoreDAV DCERPC DataDetectors DotMacLegacy DotMacSyncManager ExchangeWebServices FTServices FWAVC \
                    FaceCoreLight GoogleContactSync HeimODAdmin IMCore InternetAccounts JavaLaunching MacRuby Marco MDSChannel \
                    PasswordServer PhoneNumbers PrintingPrivate SMBClient ServerFoundation ServerKit SoftwareUpdate SpotlightIndex \
                    SyncServicesUI SystemUIPlugin UniversalAccess WhitePages XMPPCore YahooSync iCalendar login vmutils nt \
                    AppleGVA CalendarDraw IMAP MMCSServices MediaControlSender MessageProtection MMCS"
  for A_SYS_LIB_PRIV_FRK in ${SYS_LIB_PRIV_FRK}
  do
    ditto_file_at_path "${A_SYS_LIB_PRIV_FRK}.framework" /System/Library/PrivateFrameworks
  done

  if [ -e "${TMP_MOUNT_PATH}"/System/Library/Fonts ] 
  then
    rm -rf "${TMP_MOUNT_PATH}"/System/Library/Fonts
  fi
  ditto --rsrc /System/Library/Fonts "${TMP_MOUNT_PATH}/System/Library/Fonts" 

  if [ -e "${TMP_MOUNT_PATH}"/System/Library/SystemProfiler ] 
  then
    rm -rf "${TMP_MOUNT_PATH}"/System/Library/SystemProfiler
  fi
  ditto --rsrc /System/Library/SystemProfiler "${TMP_MOUNT_PATH}/System/Library/SystemProfiler" 

  if [ -e "${TMP_MOUNT_PATH}"/System/Library/Tcl ] 
  then
    rm -rf "${TMP_MOUNT_PATH}"/System/Library/Tcl
  fi
  ditto --rsrc /System/Library/Tcl "${TMP_MOUNT_PATH}/System/Library/Tcl" 
  
  ditto_file_at_path Perl   /Library
  ditto_file_at_path Perl   /System/Library

  if [ -n "${ENABLE_PYTHON}" ]
  then
    ditto_file_at_path Python /Library
	cp -p -R /usr/lib/python* "${TMP_MOUNT_PATH}"/usr/lib/ 2>&1
	ditto_file_at_path python /usr/bin
  fi
	
  if [ -n "${ENABLE_RUBY}" ]
  then
    ditto_file_at_path Ruby /Library
    ditto_file_at_path ruby /usr/lib
  fi

  # Display mirroring support
  ditto --rsrc  "${SYSBUILDER_FOLDER}"/common/enableDisplayMirroring "${TMP_MOUNT_PATH}"/usr/bin/enableDisplayMirroring 2>&1
  chmod 755 "${TMP_MOUNT_PATH}"/usr/bin/enableDisplayMirroring 2>&1
  chown root:wheel "${TMP_MOUNT_PATH}"/usr/bin/enableDisplayMirroring 2>&1

  rm "${TMP_MOUNT_PATH}"/mach
  ln -s /mach_kernel "${TMP_MOUNT_PATH}"/mach

  cp "${SYSBUILDER_FOLDER}/common/com.deploystudio.server.plist" "${TMP_MOUNT_PATH}/Library/Preferences/com.deploystudio.server.plist"
  if [ -n "${SERVER_URL}" ]
  then
    defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server server -dict-add url "${SERVER_URL}"
    if [ -n "${SERVER_URL2}" ] && [ "${SERVER_URL2}" != "${SERVER_URL}" ]
    then
      defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server server -dict-add url2 "${SERVER_URL2}"
    fi
  fi
  if [ -n "${SERVER_LOGIN}" ]
  then
    defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server server -dict-add login "${SERVER_LOGIN}"
    if [ -n "${SERVER_PASSWORD}" ]
    then
      defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server server -dict-add password "${SERVER_PASSWORD}"
    fi
  fi
  if [ -n "${SERVER_DISPLAY_LOGS}" ]
  then
    defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server runtime -dict-add displaylogs "YES"
  fi
  if [ -n "${TIMEOUT}" ]
  then
    defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server runtime -dict-add quitAfterCompletion "YES"
    defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server runtime -dict-add timeoutInSeconds "${TIMEOUT}"
  fi
  if [ -n "${CUSTOM_RUNTIME_TITLE}" ]
  then
    defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server runtime -dict-add customtitle "${CUSTOM_RUNTIME_TITLE}"
  fi
  chown root:admin "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server.plist 2>&1

  if [ ! -e "${TMP_MOUNT_PATH}/System/Installation" ]
  then
    mkdir "${TMP_MOUNT_PATH}/System/Installation" 2>&1
  fi

  if [ ! -e "${TMP_MOUNT_PATH}/Library/PrivilegedHelperTools" ]
  then
    mkdir "${TMP_MOUNT_PATH}/Library/PrivilegedHelperTools" 2>&1
    chmod 1755 "${TMP_MOUNT_PATH}/Library/PrivilegedHelperTools"
  fi
  
  # if [ ! -e "${TMP_MOUNT_PATH}/var/db/launchd.db" ]
  # then
  #   mkdir "${TMP_MOUNT_PATH}/var/db/launchd.db"
  # else
  #   rm -rf "${TMP_MOUNT_PATH}/var/db/launchd.db"/*
  # fi
  # mkdir "${TMP_MOUNT_PATH}/var/db/launchd.db/com.apple.launchd"
  # chown -R root:wheel "${TMP_MOUNT_PATH}/var/db/launchd.db" 2>&1
  # chmod -R 755 "${TMP_MOUNT_PATH}/var/db/launchd.db" 2>&1
  # 
  # if [ -e "${TMP_MOUNT_PATH}/var/db/mds" ]
  # then
  #   rm -rf "${TMP_MOUNT_PATH}/var/db/mds"
  # fi
  if [ -e "/Library/Application Support/DeployStudio" ]
  then
    ditto --rsrc "/Library/Application Support/DeployStudio" "${TMP_MOUNT_PATH}/Library/Application Support/DeployStudio" 2>&1
    chown -R root:admin "${TMP_MOUNT_PATH}/Library/Application Support/DeployStudio" 2>&1
  fi

  if [ -e "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration" ]
  then
    rm -rf "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration" 2>&1
  fi
  ditto --rsrc "${SYSBUILDER_FOLDER}/${SYS_VERS}/SystemConfiguration" "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration" 2>&1

  if [ -e "${TMP_MOUNT_PATH}/System/Library/LaunchDaemons" ]
  then
    rm -rf "${TMP_MOUNT_PATH}/System/Library/LaunchDaemons" 2>&1
  fi
  ditto --rsrc "${SYSBUILDER_FOLDER}/${SYS_VERS}/LaunchDaemons" "${TMP_MOUNT_PATH}/System/Library/LaunchDaemons" 2>&1
  chown -R root:wheel "${TMP_MOUNT_PATH}/System/Library/LaunchDaemons" 2>&1
  chmod 755 "${TMP_MOUNT_PATH}"/System/Library/LaunchDaemons 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/System/Library/LaunchDaemons/* 2>&1

  if [ -e "${TMP_MOUNT_PATH}/System/Library/LaunchAgents" ]
  then
    rm -rf "${TMP_MOUNT_PATH}/System/Library/LaunchAgents" 2>&1
  fi
  ditto --rsrc "${SYSBUILDER_FOLDER}/${SYS_VERS}/LaunchAgents" "${TMP_MOUNT_PATH}/System/Library/LaunchAgents" 2>&1
  chown -R root:wheel "${TMP_MOUNT_PATH}"/System/Library/LaunchAgents 2>&1
  chmod 755 "${TMP_MOUNT_PATH}"/System/Library/LaunchAgents 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/System/Library/LaunchAgents/* 2>&1

  rm "${TMP_MOUNT_PATH}"/tmp

  ln -s var/tmp "${TMP_MOUNT_PATH}"/tmp

  ditto /var/run/resolv.conf "${TMP_MOUNT_PATH}/var/run/resolv.conf" 2>&1
  ln -s /var/run/resolv.conf "${TMP_MOUNT_PATH}/etc/resolv.conf" 2>&1

  cp -R "${SYSBUILDER_FOLDER}/${SYS_VERS}"/etc/* "${TMP_MOUNT_PATH}/etc/" 2>&1
  sed s/__DISPLAY_SLEEP__/${DISPLAY_SLEEP}/g "${SYSBUILDER_FOLDER}/${SYS_VERS}"/etc/rc.install > "${TMP_MOUNT_PATH}"/etc/rc.install 2>&1
  chmod 555 "${TMP_MOUNT_PATH}"/etc/rc.install 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/etc/hostconfig 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/etc/rc.common 2>&1
  chmod 755 "${TMP_MOUNT_PATH}"/etc/rc.cdrom 2>&1

  rm -rf "${TMP_MOUNT_PATH}/var/log/"* 2>&1

  if [ -e "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration/preferences.plist" ]
  then
    rm "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration/preferences.plist" 2>&1
  fi

  if [ "${LANGUAGE_CODE}" == "auto" ]
  then
    GLOBAL_PREFERENCES_FILE=`find "${HOME}"/Library/Preferences/ByHost -name ".GlobalPreferences*" | head -n1`
    if [ -z "${GLOBAL_PREFERENCES_FILE}" ]
    then
      GLOBAL_PREFERENCES_FILE="${SYSBUILDER_FOLDER}/common/en.GlobalPreferences.plist"
    fi
    HITOOLBOX_FILE=`find "${HOME}"/Library/Preferences/ByHost -name "com.apple.HIToolbox*" | head -n1`
    if [ -z "${HITOOLBOX_FILE}" ]
    then
      HITOOLBOX_FILE="${SYSBUILDER_FOLDER}/common/en.com.apple.HIToolbox.plist"
    fi
  else
    GLOBAL_PREFERENCES_FILE="${SYSBUILDER_FOLDER}/common/${LANGUAGE_CODE}.GlobalPreferences.plist"
    HITOOLBOX_FILE="${SYSBUILDER_FOLDER}/common/${LANGUAGE_CODE}.com.apple.HIToolbox.plist"
  fi   

  ditto "${GLOBAL_PREFERENCES_FILE}" "${TMP_MOUNT_PATH}/Library/Preferences/.GlobalPreferences.plist" 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/Library/Preferences/.GlobalPreferences.plist 2>&1

  ditto "${HITOOLBOX_FILE}" "${TMP_MOUNT_PATH}/Library/Preferences/com.apple.HIToolbox.plist" 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.HIToolbox.plist 2>&1

  ditto "${GLOBAL_PREFERENCES_FILE}" "${TMP_MOUNT_PATH}/var/root/Library/Preferences/.GlobalPreferences.plist" 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/var/root/Library/Preferences/.GlobalPreferences.plist 2>&1

  ditto "${HITOOLBOX_FILE}" "${TMP_MOUNT_PATH}/var/root/Library/Preferences/com.apple.HIToolbox.plist" 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/var/root/Library/Preferences/com.apple.HIToolbox.plist 2>&1

  if [ -n "${ARD_PASSWORD}" ]
  then
    ditto --rsrc "${SYSBUILDER_FOLDER}"/${SYS_VERS}/com.apple.RemoteManagement.plist "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.RemoteManagement.plist 2>&1
	echo "${ARD_PASSWORD}" | perl -wne 'BEGIN { @k = unpack "C*", pack "H*", "1734516E8BA8C5E2FF1C39567390ADCA"}; chomp; s/^(.{8}).*/$1/; @p = unpack "C*", $_; foreach (@k) { printf "%02X", $_ ^ (shift @p || 0) }; print "\n"' > "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.VNCSettings.txt
    chown root:wheel "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.VNCSettings.txt 2>&1
    chmod 400 "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.VNCSettings.txt 2>&1

	if [ -n "${ARD_LOGIN}" ]
	then
	  ARD_USER_SHORTNAME="${ARD_LOGIN}"
	else
	  ARD_USER_SHORTNAME="arduser"
    fi

    ditto "${SYSBUILDER_FOLDER}/${SYS_VERS}/arduser.plist" "${TMP_MOUNT_PATH}/var/db/dslocal/nodes/Default/users/${ARD_USER_SHORTNAME}.plist" 2>&1
	"${SYSBUILDER_FOLDER}/${SYS_VERS}"/setShadowHashData "${TMP_MOUNT_PATH}/var/db/dslocal/nodes/Default/users/${ARD_USER_SHORTNAME}.plist" "${ARD_PASSWORD}"
	if [ "${ARD_LOGIN}" != "arduser" ]
	then
      defaults write "${TMP_MOUNT_PATH}/var/db/dslocal/nodes/Default/users/${ARD_USER_SHORTNAME}" realname -array "${ARD_USER_SHORTNAME}"
      defaults write "${TMP_MOUNT_PATH}/var/db/dslocal/nodes/Default/users/${ARD_USER_SHORTNAME}" name -array "${ARD_USER_SHORTNAME}"
    fi
    chmod 600 "${TMP_MOUNT_PATH}/var/db/dslocal/nodes/Default/users/${ARD_USER_SHORTNAME}.plist" 2>&1
  fi

  if [ -n "${NTP_SERVER}" ]
  then
    echo "${NTP_SERVER}" > "${TMP_MOUNT_PATH}"/Library/Preferences/ntpserver.txt
    chmod 644 "${TMP_MOUNT_PATH}"/Library/Preferences/ntpserver.txt 2>&1
    chown root:wheel "${TMP_MOUNT_PATH}"/Library/Preferences/ntpserver.txt 2>&1
  fi

  mkdir "${TMP_MOUNT_PATH}"/Library/Caches 2>&1
  chmod 1777 "${TMP_MOUNT_PATH}"/Library/Caches 2>&1
  chown -R root:admin "${TMP_MOUNT_PATH}"/Library/Caches 2>&1

  # improve tcp performance (risky)
  if [ -n "${ENABLE_CUSTOM_TCP_STACK_SETTINGS}" ]
  then
    enable_custom_tcp_stack_settings
  fi

  chmod -R 644 "${TMP_MOUNT_PATH}"/Library/Preferences/* 2>&1
  chmod 755 "${TMP_MOUNT_PATH}"/Library/Preferences/DirectoryService 2>&1
  chmod 755 "${TMP_MOUNT_PATH}"/Library/Preferences/SystemConfiguration 2>&1
  chown -R root:wheel "${TMP_MOUNT_PATH}"/Library/Preferences/* 2>&1

  touch "${TMP_MOUNT_PATH}"/System/Library/CoreServices/ServerVersion.plist 2>&1
  chmod 444 "${TMP_MOUNT_PATH}"/System/Library/CoreServices/ServerVersion.plist 2>&1
  chown root:wheel "${TMP_MOUNT_PATH}"/System/Library/CoreServices/ServerVersion.plist 2>&1

  if [ -n "${CUSTOM_RUNTIME_BACKGROUND}" ] && [ -f "${CUSTOM_RUNTIME_BACKGROUND}" ]
  then
    ditto --rsrc "${CUSTOM_RUNTIME_BACKGROUND}" "${TMP_MOUNT_PATH}"/System/Library/CoreServices/DefaultDesktop.jpg
  else
    ditto --rsrc "${SYSBUILDER_FOLDER}"/common/DefaultDesktop.jpg "${TMP_MOUNT_PATH}"/System/Library/CoreServices/DefaultDesktop.jpg
  fi

  if [ -e "/Applications/Utilities/DeployStudio Admin.app" ]
  then
    ditto --rsrc "/Applications/Utilities/DeployStudio Admin.app" "${TMP_MOUNT_PATH}/Applications/Utilities/DeployStudio Admin.app" 2>&1
  elif [ -e "${SYSBUILDER_FOLDER}/../../../../Applications/Utilities/DeployStudio Admin.app" ]
  then
    ditto --rsrc "${SYSBUILDER_FOLDER}/../../../../Applications/Utilities/DeployStudio Admin.app" "${TMP_MOUNT_PATH}/Applications/Utilities/DeployStudio Admin.app" 2>&1
  fi
  chown -R root:admin "${TMP_MOUNT_PATH}/Applications/Utilities/DeployStudio Admin.app" 2>&1

  # disable spotlight indexing again (just in case)
  mdutil -i off "${TMP_MOUNT_PATH}"
  mdutil -E "${TMP_MOUNT_PATH}"
  defaults write "${TMP_MOUNT_PATH}"/.Spotlight-V100/_IndexPolicy Policy -int 3

  rm -rf "${TMP_MOUNT_PATH}"/System/Library/Caches/com.apple.bootstamps
  rm -rf "${TMP_MOUNT_PATH}"/System/Library/Caches/*
  rm -r  "${TMP_MOUNT_PATH}"/System/Library/Extensions.mkext
  rm -rf "${TMP_MOUNT_PATH}"/System/Library/SystemProfiler/SPManagedClientReporter.spreporter
  rm -rf "${TMP_MOUNT_PATH}"/System/Library/SystemProfiler/SPConfigurationProfileReporter.spreporter
  rm -r  "${TMP_MOUNT_PATH}"/usr/standalone/bootcaches.plist
  rm -f  "${TMP_MOUNT_PATH}"/var/db/BootCache*

  if [ -e "${TMP_MOUNT_PATH}"/Volumes ]
  then
    rm -rf "${TMP_MOUNT_PATH}"/Volumes/* 2>&1
  fi
}

fill_volume_1073() {
  # disable spotlight indexing
  mdutil -i off "${TMP_MOUNT_PATH}"
  mdutil -E "${TMP_MOUNT_PATH}"
  defaults write "${TMP_MOUNT_PATH}"/.Spotlight-V100/_IndexPolicy Policy -int 3

  # build BaseSystem bom
  lsbom -s /var/db/receipts/com.apple.pkg.BaseSystemBinaries.bom   > /tmp/dss_bs.txt
  lsbom -s /var/db/receipts/com.apple.pkg.BaseSystemResources.bom >> /tmp/dss_bs.txt
  sort -u /tmp/dss_bs.txt > /tmp/dss_bs_sorted.txt
  mkbom -s -i /tmp/dss_bs_sorted.txt /tmp/dss_bs.bom
  
  # start adding content to the volume
  ditto -bom /tmp/dss_bs.bom / "${TMP_MOUNT_PATH}" 2>&1
  
  # temp files cleanup
  rm /tmp/dss_bs.txt /tmp/dss_bs_sorted.txt /tmp/dss_bs.bom

  # add extra content
  # ETC_CONF="pam.d smb.conf smb.conf.template"
  # for A_ETC_CONF in ${ETC_CONF}
  # do
  #   ditto_file_at_path "${A_ETC_CONF}" /etc
  # done
  # ditto /var/db/smb.conf "${TMP_MOUNT_PATH}/var/db/smb.conf" 2>&1
  # 
  USR_LIB_SYS="libsystem_notify.dylib"
  for A_LIB_SYS in ${USR_LIB_SYS}
  do
    ditto_file_at_path "${A_LIB_SYS}" /usr/lib/system
  done

  cp -p -R /usr/lib/libsvn_* "${TMP_MOUNT_PATH}"/usr/lib/ 2>&1
  cp -p -R /usr/lib/libxar* "${TMP_MOUNT_PATH}"/usr/lib/ 2>&1

  USR_BIN="afconvert afinfo afplay atos auval auvaltool basename cd chgrp curl diff dirname dscl du egrep \
           erb expect false fgrep fs_usage grep gunzip gzip irb lsbom mkbom open printf rails rake rdoc ri rsync \
           ruby say smbutil srm sw_vers syslog testrb xattr xattr-2.5 xattr-2.6 xattr-2.7 xxd"
  for A_BIN in ${USR_BIN}
  do
    ditto_file_at_path "${A_BIN}" /usr/bin
  done

  USR_SBIN="gssd hwmond iostat ntpdate smbd systemkeychain vsdbutil"
  for A_SBIN in ${USR_SBIN}
  do
    ditto_file_at_path "${A_SBIN}" /usr/sbin
  done
  
  # USR_SHARE="sandbox terminfo zoneinfo"
  # for A_SHARE in ${USR_SHARE}
  # do
  #   ditto_file_at_path "${A_SHARE}" /usr/share
  # done
  # 
  USR_LIBEXEC="launchdadd samba security-checksystem"
  for A_LIBEXEC in ${USR_LIBEXEC}
  do
    ditto_file_at_path "${A_LIBEXEC}" /usr/libexec
  done
  
  ditto --rsrc "${SYSBUILDER_FOLDER}"/common/StartupDisk.app "${TMP_MOUNT_PATH}"/Applications/Utilities/StartupDisk.app
  if [ -z ${DISABLE_AD_VIEWER} ]
  then
    ditto --rsrc "${SYSBUILDER_FOLDER}"/common/AdViewer.app "${TMP_MOUNT_PATH}"/Applications/AdViewer.app
  fi
  # 
  # LIB_MISC="ColorSync Perl"
  # for A_LIB in ${LIB_MISC}
  # do
  #   ditto_file_at_path "${A_LIB}" /Library
  # done
  # 
  ditto_file_at_path smb.bundle /Library/Filesystems/NetFSPlugins
  # 
  # SYS_LIB="Displays KerberosPlugins LoginPlugins Perl Sandbox"
  SYS_LIB="DirectoryServices OpenDirectory"
  for A_SYS_LIB in ${SYS_LIB}
  do
    ditto_file_at_path "${A_SYS_LIB}" /System/Library
  done

  # SYS_LIB_CORE="CoreTypes.bundle KernelEventAgent.bundle RemoteManagement SecurityAgentPlugins"
  SYS_LIB_CORE="ZoomWindow.app RemoteManagement"
  for A_SYS_LIB_CORE in ${SYS_LIB_CORE}
  do
    ditto_file_at_path "${A_SYS_LIB_CORE}" /System/Library/CoreServices
  done

  ditto_file_at_path Sounds /System/Library

  SYS_LIB_EXT="IOPlatformPluginFamily AppleIntelHD3000Graphics"
  for A_SYS_LIB_EXT in ${SYS_LIB_EXT}
  do
    ditto_file_at_path "${A_SYS_LIB_EXT}.kext" /System/Library/Extensions
  done
  # 
  # SYS_LIB_EXT_BDL="ATIRadeonX2000GLDriver ATIRadeonX2000VADriver ATIRadeonX3000GLDriver ATIRadeonX3000VADriver \
  #                  AppleIntelHD3000GraphicsGLDriver AppleIntelHD3000GraphicsVADriver AppleIntelHDGraphicsGLDriver \
  #                  GeForceGLDriver"
  # for A_SYS_LIB_EXT_BDL in ${SYS_LIB_EXT_BDL}
  # do
  #   ditto_file_at_path "${A_SYS_LIB_EXT_BDL}.bundle" /System/Library/Extensions
  # done
  # 
  # SYS_LIB_EXT_PLUG="ATIRadeonX2000GA ATIRadeonX3000GA AppleIntelHD3000GraphicsGA"
  # for A_SYS_LIB_EXT_PLUG in ${SYS_LIB_EXT_PLUG}
  # do
  #   ditto_file_at_path "${A_SYS_LIB_EXT_PLUG}.plugin" /System/Library/Extensions
  # done
  # 
  SYS_LIB_FRK="AppleScriptObjC AVFoundation AddressBook Automator CalendarStore Carbon CoreMIDI FWAUserLib IMServicePlugIn \
               IOBluetooth InstantMessage Message nt OpenAL OpenGL OSAKit QuickTime Ruby RubyCocoa ScriptingBridge \
               ServerNotification Tcl"
  for A_SYS_LIB_FRK in ${SYS_LIB_FRK}
  do
    ditto_file_at_path "${A_SYS_LIB_FRK}.framework" /System/Library/Frameworks
  done
	# 
	#   SYS_LIB_PREF_PANES="StartupDisk"
	#   for A_SYS_LIB_PREF_PANE in ${SYS_LIB_PREF_PANES}
	#   do
	#     ditto_file_at_path "${A_SYS_LIB_PREF_PANE}.prefPane" /System/Library/PreferencePanes
	#   done
	# 
  SYS_LIB_PRIV_FRK="AOSMigrate ByteRangeLocking CalDAV CaptiveNetwork ClockMenuExtraPreferences ConfigProfileHelper ConfigurationProfiles \
                    CoreDaemon CoreDAV DCERPC DataDetectors DotMacLegacy DotMacSyncManager ExchangeWebServices FTServices FWAVC \
                    FaceCoreLight GoogleContactSync HeimODAdmin IMCore InternetAccounts JavaLaunching MacRuby Marco MDSChannel \
                    PasswordServer PhoneNumbers PrintingPrivate SMBClient ServerFoundation ServerKit SoftwareUpdate SpotlightIndex \
                    SyncServicesUI SystemUIPlugin UniversalAccess WhitePages XMPPCore YahooSync iCalendar login vmutils nt"
  for A_SYS_LIB_PRIV_FRK in ${SYS_LIB_PRIV_FRK}
  do
    ditto_file_at_path "${A_SYS_LIB_PRIV_FRK}.framework" /System/Library/PrivateFrameworks
  done

  if [ -e "${TMP_MOUNT_PATH}"/System/Library/Fonts ] 
  then
    rm -rf "${TMP_MOUNT_PATH}"/System/Library/Fonts
  fi
  ditto --rsrc /System/Library/Fonts "${TMP_MOUNT_PATH}/System/Library/Fonts" 

  if [ -e "${TMP_MOUNT_PATH}"/System/Library/SystemProfiler ] 
  then
    rm -rf "${TMP_MOUNT_PATH}"/System/Library/SystemProfiler
  fi
  ditto --rsrc /System/Library/SystemProfiler "${TMP_MOUNT_PATH}/System/Library/SystemProfiler" 

  if [ -e "${TMP_MOUNT_PATH}"/System/Library/Tcl ] 
  then
    rm -rf "${TMP_MOUNT_PATH}"/System/Library/Tcl
  fi
  ditto --rsrc /System/Library/Tcl "${TMP_MOUNT_PATH}/System/Library/Tcl" 
  
  ditto_file_at_path Perl   /Library
  ditto_file_at_path Perl   /System/Library

  if [ -n "${ENABLE_PYTHON}" ]
  then
    ditto_file_at_path Python /Library
	cp -p -R /usr/lib/python* "${TMP_MOUNT_PATH}"/usr/lib/ 2>&1
	ditto_file_at_path python /usr/bin
  fi
	
  if [ -n "${ENABLE_RUBY}" ]
  then
    ditto_file_at_path Ruby /Library
    ditto_file_at_path ruby /usr/lib
  fi

  # Display mirroring support
  ditto --rsrc  "${SYSBUILDER_FOLDER}"/common/enableDisplayMirroring "${TMP_MOUNT_PATH}"/usr/bin/enableDisplayMirroring 2>&1
  chmod 755 "${TMP_MOUNT_PATH}"/usr/bin/enableDisplayMirroring 2>&1
  chown root:wheel "${TMP_MOUNT_PATH}"/usr/bin/enableDisplayMirroring 2>&1

  rm "${TMP_MOUNT_PATH}"/mach
  ln -s /mach_kernel "${TMP_MOUNT_PATH}"/mach

  cp "${SYSBUILDER_FOLDER}/common/com.deploystudio.server.plist" "${TMP_MOUNT_PATH}/Library/Preferences/com.deploystudio.server.plist"
  if [ -n "${SERVER_URL}" ]
  then
    defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server server -dict-add url "${SERVER_URL}"
    if [ -n "${SERVER_URL2}" ] && [ "${SERVER_URL2}" != "${SERVER_URL}" ]
    then
      defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server server -dict-add url2 "${SERVER_URL2}"
    fi
  fi
  if [ -n "${SERVER_LOGIN}" ]
  then
    defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server server -dict-add login "${SERVER_LOGIN}"
    if [ -n "${SERVER_PASSWORD}" ]
    then
      defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server server -dict-add password "${SERVER_PASSWORD}"
    fi
  fi
  if [ -n "${SERVER_DISPLAY_LOGS}" ]
  then
    defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server runtime -dict-add displaylogs "YES"
  fi
  if [ -n "${TIMEOUT}" ]
  then
    defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server runtime -dict-add quitAfterCompletion "YES"
    defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server runtime -dict-add timeoutInSeconds "${TIMEOUT}"
  fi
  if [ -n "${CUSTOM_RUNTIME_TITLE}" ]
  then
    defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server runtime -dict-add customtitle "${CUSTOM_RUNTIME_TITLE}"
  fi
  chown root:admin "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server.plist 2>&1

  if [ ! -e "${TMP_MOUNT_PATH}/System/Installation" ]
  then
    mkdir "${TMP_MOUNT_PATH}/System/Installation" 2>&1
  fi

  if [ ! -e "${TMP_MOUNT_PATH}/Library/PrivilegedHelperTools" ]
  then
    mkdir "${TMP_MOUNT_PATH}/Library/PrivilegedHelperTools" 2>&1
    chmod 1755 "${TMP_MOUNT_PATH}/Library/PrivilegedHelperTools"
  fi
  
  # if [ ! -e "${TMP_MOUNT_PATH}/var/db/launchd.db" ]
  # then
  #   mkdir "${TMP_MOUNT_PATH}/var/db/launchd.db"
  # else
  #   rm -rf "${TMP_MOUNT_PATH}/var/db/launchd.db"/*
  # fi
  # mkdir "${TMP_MOUNT_PATH}/var/db/launchd.db/com.apple.launchd"
  # chown -R root:wheel "${TMP_MOUNT_PATH}/var/db/launchd.db" 2>&1
  # chmod -R 755 "${TMP_MOUNT_PATH}/var/db/launchd.db" 2>&1
  # 
  # if [ -e "${TMP_MOUNT_PATH}/var/db/mds" ]
  # then
  #   rm -rf "${TMP_MOUNT_PATH}/var/db/mds"
  # fi
  if [ -e "/Library/Application Support/DeployStudio" ]
  then
    ditto --rsrc "/Library/Application Support/DeployStudio" "${TMP_MOUNT_PATH}/Library/Application Support/DeployStudio" 2>&1
    chown -R root:admin "${TMP_MOUNT_PATH}/Library/Application Support/DeployStudio" 2>&1
  fi

  if [ -e "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration" ]
  then
    rm -rf "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration" 2>&1
  fi
  ditto --rsrc "${SYSBUILDER_FOLDER}/${SYS_VERS}/SystemConfiguration" "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration" 2>&1

  if [ -e "${TMP_MOUNT_PATH}/System/Library/LaunchDaemons" ]
  then
    rm -rf "${TMP_MOUNT_PATH}/System/Library/LaunchDaemons" 2>&1
  fi
  ditto --rsrc "${SYSBUILDER_FOLDER}/${SYS_VERS}/LaunchDaemons" "${TMP_MOUNT_PATH}/System/Library/LaunchDaemons" 2>&1
  chown -R root:wheel "${TMP_MOUNT_PATH}/System/Library/LaunchDaemons" 2>&1
  chmod 755 "${TMP_MOUNT_PATH}"/System/Library/LaunchDaemons 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/System/Library/LaunchDaemons/* 2>&1

  if [ -e "${TMP_MOUNT_PATH}/System/Library/LaunchAgents" ]
  then
    rm -rf "${TMP_MOUNT_PATH}/System/Library/LaunchAgents" 2>&1
  fi
  ditto --rsrc "${SYSBUILDER_FOLDER}/${SYS_VERS}/LaunchAgents" "${TMP_MOUNT_PATH}/System/Library/LaunchAgents" 2>&1
  chown -R root:wheel "${TMP_MOUNT_PATH}"/System/Library/LaunchAgents 2>&1
  chmod 755 "${TMP_MOUNT_PATH}"/System/Library/LaunchAgents 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/System/Library/LaunchAgents/* 2>&1

  rm "${TMP_MOUNT_PATH}"/tmp

  ln -s var/tmp "${TMP_MOUNT_PATH}"/tmp

  ditto /var/run/resolv.conf "${TMP_MOUNT_PATH}/var/run/resolv.conf" 2>&1
  ln -s /var/run/resolv.conf "${TMP_MOUNT_PATH}/etc/resolv.conf" 2>&1

  cp -R "${SYSBUILDER_FOLDER}/${SYS_VERS}"/etc/* "${TMP_MOUNT_PATH}/etc/" 2>&1
  sed s/__DISPLAY_SLEEP__/${DISPLAY_SLEEP}/g "${SYSBUILDER_FOLDER}/${SYS_VERS}"/etc/rc.install > "${TMP_MOUNT_PATH}"/etc/rc.install 2>&1
  chmod 555 "${TMP_MOUNT_PATH}"/etc/rc.install 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/etc/hostconfig 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/etc/rc.common 2>&1
  chmod 755 "${TMP_MOUNT_PATH}"/etc/rc.cdrom 2>&1

  rm -rf "${TMP_MOUNT_PATH}/var/log/"* 2>&1

  if [ -e "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration/preferences.plist" ]
  then
    rm "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration/preferences.plist" 2>&1
  fi

  if [ "${LANGUAGE_CODE}" == "auto" ]
  then
    GLOBAL_PREFERENCES_FILE=`find "${HOME}"/Library/Preferences/ByHost -name ".GlobalPreferences*" | head -n1`
    if [ -z "${GLOBAL_PREFERENCES_FILE}" ]
    then
      GLOBAL_PREFERENCES_FILE="${SYSBUILDER_FOLDER}/common/en.GlobalPreferences.plist"
    fi
    HITOOLBOX_FILE=`find "${HOME}"/Library/Preferences/ByHost -name "com.apple.HIToolbox*" | head -n1`
    if [ -z "${HITOOLBOX_FILE}" ]
    then
      HITOOLBOX_FILE="${SYSBUILDER_FOLDER}/common/en.com.apple.HIToolbox.plist"
    fi
  else
    GLOBAL_PREFERENCES_FILE="${SYSBUILDER_FOLDER}/common/${LANGUAGE_CODE}.GlobalPreferences.plist"
    HITOOLBOX_FILE="${SYSBUILDER_FOLDER}/common/${LANGUAGE_CODE}.com.apple.HIToolbox.plist"
  fi   

  ditto "${GLOBAL_PREFERENCES_FILE}" "${TMP_MOUNT_PATH}/Library/Preferences/.GlobalPreferences.plist" 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/Library/Preferences/.GlobalPreferences.plist 2>&1

  ditto "${HITOOLBOX_FILE}" "${TMP_MOUNT_PATH}/Library/Preferences/com.apple.HIToolbox.plist" 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.HIToolbox.plist 2>&1

  ditto "${GLOBAL_PREFERENCES_FILE}" "${TMP_MOUNT_PATH}/var/root/Library/Preferences/.GlobalPreferences.plist" 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/var/root/Library/Preferences/.GlobalPreferences.plist 2>&1

  ditto "${HITOOLBOX_FILE}" "${TMP_MOUNT_PATH}/var/root/Library/Preferences/com.apple.HIToolbox.plist" 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/var/root/Library/Preferences/com.apple.HIToolbox.plist 2>&1

  if [ -n "${ARD_PASSWORD}" ]
  then
    ditto --rsrc "${SYSBUILDER_FOLDER}"/${SYS_VERS}/com.apple.RemoteManagement.plist "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.RemoteManagement.plist 2>&1
	echo "${ARD_PASSWORD}" | perl -wne 'BEGIN { @k = unpack "C*", pack "H*", "1734516E8BA8C5E2FF1C39567390ADCA"}; chomp; s/^(.{8}).*/$1/; @p = unpack "C*", $_; foreach (@k) { printf "%02X", $_ ^ (shift @p || 0) }; print "\n"' > "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.VNCSettings.txt
    chown root:wheel "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.VNCSettings.txt 2>&1
    chmod 400 "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.VNCSettings.txt 2>&1

	if [ -n "${ARD_LOGIN}" ]
	then
	  ARD_USER_SHORTNAME="${ARD_LOGIN}"
	else
	  ARD_USER_SHORTNAME="arduser"
    fi

    ditto "${SYSBUILDER_FOLDER}/${SYS_VERS}/arduser.plist" "${TMP_MOUNT_PATH}/var/db/dslocal/nodes/Default/users/${ARD_USER_SHORTNAME}.plist" 2>&1
	"${SYSBUILDER_FOLDER}/${SYS_VERS}"/setShadowHashData "${TMP_MOUNT_PATH}/var/db/dslocal/nodes/Default/users/${ARD_USER_SHORTNAME}.plist" "${ARD_PASSWORD}"
	if [ "${ARD_LOGIN}" != "arduser" ]
	then
      defaults write "${TMP_MOUNT_PATH}/var/db/dslocal/nodes/Default/users/${ARD_USER_SHORTNAME}" realname -array "${ARD_USER_SHORTNAME}"
      defaults write "${TMP_MOUNT_PATH}/var/db/dslocal/nodes/Default/users/${ARD_USER_SHORTNAME}" name -array "${ARD_USER_SHORTNAME}"
    fi
    chmod 600 "${TMP_MOUNT_PATH}/var/db/dslocal/nodes/Default/users/${ARD_USER_SHORTNAME}.plist" 2>&1
  fi

  if [ -n "${NTP_SERVER}" ]
  then
    echo "${NTP_SERVER}" > "${TMP_MOUNT_PATH}"/Library/Preferences/ntpserver.txt
    chmod 644 "${TMP_MOUNT_PATH}"/Library/Preferences/ntpserver.txt 2>&1
    chown root:wheel "${TMP_MOUNT_PATH}"/Library/Preferences/ntpserver.txt 2>&1
  fi

  mkdir "${TMP_MOUNT_PATH}"/Library/Caches 2>&1
  chmod 1777 "${TMP_MOUNT_PATH}"/Library/Caches 2>&1
  chown -R root:admin "${TMP_MOUNT_PATH}"/Library/Caches 2>&1

  # improve tcp performance (risky)
  if [ -n "${ENABLE_CUSTOM_TCP_STACK_SETTINGS}" ]
  then
    enable_custom_tcp_stack_settings
  fi

  chmod -R 644 "${TMP_MOUNT_PATH}"/Library/Preferences/* 2>&1
  chmod 755 "${TMP_MOUNT_PATH}"/Library/Preferences/DirectoryService 2>&1
  chmod 755 "${TMP_MOUNT_PATH}"/Library/Preferences/SystemConfiguration 2>&1
  chown -R root:wheel "${TMP_MOUNT_PATH}"/Library/Preferences/* 2>&1

  touch "${TMP_MOUNT_PATH}"/System/Library/CoreServices/ServerVersion.plist 2>&1
  chmod 444 "${TMP_MOUNT_PATH}"/System/Library/CoreServices/ServerVersion.plist 2>&1
  chown root:wheel "${TMP_MOUNT_PATH}"/System/Library/CoreServices/ServerVersion.plist 2>&1

  if [ -n "${CUSTOM_RUNTIME_BACKGROUND}" ] && [ -f "${CUSTOM_RUNTIME_BACKGROUND}" ]
  then
    ditto --rsrc "${CUSTOM_RUNTIME_BACKGROUND}" "${TMP_MOUNT_PATH}"/System/Library/CoreServices/DefaultDesktop.jpg
  else
    ditto --rsrc "${SYSBUILDER_FOLDER}"/common/DefaultDesktop.jpg "${TMP_MOUNT_PATH}"/System/Library/CoreServices/DefaultDesktop.jpg
  fi

  if [ -e "/Applications/Utilities/DeployStudio Admin.app" ]
  then
    ditto --rsrc "/Applications/Utilities/DeployStudio Admin.app" "${TMP_MOUNT_PATH}/Applications/Utilities/DeployStudio Admin.app" 2>&1
  elif [ -e "${SYSBUILDER_FOLDER}/../../../../Applications/Utilities/DeployStudio Admin.app" ]
  then
    ditto --rsrc "${SYSBUILDER_FOLDER}/../../../../Applications/Utilities/DeployStudio Admin.app" "${TMP_MOUNT_PATH}/Applications/Utilities/DeployStudio Admin.app" 2>&1
  fi
  chown -R root:admin "${TMP_MOUNT_PATH}/Applications/Utilities/DeployStudio Admin.app" 2>&1

  # disable spotlight indexing again (just in case)
  mdutil -i off "${TMP_MOUNT_PATH}"
  mdutil -E "${TMP_MOUNT_PATH}"
  defaults write "${TMP_MOUNT_PATH}"/.Spotlight-V100/_IndexPolicy Policy -int 3

  rm -rf "${TMP_MOUNT_PATH}"/System/Library/Caches/com.apple.bootstamps
  rm -rf "${TMP_MOUNT_PATH}"/System/Library/Caches/*
  rm -r  "${TMP_MOUNT_PATH}"/System/Library/Extensions.mkext
  rm -r  "${TMP_MOUNT_PATH}"/usr/standalone/bootcaches.plist
  rm -f  "${TMP_MOUNT_PATH}"/var/db/BootCache*

  if [ -e "${TMP_MOUNT_PATH}"/Volumes ]
  then
    rm -rf "${TMP_MOUNT_PATH}"/Volumes/* 2>&1
  fi
}

fill_volume_1070() {
  # disable spotlight indexing
  mdutil -i off "${TMP_MOUNT_PATH}"
  mdutil -E "${TMP_MOUNT_PATH}"
  defaults write "${TMP_MOUNT_PATH}"/.Spotlight-V100/_IndexPolicy Policy -int 3

  # start adding content to the volume
  ditto -bom "${SYSBUILDER_FOLDER}/${SYS_VERS}/${ARCH}.bom" / "${TMP_MOUNT_PATH}" 2>&1

##  rm -rf "${TMP_MOUNT_PATH}"/System/Library/Extensions/IOSerialFamily.kext/Contents/PlugIns/*

  ETC_CONF="pam.d smb.conf smb.conf.template"
  for A_ETC_CONF in ${ETC_CONF}
  do
    ditto_file_at_path "${A_ETC_CONF}" /etc
  done
  ditto /var/db/smb.conf "${TMP_MOUNT_PATH}/var/db/smb.conf" 2>&1

  USR_LIB_SYS="libsystem_notify.dylib"
  for A_LIB_SYS in ${USR_LIB_SYS}
  do
    ditto_file_at_path "${A_LIB_SYS}" /usr/lib/system
  done

  USR_LIB="libapr-1.0.3.8.dylib libaprutil-1.0.3.9.dylib libtcl.dylib libtk.dylib libXplugin.1.dylib \
           libnetsnmp.15.1.2.dylib libnetsnmp.15.dylib libz.1.2.5.dylib libwebsharing.dylib \ 
           mecab pkgconfig samba sasl2 libsystem_notify.dylib"
  for A_LIB in ${USR_LIB}
  do
    ditto_file_at_path "${A_LIB}" /usr/lib
  done

  USR_BIN="afconvert afinfo afplay atos auval auvaltool basename cd chgrp curl diff dirname dscl du egrep \
           false fgrep fs_usage gunzip gzip lsbom mkbom nmblookup ntlm_auth open printf rsync say srm \
		   smbcacls smbclient smbcontrol smbcquotas smbget smbpasswd smbspool smbstatus smbtree smbutil \
		   uuidgen xxd syslog"
  for A_BIN in ${USR_BIN}
  do
    ditto_file_at_path "${A_BIN}" /usr/bin
  done

  USR_SBIN="gssd iostat nmbd ntpdate smbd systemkeychain vsdbutil filecoordinationd"
  for A_SBIN in ${USR_SBIN}
  do
    ditto_file_at_path "${A_SBIN}" /usr/sbin
  done

  USR_SHARE="sandbox terminfo zoneinfo"
  for A_SHARE in ${USR_SHARE}
  do
    ditto_file_at_path "${A_SHARE}" /usr/share
  done

  USR_LIBEXEC="samba security-checksystem launchdadd"
  for A_LIBEXEC in ${USR_LIBEXEC}
  do
    ditto_file_at_path "${A_LIBEXEC}" /usr/libexec
  done

  USR_X11_LIBS="libXau.6.dylib libXdmcp.6.dylib libxcb.1.dylib"
  for A_USR_X11_LIB in ${USR_X11_LIBS}
  do
    ditto_file_at_path "${A_USR_X11_LIB}" /usr/X11/lib
  done

  ditto_file_at_path "Disk Utility.app" /Applications/Utilities
  ditto_file_at_path "Network Utility.app" /Applications/Utilities
  ditto_file_at_path "RAID Utility.app" /Applications/Utilities
  ditto_file_at_path "System Profiler.app" /Applications/Utilities
  ditto_file_at_path "Terminal.app" /Applications/Utilities

  ditto_file_at_path standalone /usr

  ditto --rsrc "${SYSBUILDER_FOLDER}"/common/StartupDisk.app "${TMP_MOUNT_PATH}"/Applications/Utilities/StartupDisk.app
  if [ -z ${DISABLE_AD_VIEWER} ]
  then
    ditto --rsrc "${SYSBUILDER_FOLDER}"/common/AdViewer.app "${TMP_MOUNT_PATH}"/Applications/AdViewer.app
  fi

  LIB_MISC="ColorSync Perl"
  for A_LIB in ${LIB_MISC}
  do
    ditto_file_at_path "${A_LIB}" /Library
  done

  ditto_file_at_path NetFSPlugins /Library/Filesystems

  SYS_LIB="DirectoryServices Displays Filesystems KerberosPlugins LoginPlugins OpenDirectory Perl Sandbox"
  for A_SYS_LIB in ${SYS_LIB}
  do
    ditto_file_at_path "${A_SYS_LIB}" /System/Library
  done

  SYS_LIB_COMP="AudioCodecs CoreAudio"
  for A_SYS_LIB_COMP in ${SYS_LIB_COMP}
  do
    ditto_file_at_path "${A_SYS_LIB_COMP}.component" /System/Library/Components
  done

  SYS_LIB_CORE="CoreTypes.bundle KernelEventAgent.bundle RemoteManagement SecurityAgentPlugins"
  for A_SYS_LIB_CORE in ${SYS_LIB_CORE}
  do
    ditto_file_at_path "${A_SYS_LIB_CORE}" /System/Library/CoreServices
  done

  ditto_file_at_path "TextInput.menu" "/System/Library/CoreServices/Menu Extras"
  ditto_file_at_path "Setup Assistant.app" /System/Library/CoreServices
  ditto_file_at_path Voices /System/Library/Speech
  ditto_file_at_path Sounds /System/Library

  SYS_LIB_EXT="AppleBMC AppleHIDKeyboard AppleProfileFamily \
			   AppleIntelHD3000Graphics AppleIntelSNBGraphicsFB AppleIntelSNBVA NVDAGF100Hal \
               ATI4500Controller BJUSBLoad IOPlatformPluginFamily \
			   IO80211Family AppleHDA System PromiseSTEX \
               AppleThunderboltDPAdapters AppleThunderboltNHI AppleThunderboltPCIAdapters AppleThunderboltUTDM IOThunderboltFamily"
  for A_SYS_LIB_EXT in ${SYS_LIB_EXT}
  do
    ditto_file_at_path "${A_SYS_LIB_EXT}.kext" /System/Library/Extensions
  done

# rm -rf "${TMP_MOUNT_PATH}"/System/Library/Extensions/IOSerialFamily.kext/Contents/PlugIns/InternalModemSupport.kext
# rm -rf "${TMP_MOUNT_PATH}"/System/Library/Extensions/SM56KUSBAudioFamily.kext/Contents/PlugIns/AppleSM56KUSBModemFamily.kext

  SYS_LIB_EXT_BDL="AppleIntelHDGraphicsGLDriver AppleIntelHDGraphicsVADriver AppleIntelHD3000GraphicsGLDriver AppleIntelHD3000GraphicsVADriver \
                   ATIRadeonX2000VADriver ATIRadeonX2000GLDriver ATIRadeonX3000VADriver ATIRadeonX3000GLDriver GeForceGLDriver AppleIntelSNBVA"
  for A_SYS_LIB_EXT_BDL in ${SYS_LIB_EXT_BDL}
  do
    ditto_file_at_path "${A_SYS_LIB_EXT_BDL}.bundle" /System/Library/Extensions
  done

  SYS_LIB_EXT_PLUG="AppleIntelHDGraphicsGA AppleIntelHD3000GraphicsGA ATIRadeonX2000GA ATIRadeonX3000GA"
  for A_SYS_LIB_EXT_PLUG in ${SYS_LIB_EXT_PLUG}
  do
    ditto_file_at_path "${A_SYS_LIB_EXT_PLUG}.plugin" /System/Library/Extensions
  done

  SYS_LIB_FRK="AppKit ApplicationServices CoreFoundation CoreVideo CoreServices IOBluetooth JavaScriptCore Kernel OpenCL OpenDirectory \
               OpenGL PreferencePanes Quartz Security WebKit AddressBook Automator CalendarStore Collaboration CoreAudioKit CoreMIDI \
               FWAUserLib InstantMessage Message OpenAL Tcl Tk AppleScriptObjC OSAKit ScriptingBridge ServerNotification AppleTalk \
               GLUT IMServicePlugIn ScreenSaver AVFoundation Python AppleConnect"
  for A_SYS_LIB_FRK in ${SYS_LIB_FRK}
  do
    ditto_file_at_path "${A_SYS_LIB_FRK}.framework" /System/Library/Frameworks
  done

  SYS_LIB_PREF_PANES="StartupDisk"
  for A_SYS_LIB_PREF_PANE in ${SYS_LIB_PREF_PANES}
  do
    ditto_file_at_path "${A_SYS_LIB_PREF_PANE}.prefPane" /System/Library/PreferencePanes
  done

  SYS_LIB_PRIV_FRK="CoreDaemon CoreMedia CoreMediaIOServices HelpData SMBClient DCERPC \
                    MobileDevice PlatformHardwareManagement ScreenSharing Shortcut \
                    AVFoundationCF AppleGVA CoreKE ByteRangeLocking ClockMenuExtraPreferences DataDetectors DeviceLink DotMacLegacy \
                    DotMacSyncManager FWAVC International MDSChannel MPWXmlCore PasswordServer PrintingPrivate ServerFoundation ServerKit \
                    SetupAssistant SetupAssistantSupport SoftwareUpdate SpotlightIndex SyncServicesUI SystemUIPlugin iCalendar \
                    ExchangeWebServices IntlPreferences OpenDirectoryConfig OpenDirectoryConfigUI WhitePages \
                    AppSandbox AppleProfileFamily ChunkingLibrary CoreServicesInternal GenerationalStorage \
                    iLifeMediaBrowser FTServices Marco XMPPCore AOSKit CalDAV CaptiveNetwork CoreDAV FaceCoreLight \
                    GoogleContactSync HeimODAdmin IMCore InternetAccounts MacRuby PerformanceAnalysis PhoneNumbers \
                    SemanticDocumentManagement YahooSync login XPCService JavaLaunching LoginUIKit \
                    AOSMigrate ConfigurationProfiles nt"
  for A_SYS_LIB_PRIV_FRK in ${SYS_LIB_PRIV_FRK}
  do
    ditto_file_at_path "${A_SYS_LIB_PRIV_FRK}.framework" /System/Library/PrivateFrameworks
  done

  for SYS_LIB_FONT_PATH in /System/Library/Fonts/*
  do
    SYS_LIB_FONT=`basename "${SYS_LIB_FONT_PATH}"`
    ditto_file_at_path "${SYS_LIB_FONT}" /System/Library/Fonts
  done

  rm -rf "${TMP_MOUNT_PATH}"/System/Library/SystemProfiler/*.spreporter
  SYS_LIB_PROFILERS="SPAirPortReporter SPAudioReporter SPBluetoothReporter SPDiagnosticsReporter SPDisplaysReporter SPEthernetReporter SPFibreChannelReporter SPFireWireReporter SPHardwareRAIDReporter \
                     SPMemoryReporter SPNetworkReporter SPOSReporter SPPCIReporter SPParallelATAReporter SPParallelSCSIReporter SPPlatformReporter SPPowerReporter \
				     SPSASReporter SPSerialATAReporter SPUSBReporter SPWWANReporter SPThunderboltReporter"
  for A_SYS_LIB_PROFILER in ${SYS_LIB_PROFILERS}
  do
    ditto_file_at_path "${A_SYS_LIB_PROFILER}.spreporter" /System/Library/SystemProfiler
  done

  ditto_file_at_path Perl   /Library
  ditto_file_at_path Perl   /System/Library

  if [ -n "${ENABLE_PYTHON}" ]
  then
    ditto_file_at_path Python /Library
	cp -p -R /usr/lib/python* "${TMP_MOUNT_PATH}"/usr/lib/ 2>&1
	ditto_file_at_path python /usr/bin
  fi

  if [ -n "${ENABLE_RUBY}" ]
  then
    ditto_file_at_path Ruby /Library
    ditto_file_at_path Ruby.framework /System/Library/Frameworks
    ditto_file_at_path ruby /usr/lib
  fi

  # Display mirroring support
  ditto --rsrc  "${SYSBUILDER_FOLDER}"/common/enableDisplayMirroring "${TMP_MOUNT_PATH}"/usr/bin/enableDisplayMirroring 2>&1
  chmod 755 "${TMP_MOUNT_PATH}"/usr/bin/enableDisplayMirroring 2>&1
  chown root:wheel "${TMP_MOUNT_PATH}"/usr/bin/enableDisplayMirroring 2>&1

  rm "${TMP_MOUNT_PATH}"/mach
  ln -s /mach_kernel "${TMP_MOUNT_PATH}"/mach

  cp "${SYSBUILDER_FOLDER}/common/com.deploystudio.server.plist" "${TMP_MOUNT_PATH}/Library/Preferences/com.deploystudio.server.plist"
  if [ -n "${SERVER_URL}" ]
  then
    defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server server -dict-add url "${SERVER_URL}"
    if [ -n "${SERVER_URL2}" ] && [ "${SERVER_URL2}" != "${SERVER_URL}" ]
    then
      defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server server -dict-add url2 "${SERVER_URL2}"
    fi
  fi
  if [ -n "${SERVER_LOGIN}" ]
  then
    defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server server -dict-add login "${SERVER_LOGIN}"
    if [ -n "${SERVER_PASSWORD}" ]
    then
      defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server server -dict-add password "${SERVER_PASSWORD}"
    fi
  fi
  if [ -n "${SERVER_DISPLAY_LOGS}" ]
  then
    defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server runtime -dict-add displaylogs "YES"
  fi
  if [ -n "${TIMEOUT}" ]
  then
    defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server runtime -dict-add quitAfterCompletion "YES"
    defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server runtime -dict-add timeoutInSeconds "${TIMEOUT}"
  fi
  if [ -n "${CUSTOM_RUNTIME_TITLE}" ]
  then
    defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server runtime -dict-add customtitle "${CUSTOM_RUNTIME_TITLE}"
  fi
  chown root:admin "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server.plist 2>&1

  if [ ! -e "${TMP_MOUNT_PATH}/System/Installation" ]
  then
    mkdir "${TMP_MOUNT_PATH}/System/Installation" 2>&1
  fi

  if [ ! -e "${TMP_MOUNT_PATH}/Library/Logs" ]
  then
    mkdir "${TMP_MOUNT_PATH}/Library/Logs" 2>&1
  fi

  if [ ! -e "${TMP_MOUNT_PATH}/Library/PrivilegedHelperTools" ]
  then
    mkdir "${TMP_MOUNT_PATH}/Library/PrivilegedHelperTools" 2>&1
    chmod 1755 "${TMP_MOUNT_PATH}/Library/PrivilegedHelperTools"
  fi

  if [ ! -e "${TMP_MOUNT_PATH}/var/db/launchd.db" ]
  then
    mkdir "${TMP_MOUNT_PATH}/var/db/launchd.db"
  else
    rm -rf "${TMP_MOUNT_PATH}/var/db/launchd.db"/*
  fi
  mkdir "${TMP_MOUNT_PATH}/var/db/launchd.db/com.apple.launchd"
  chown -R root:wheel "${TMP_MOUNT_PATH}/var/db/launchd.db" 2>&1
  chmod -R 755 "${TMP_MOUNT_PATH}/var/db/launchd.db" 2>&1

  if [ -e "${TMP_MOUNT_PATH}/var/db/mds" ]
  then
    rm -rf "${TMP_MOUNT_PATH}/var/db/mds"
  fi

  if [ -e "/Library/Application Support/DeployStudio" ]
  then
    ditto --rsrc "/Library/Application Support/DeployStudio" "${TMP_MOUNT_PATH}/Library/Application Support/DeployStudio" 2>&1
    chown -R root:admin "${TMP_MOUNT_PATH}/Library/Application Support/DeployStudio" 2>&1
  fi

  if [ -e "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration" ]
  then
    rm -rf "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration" 2>&1
  fi
  ditto --rsrc "${SYSBUILDER_FOLDER}/${SYS_VERS}/SystemConfiguration" "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration" 2>&1

  if [ -e "${TMP_MOUNT_PATH}/System/Library/LaunchDaemons" ]
  then
    rm -rf "${TMP_MOUNT_PATH}/System/Library/LaunchDaemons" 2>&1
  fi
  ditto --rsrc "${SYSBUILDER_FOLDER}/${SYS_VERS}/LaunchDaemons" "${TMP_MOUNT_PATH}/System/Library/LaunchDaemons" 2>&1
  chown -R root:wheel "${TMP_MOUNT_PATH}/System/Library/LaunchDaemons" 2>&1
  chmod 755 "${TMP_MOUNT_PATH}"/System/Library/LaunchDaemons 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/System/Library/LaunchDaemons/* 2>&1

  if [ -e "${TMP_MOUNT_PATH}/System/Library/LaunchAgents" ]
  then
    rm -rf "${TMP_MOUNT_PATH}/System/Library/LaunchAgents" 2>&1
  fi
  ditto --rsrc "${SYSBUILDER_FOLDER}/${SYS_VERS}/LaunchAgents" "${TMP_MOUNT_PATH}/System/Library/LaunchAgents" 2>&1
  chown -R root:wheel "${TMP_MOUNT_PATH}"/System/Library/LaunchAgents 2>&1
  chmod 755 "${TMP_MOUNT_PATH}"/System/Library/LaunchAgents 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/System/Library/LaunchAgents/* 2>&1

  rm "${TMP_MOUNT_PATH}"/tmp

  ln -s var/tmp "${TMP_MOUNT_PATH}"/tmp

  ditto /var/run/resolv.conf "${TMP_MOUNT_PATH}/var/run/resolv.conf" 2>&1
  ln -s /var/run/resolv.conf "${TMP_MOUNT_PATH}/etc/resolv.conf" 2>&1

  cp -R "${SYSBUILDER_FOLDER}/${SYS_VERS}"/etc/* "${TMP_MOUNT_PATH}/etc/" 2>&1
  sed s/__DISPLAY_SLEEP__/${DISPLAY_SLEEP}/g "${SYSBUILDER_FOLDER}/${SYS_VERS}"/etc/rc.install > "${TMP_MOUNT_PATH}"/etc/rc.install 2>&1
  chmod 555 "${TMP_MOUNT_PATH}"/etc/rc.install 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/etc/hostconfig 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/etc/rc.common 2>&1
  chmod 755 "${TMP_MOUNT_PATH}"/etc/rc.cdrom 2>&1

  rm -rf "${TMP_MOUNT_PATH}/var/log/"* 2>&1

  if [ -e "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration/preferences.plist" ]
  then
    rm "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration/preferences.plist" 2>&1
  fi

  if [ "${LANGUAGE_CODE}" == "auto" ]
  then
    GLOBAL_PREFERENCES_FILE=`find "${HOME}"/Library/Preferences/ByHost -name ".GlobalPreferences*" | head -n1`
    if [ -z "${GLOBAL_PREFERENCES_FILE}" ]
    then
      GLOBAL_PREFERENCES_FILE="${SYSBUILDER_FOLDER}/common/en.GlobalPreferences.plist"
    fi
    HITOOLBOX_FILE=`find "${HOME}"/Library/Preferences/ByHost -name "com.apple.HIToolbox*" | head -n1`
    if [ -z "${HITOOLBOX_FILE}" ]
    then
      HITOOLBOX_FILE="${SYSBUILDER_FOLDER}/common/en.com.apple.HIToolbox.plist"
    fi
  else
    GLOBAL_PREFERENCES_FILE="${SYSBUILDER_FOLDER}/common/${LANGUAGE_CODE}.GlobalPreferences.plist"
    HITOOLBOX_FILE="${SYSBUILDER_FOLDER}/common/${LANGUAGE_CODE}.com.apple.HIToolbox.plist"
  fi   

  ditto "${GLOBAL_PREFERENCES_FILE}" "${TMP_MOUNT_PATH}/Library/Preferences/.GlobalPreferences.plist" 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/Library/Preferences/.GlobalPreferences.plist 2>&1

  ditto "${HITOOLBOX_FILE}" "${TMP_MOUNT_PATH}/Library/Preferences/com.apple.HIToolbox.plist" 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.HIToolbox.plist 2>&1

  ditto "${GLOBAL_PREFERENCES_FILE}" "${TMP_MOUNT_PATH}/var/root/Library/Preferences/.GlobalPreferences.plist" 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/var/root/Library/Preferences/.GlobalPreferences.plist 2>&1

  ditto "${HITOOLBOX_FILE}" "${TMP_MOUNT_PATH}/var/root/Library/Preferences/com.apple.HIToolbox.plist" 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/var/root/Library/Preferences/com.apple.HIToolbox.plist 2>&1

  if [ -n "${ARD_PASSWORD}" ]
  then
    ditto --rsrc "${SYSBUILDER_FOLDER}"/${SYS_VERS}/com.apple.RemoteManagement.plist "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.RemoteManagement.plist 2>&1
	echo "${ARD_PASSWORD}" | perl -wne 'BEGIN { @k = unpack "C*", pack "H*", "1734516E8BA8C5E2FF1C39567390ADCA"}; chomp; s/^(.{8}).*/$1/; @p = unpack "C*", $_; foreach (@k) { printf "%02X", $_ ^ (shift @p || 0) }; print "\n"' > "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.VNCSettings.txt
    chown root:wheel "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.VNCSettings.txt 2>&1
    chmod 400 "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.VNCSettings.txt 2>&1

	if [ -n "${ARD_LOGIN}" ]
	then
	  ARD_USER_SHORTNAME="${ARD_LOGIN}"
	else
	  ARD_USER_SHORTNAME="arduser"
    fi

    ditto "${SYSBUILDER_FOLDER}/${SYS_VERS}/arduser.plist" "${TMP_MOUNT_PATH}/var/db/dslocal/nodes/Default/users/${ARD_USER_SHORTNAME}.plist" 2>&1
	"${SYSBUILDER_FOLDER}/${SYS_VERS}"/setShadowHashData "${TMP_MOUNT_PATH}/var/db/dslocal/nodes/Default/users/${ARD_USER_SHORTNAME}.plist" "${ARD_PASSWORD}"
	if [ "${ARD_LOGIN}" != "arduser" ]
	then
      defaults write "${TMP_MOUNT_PATH}/var/db/dslocal/nodes/Default/users/${ARD_USER_SHORTNAME}" realname -array "${ARD_USER_SHORTNAME}"
      defaults write "${TMP_MOUNT_PATH}/var/db/dslocal/nodes/Default/users/${ARD_USER_SHORTNAME}" name -array "${ARD_USER_SHORTNAME}"
    fi
    chmod 600 "${TMP_MOUNT_PATH}/var/db/dslocal/nodes/Default/users/${ARD_USER_SHORTNAME}.plist" 2>&1
  fi

  if [ -n "${NTP_SERVER}" ]
  then
    echo "${NTP_SERVER}" > "${TMP_MOUNT_PATH}"/Library/Preferences/ntpserver.txt
    chmod 644 "${TMP_MOUNT_PATH}"/Library/Preferences/ntpserver.txt 2>&1
    chown root:wheel "${TMP_MOUNT_PATH}"/Library/Preferences/ntpserver.txt 2>&1
  fi

  mkdir "${TMP_MOUNT_PATH}"/Library/Caches 2>&1
  chmod 1777 "${TMP_MOUNT_PATH}"/Library/Caches 2>&1
  chown -R root:admin "${TMP_MOUNT_PATH}"/Library/Caches 2>&1

  # improve tcp performance (risky)
  if [ -n "${ENABLE_CUSTOM_TCP_STACK_SETTINGS}" ]
  then
    enable_custom_tcp_stack_settings
  fi

  chmod -R 644 "${TMP_MOUNT_PATH}"/Library/Preferences/* 2>&1
  chmod 755 "${TMP_MOUNT_PATH}"/Library/Preferences/DirectoryService 2>&1
  chmod 755 "${TMP_MOUNT_PATH}"/Library/Preferences/SystemConfiguration 2>&1
  chown -R root:wheel "${TMP_MOUNT_PATH}"/Library/Preferences/* 2>&1

  touch "${TMP_MOUNT_PATH}"/System/Library/CoreServices/ServerVersion.plist 2>&1
  chmod 444 "${TMP_MOUNT_PATH}"/System/Library/CoreServices/ServerVersion.plist 2>&1
  chown root:wheel "${TMP_MOUNT_PATH}"/System/Library/CoreServices/ServerVersion.plist 2>&1

  if [ -n "${CUSTOM_RUNTIME_BACKGROUND}" ] && [ -f "${CUSTOM_RUNTIME_BACKGROUND}" ]
  then
    ditto --rsrc "${CUSTOM_RUNTIME_BACKGROUND}" "${TMP_MOUNT_PATH}"/System/Library/CoreServices/DefaultDesktop.jpg
  else
    ditto --rsrc "${SYSBUILDER_FOLDER}"/common/DefaultDesktop.jpg "${TMP_MOUNT_PATH}"/System/Library/CoreServices/DefaultDesktop.jpg
  fi

  if [ -e "/Applications/Utilities/DeployStudio Admin.app" ]
  then
    ditto --rsrc "/Applications/Utilities/DeployStudio Admin.app" "${TMP_MOUNT_PATH}/Applications/Utilities/DeployStudio Admin.app" 2>&1
  elif [ -e "${SYSBUILDER_FOLDER}/../../../../Applications/Utilities/DeployStudio Admin.app" ]
  then
    ditto --rsrc "${SYSBUILDER_FOLDER}/../../../../Applications/Utilities/DeployStudio Admin.app" "${TMP_MOUNT_PATH}/Applications/Utilities/DeployStudio Admin.app" 2>&1
  fi
  chown -R root:admin "${TMP_MOUNT_PATH}/Applications/Utilities/DeployStudio Admin.app" 2>&1

  # disable spotlight indexing again (just in case)
  mdutil -i off "${TMP_MOUNT_PATH}"
  mdutil -E "${TMP_MOUNT_PATH}"
  defaults write "${TMP_MOUNT_PATH}"/.Spotlight-V100/_IndexPolicy Policy -int 3

  rm -rf "${TMP_MOUNT_PATH}"/System/Library/Caches/com.apple.bootstamps
  rm -rf "${TMP_MOUNT_PATH}"/System/Library/Caches/*
  rm -r  "${TMP_MOUNT_PATH}"/System/Library/Extensions.mkext
  rm -r  "${TMP_MOUNT_PATH}"/usr/standalone/bootcaches.plist
  rm -f  "${TMP_MOUNT_PATH}"/var/db/BootCache*

  if [ -e "${TMP_MOUNT_PATH}"/Volumes ]
  then
    rm -rf "${TMP_MOUNT_PATH}"/Volumes/* 2>&1
  fi
}

fill_volume_1060() {
  # disable spotlight indexing
  mdutil -i off "${TMP_MOUNT_PATH}"
  mdutil -E "${TMP_MOUNT_PATH}"
  defaults write "${TMP_MOUNT_PATH}"/.Spotlight-V100/_IndexPolicy Policy -int 3

  # start adding content to the volume
  ditto -bom "${SYSBUILDER_FOLDER}/${SYS_VERS}/${ARCH}.bom" / "${TMP_MOUNT_PATH}" 2>&1

  rm -rf "${TMP_MOUNT_PATH}"/System/Library/Extensions/IOSerialFamily.kext/Contents/PlugIns/*

  ETC_CONF="pam.d smb.conf smb.conf.template"
  for A_ETC_CONF in ${ETC_CONF}
  do
    ditto_file_at_path "${A_ETC_CONF}" /etc
  done
  ditto /var/db/smb.conf "${TMP_MOUNT_PATH}/var/db/smb.conf" 2>&1
  
  USR_LIB="libapr-1.0.3.8.dylib libaprutil-1.0.3.9.dylib libtcl.dylib libtk.dylib libXplugin.1.dylib mecab pam pkgconfig samba sasl2 \
           libwx_macud-2.8.0.dylib libwx_macud_stc-2.8.0.dylib"
  for A_LIB in ${USR_LIB}
  do
    ditto_file_at_path "${A_LIB}" /usr/lib
  done

  USR_BIN="afconvert afinfo afplay atos auval auvaltool basename cd chflags chgrp curl cut diff dirname dscl du egrep \
           expect false fgrep fs_usage gunzip gzip less lsbom mkbom more nmblookup ntlm_auth open printf rsync say sort srm \
		   smbcacls smbclient smbcontrol smbcquotas smbget smbpasswd smbspool smbstatus smbtree smbutil \
		   tail tr uuidgen vi vim xxd bsdtar syslog"
  for A_BIN in ${USR_BIN}
  do
    ditto_file_at_path "${A_BIN}" /usr/bin
  done

  USR_SBIN="gssd installer iostat ipconfig nmbd ntpdate smbd systemsetup vsdbutil winbindd"
  for A_SBIN in ${USR_SBIN}
  do
    ditto_file_at_path "${A_SBIN}" /usr/sbin
  done

  USR_SHARE="sandbox terminfo zoneinfo"
  for A_SHARE in ${USR_SHARE}
  do
    ditto_file_at_path "${A_SHARE}" /usr/share
  done

  USR_LIBEXEC="samba mtversionlog third_party_32b_kext_logger.rb"
  for A_LIBEXEC in ${USR_LIBEXEC}
  do
    ditto_file_at_path "${A_LIBEXEC}" /usr/libexec
  done

  ditto_file_at_path "Disk Utility.app" /Applications/Utilities
  ditto_file_at_path "Network Utility.app" /Applications/Utilities
  ditto_file_at_path "RAID Utility.app" /Applications/Utilities
  ditto_file_at_path "System Profiler.app" /Applications/Utilities
  ditto_file_at_path "Terminal.app" /Applications/Utilities

  ditto --rsrc "${SYSBUILDER_FOLDER}"/common/StartupDisk.app "${TMP_MOUNT_PATH}"/Applications/Utilities/StartupDisk.app
  if [ -z ${DISABLE_AD_VIEWER} ]
  then
    ditto --rsrc "${SYSBUILDER_FOLDER}"/common/AdViewer.app "${TMP_MOUNT_PATH}"/Applications/AdViewer.app
  fi

  LIB_MISC="ColorSync Perl"
  for A_LIB in ${LIB_MISC}
  do
    ditto_file_at_path "${A_LIB}" /Library
  done

  ditto_file_at_path NetFSPlugins /Library/Filesystems

  SYS_LIB="DirectoryServices Displays Filesystems KerberosPlugins LoginPlugins Perl Sandbox"
  for A_SYS_LIB in ${SYS_LIB}
  do
    ditto_file_at_path "${A_SYS_LIB}" /System/Library
  done

  SYS_LIB_COMP="AudioCodecs CoreAudio"
  for A_SYS_LIB_COMP in ${SYS_LIB_COMP}
  do
    ditto_file_at_path "${A_SYS_LIB_COMP}.component" /System/Library/Components
  done

  SYS_LIB_CORE="CoreTypes.bundle KernelEventAgent.bundle RemoteManagement SecurityAgentPlugins"
  for A_SYS_LIB_CORE in ${SYS_LIB_CORE}
  do
    ditto_file_at_path "${A_SYS_LIB_CORE}" /System/Library/CoreServices
  done

  ditto_file_at_path "TextInput.menu" "/System/Library/CoreServices/Menu Extras"
  ditto_file_at_path "Setup Assistant.app" /System/Library/CoreServices
  ditto_file_at_path Voices /System/Library/Speech
  ditto_file_at_path Sounds /System/Library

  SYS_LIB_EXT="AppleBMC AppleBluetoothMultitouch AppleHIDKeyboard AppleIntelCPUPowerManagementClient AppleMultitouchDriver AppleProfileFamily \
			   AppleUSBEthernetHost AppleIntelHDGraphics AppleIntelHDGraphicsFB AppleIntelSNBGraphicsFB AppleIntelSNBVA \
               ATI4500Controller ATI4600Controller ATI5000Controller ATI6000Controller ATIRadeonX3000 BJUSBLoad IOPlatformPluginFamily \
			   AppleBacklightExpert IO80211Family AppleHDA System PromiseSTEX \
               AppleThunderboltEDMService AppleThunderboltDPAdapters AppleThunderboltNHI AppleThunderboltPCIAdapters AppleThunderboltUTDM IOThunderboltFamily"
  for A_SYS_LIB_EXT in ${SYS_LIB_EXT}
  do
    ditto_file_at_path "${A_SYS_LIB_EXT}.kext" /System/Library/Extensions
  done

  SYS_LIB_EXT_BDL="AppleIntelHDGraphicsGLDriver AppleIntelHDGraphicsVADriver ATIRadeonX3000VADriver ATIRadeonX3000GLDriver GeForceGLDriver"
  for A_SYS_LIB_EXT_BDL in ${SYS_LIB_EXT_BDL}
  do
    ditto_file_at_path "${A_SYS_LIB_EXT_BDL}.bundle" /System/Library/Extensions
  done

  SYS_LIB_EXT_PLUG="AppleIntelHDGraphicsGA ATIRadeonX3000GA"
  for A_SYS_LIB_EXT_PLUG in ${SYS_LIB_EXT_PLUG}
  do
    ditto_file_at_path "${A_SYS_LIB_EXT_PLUG}.plugin" /System/Library/Extensions
  done

  SYS_LIB_FRK="AppKit ApplicationServices CoreFoundation CoreVideo CoreServices IOBluetooth JavaScriptCore Kernel LDAP OpenCL OpenDirectory \
               OpenGL PreferencePanes QTKit Quartz QuickTime Security ServiceManagement WebKit Carbon \
               AddressBook CoreAudioKit CoreMIDI FWAUserLib ImageCaptureCore Message OpenAL PubSub QuickLook Ruby Tcl Tk \
               AGL CalendarStore RubyCocoa ScriptingBridge ServerNotification AppleConnect nt"
  for A_SYS_LIB_FRK in ${SYS_LIB_FRK}
  do
    ditto_file_at_path "${A_SYS_LIB_FRK}.framework" /System/Library/Frameworks
  done

  SYS_LIB_PREF_PANES="StartupDisk"
  for A_SYS_LIB_PREF_PANE in ${SYS_LIB_PREF_PANES}
  do
    ditto_file_at_path "${A_SYS_LIB_PREF_PANE}.prefPane" /System/Library/PreferencePanes
  done

  SYS_LIB_PRIV_FRK="AppleVA BezelServices CommerceKit CoreMedia CoreMediaIOServices DSObjCWrappers DisplayServices MonitorPanel HelpData \
                    MachineSettings MediaToolbox MobileDevice PlatformHardwareManagement ScreenSharing Shortcut VideoToolbox \
                    AVFoundationCF AppleGVA CoreKE Install \
                    ByteRangeLocking ClockMenuExtraPreferences CoreAUC CoreChineseEngine CorePDF DataDetectorsCore DeviceLink \
                    DotMacLegacy FWAVC GraphKit Heimdal International MDSChannel MPWXmlCore MeshKit PasswordServer \
                    PrintingPrivate ProxyHelper ServerFoundation ServerKit SetupAssistant SetupAssistantSupport \
                    SoftwareUpdate SpeechObjects SpotlightIndex SyncServicesUI SystemUIPlugin \
                    DAVKit DotMacSyncManager ExchangeWebServices FileSync ISSupport IntlPreferences OpenDirectoryConfig \
                    OpenDirectoryConfigUI iCalendar AOSNotification WhitePages XMPP ApplePushService"
  for A_SYS_LIB_PRIV_FRK in ${SYS_LIB_PRIV_FRK}
  do
    ditto_file_at_path "${A_SYS_LIB_PRIV_FRK}.framework" /System/Library/PrivateFrameworks
  done

  SYS_LIB_FONTS="Geneva Helvetica Monaco"
  for SYS_LIB_FONT in ${SYS_LIB_FONTS}
  do
    ditto_file_at_path "${SYS_LIB_FONT}.dfont" /System/Library/Fonts
  done

  rm -rf "${TMP_MOUNT_PATH}"/System/Library/SystemProfiler/*.spreporter
  SYS_LIB_PROFILERS="SPAirPortReporter SPAudioReporter SPBluetoothReporter SPDiagnosticsReporter SPDisplaysReporter SPEthernetReporter SPFibreChannelReporter SPFireWireReporter SPHardwareRAIDReporter \
                     SPMemoryReporter SPNetworkReporter SPOSReporter SPPCIReporter SPParallelATAReporter SPParallelSCSIReporter SPPlatformReporter SPPowerReporter \
				     SPSASReporter SPSerialATAReporter SPUSBReporter SPWWANReporter SPThunderboltReporter"
  for A_SYS_LIB_PROFILER in ${SYS_LIB_PROFILERS}
  do
    ditto_file_at_path "${A_SYS_LIB_PROFILER}.spreporter" /System/Library/SystemProfiler
  done

  if [ -e "${TMP_MOUNT_PATH}"/System/Library/Tcl ] 
  then
    rm -rf "${TMP_MOUNT_PATH}"/System/Library/Tcl
  fi
  ditto --rsrc /System/Library/Tcl "${TMP_MOUNT_PATH}/System/Library/Tcl" 

  if [ -n "${ENABLE_PYTHON}" ]
  then
    ditto_file_at_path Python /Library
    ditto_file_at_path Python.framework /System/Library/Frameworks
	cp -p -R /usr/lib/python* "${TMP_MOUNT_PATH}"/usr/lib/ 2>&1
	ditto_file_at_path python /usr/bin
  fi
  
  if [ -n "${ENABLE_RUBY}" ]
  then
    ditto_file_at_path Ruby /Library
    ditto_file_at_path ruby /usr/lib
    ditto_file_at_path ruby /usr/bin
  fi

  # Display mirroring support
  ditto --rsrc  "${SYSBUILDER_FOLDER}"/common/enableDisplayMirroring "${TMP_MOUNT_PATH}"/usr/bin/enableDisplayMirroring 2>&1
  chmod 755 "${TMP_MOUNT_PATH}"/usr/bin/enableDisplayMirroring 2>&1
  chown root:wheel "${TMP_MOUNT_PATH}"/usr/bin/enableDisplayMirroring 2>&1

  rm "${TMP_MOUNT_PATH}"/mach
  ln -s /mach_kernel "${TMP_MOUNT_PATH}"/mach
  
  cp "${SYSBUILDER_FOLDER}/common/com.deploystudio.server.plist" "${TMP_MOUNT_PATH}/Library/Preferences/com.deploystudio.server.plist"
  if [ -n "${SERVER_URL}" ]
  then
    defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server server -dict-add url "${SERVER_URL}"
    if [ -n "${SERVER_URL2}" ] && [ "${SERVER_URL2}" != "${SERVER_URL}" ]
    then
      defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server server -dict-add url2 "${SERVER_URL2}"
    fi
  fi
  if [ -n "${SERVER_LOGIN}" ]
  then
    defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server server -dict-add login "${SERVER_LOGIN}"
    if [ -n "${SERVER_PASSWORD}" ]
    then
      defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server server -dict-add password "${SERVER_PASSWORD}"
    fi
  fi
  if [ -n "${SERVER_DISPLAY_LOGS}" ]
  then
    defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server runtime -dict-add displaylogs "YES"
  fi
  if [ -n "${TIMEOUT}" ]
  then
    defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server runtime -dict-add quitAfterCompletion "YES"
    defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server runtime -dict-add timeoutInSeconds "${TIMEOUT}"
  fi
  if [ -n "${CUSTOM_RUNTIME_TITLE}" ]
  then
    defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server runtime -dict-add customtitle "${CUSTOM_RUNTIME_TITLE}"
  fi
  chown root:admin "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server.plist 2>&1

  if [ ! -e "${TMP_MOUNT_PATH}/System/Installation" ]
  then
    mkdir "${TMP_MOUNT_PATH}/System/Installation" 2>&1
  fi

  if [ ! -e "${TMP_MOUNT_PATH}/Library/Logs" ]
  then
    mkdir "${TMP_MOUNT_PATH}/Library/Logs" 2>&1
  fi

  if [ ! -e "${TMP_MOUNT_PATH}/var/db/launchd.db" ]
  then
    mkdir "${TMP_MOUNT_PATH}/var/db/launchd.db"
  else
    rm -rf "${TMP_MOUNT_PATH}/var/db/launchd.db"/*
  fi
  mkdir "${TMP_MOUNT_PATH}/var/db/launchd.db/com.apple.launchd"
  chown -R root:wheel "${TMP_MOUNT_PATH}/var/db/launchd.db" 2>&1
  chmod -R 755 "${TMP_MOUNT_PATH}/var/db/launchd.db" 2>&1

  if [ -e "${TMP_MOUNT_PATH}/var/db/mds" ]
  then
    rm -rf "${TMP_MOUNT_PATH}/var/db/mds"
  fi

  if [ -e "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration" ]
  then
    rm -rf "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration" 2>&1
  fi
  ditto --rsrc "${SYSBUILDER_FOLDER}/${SYS_VERS}/SystemConfiguration" "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration" 2>&1

  if [ -e "${TMP_MOUNT_PATH}/System/Library/LaunchDaemons" ]
  then
    rm -rf "${TMP_MOUNT_PATH}/System/Library/LaunchDaemons" 2>&1
  fi
  ditto --rsrc "${SYSBUILDER_FOLDER}/${SYS_VERS}/LaunchDaemons" "${TMP_MOUNT_PATH}/System/Library/LaunchDaemons" 2>&1
  chown -R root:wheel "${TMP_MOUNT_PATH}/System/Library/LaunchDaemons" 2>&1
  chmod 755 "${TMP_MOUNT_PATH}"/System/Library/LaunchDaemons 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/System/Library/LaunchDaemons/* 2>&1
  
  if [ -e "${TMP_MOUNT_PATH}/System/Library/LaunchAgents" ]
  then
    rm -rf "${TMP_MOUNT_PATH}/System/Library/LaunchAgents" 2>&1
  fi
  ditto --rsrc "${SYSBUILDER_FOLDER}/${SYS_VERS}/LaunchAgents" "${TMP_MOUNT_PATH}/System/Library/LaunchAgents" 2>&1
  chown -R root:wheel "${TMP_MOUNT_PATH}"/System/Library/LaunchAgents 2>&1
  chmod 755 "${TMP_MOUNT_PATH}"/System/Library/LaunchAgents 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/System/Library/LaunchAgents/* 2>&1

  rm "${TMP_MOUNT_PATH}"/tmp

  ln -s var/tmp "${TMP_MOUNT_PATH}"/tmp

  ditto /var/run/resolv.conf "${TMP_MOUNT_PATH}/var/run/resolv.conf" 2>&1
  ln -s /var/run/resolv.conf "${TMP_MOUNT_PATH}/etc/resolv.conf" 2>&1

  cp -R "${SYSBUILDER_FOLDER}/${SYS_VERS}"/etc/* "${TMP_MOUNT_PATH}/etc/" 2>&1
  sed s/__DISPLAY_SLEEP__/${DISPLAY_SLEEP}/g "${SYSBUILDER_FOLDER}/${SYS_VERS}"/etc/rc.install > "${TMP_MOUNT_PATH}"/etc/rc.install 2>&1
  chmod 555 "${TMP_MOUNT_PATH}"/etc/rc.install 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/etc/hostconfig 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/etc/rc.common 2>&1
  chmod 755 "${TMP_MOUNT_PATH}"/etc/rc.cdrom 2>&1

  rm -rf "${TMP_MOUNT_PATH}/var/log/"* 2>&1

  if [ -e "/Library/Application Support/DeployStudio" ]
  then
    ditto --rsrc "/Library/Application Support/DeployStudio" "${TMP_MOUNT_PATH}/Library/Application Support/DeployStudio" 2>&1
    chown -R root:admin "${TMP_MOUNT_PATH}/Library/Application Support/DeployStudio" 2>&1
  fi

  if [ -e "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration/preferences.plist" ]
  then
    rm "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration/preferences.plist" 2>&1
  fi

  if [ "${LANGUAGE_CODE}" == "auto" ]
  then
    GLOBAL_PREFERENCES_FILE=`find "${HOME}"/Library/Preferences/ByHost -name ".GlobalPreferences*" | head -n1`
    if [ -z "${GLOBAL_PREFERENCES_FILE}" ]
    then
      GLOBAL_PREFERENCES_FILE="${SYSBUILDER_FOLDER}/common/en.GlobalPreferences.plist"
    fi
    HITOOLBOX_FILE=`find "${HOME}"/Library/Preferences/ByHost -name "com.apple.HIToolbox*" | head -n1`
    if [ -z "${HITOOLBOX_FILE}" ]
    then
      HITOOLBOX_FILE="${SYSBUILDER_FOLDER}/common/en.com.apple.HIToolbox.plist"
    fi
  else
    GLOBAL_PREFERENCES_FILE="${SYSBUILDER_FOLDER}/common/${LANGUAGE_CODE}.GlobalPreferences.plist"
    HITOOLBOX_FILE="${SYSBUILDER_FOLDER}/common/${LANGUAGE_CODE}.com.apple.HIToolbox.plist"
  fi   
  
  ditto "${GLOBAL_PREFERENCES_FILE}" "${TMP_MOUNT_PATH}/Library/Preferences/.GlobalPreferences.plist" 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/Library/Preferences/.GlobalPreferences.plist 2>&1

  ditto "${HITOOLBOX_FILE}" "${TMP_MOUNT_PATH}/Library/Preferences/com.apple.HIToolbox.plist" 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.HIToolbox.plist 2>&1

  ditto "${GLOBAL_PREFERENCES_FILE}" "${TMP_MOUNT_PATH}/var/root/Library/Preferences/.GlobalPreferences.plist" 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/var/root/Library/Preferences/.GlobalPreferences.plist 2>&1

  ditto "${HITOOLBOX_FILE}" "${TMP_MOUNT_PATH}/var/root/Library/Preferences/com.apple.HIToolbox.plist" 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/var/root/Library/Preferences/com.apple.HIToolbox.plist 2>&1
  
  if [ -n "${ARD_PASSWORD}" ]
  then
    ditto --rsrc "${SYSBUILDER_FOLDER}"/${SYS_VERS}/com.apple.RemoteManagement.plist "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.RemoteManagement.plist 2>&1

    ditto --rsrc "${SYSBUILDER_FOLDER}/common/OSXvnc-server" "${TMP_MOUNT_PATH}/usr/bin/OSXvnc-server" 2>&1
    chmod 755 "${TMP_MOUNT_PATH}"/usr/bin/OSXvnc-server 2>&1
    chown root:wheel "${TMP_MOUNT_PATH}"/usr/bin/OSXvnc-server 2>&1

	echo enabled > "${TMP_MOUNT_PATH}"/etc/ScreenSharing.launchd
    "${SYSBUILDER_FOLDER}"/common/storepasswd "${ARD_PASSWORD}" "${TMP_MOUNT_PATH}/Library/Preferences/com.osxvnc.txt" 2>&1
    chmod 644 "${TMP_MOUNT_PATH}"/Library/Preferences/com.osxvnc.txt 2>&1
    chown root:wheel "${TMP_MOUNT_PATH}"/Library/Preferences/com.osxvnc.txt 2>&1
	echo "${ARD_PASSWORD}" | perl -wne 'BEGIN { @k = unpack "C*", pack "H*", "1734516E8BA8C5E2FF1C39567390ADCA"}; chomp; s/^(.{8}).*/$1/; @p = unpack "C*", $_; foreach (@k) { printf "%02X", $_ ^ (shift @p || 0) }; print "\n"' > "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.VNCSettings.txt
    chmod 400 "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.VNCSettings.txt 2>&1
    chown root:wheel "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.VNCSettings.txt 2>&1
  fi

  if [ -n "${NTP_SERVER}" ]
  then
    echo "${NTP_SERVER}" > "${TMP_MOUNT_PATH}"/Library/Preferences/ntpserver.txt
    chmod 644 "${TMP_MOUNT_PATH}"/Library/Preferences/ntpserver.txt 2>&1
    chown root:wheel "${TMP_MOUNT_PATH}"/Library/Preferences/ntpserver.txt 2>&1
  fi
  
  mkdir "${TMP_MOUNT_PATH}"/Library/Caches 2>&1
  chmod 1777 "${TMP_MOUNT_PATH}"/Library/Caches 2>&1
  chown -R root:admin "${TMP_MOUNT_PATH}"/Library/Caches 2>&1

  # improve tcp performance (risky)
  if [ -n "${ENABLE_CUSTOM_TCP_STACK_SETTINGS}" ]
  then
    enable_custom_tcp_stack_settings
  fi
  
  chmod -R 644 "${TMP_MOUNT_PATH}"/Library/Preferences/* 2>&1
  chmod 755 "${TMP_MOUNT_PATH}"/Library/Preferences/DirectoryService 2>&1
  chmod 755 "${TMP_MOUNT_PATH}"/Library/Preferences/SystemConfiguration 2>&1
  chown -R root:wheel "${TMP_MOUNT_PATH}"/Library/Preferences/* 2>&1

  touch "${TMP_MOUNT_PATH}"/System/Library/CoreServices/ServerVersion.plist 2>&1
  chmod 444 "${TMP_MOUNT_PATH}"/System/Library/CoreServices/ServerVersion.plist 2>&1
  chown root:wheel "${TMP_MOUNT_PATH}"/System/Library/CoreServices/ServerVersion.plist 2>&1

  if [ -n "${CUSTOM_RUNTIME_BACKGROUND}" ] && [ -f "${CUSTOM_RUNTIME_BACKGROUND}" ]
  then
    ditto --rsrc "${CUSTOM_RUNTIME_BACKGROUND}" "${TMP_MOUNT_PATH}"/System/Library/CoreServices/DefaultDesktop.jpg
  else
    ditto --rsrc "${SYSBUILDER_FOLDER}"/common/DefaultDesktop.jpg "${TMP_MOUNT_PATH}"/System/Library/CoreServices/DefaultDesktop.jpg
  fi
  
  if [ -e "/Applications/Utilities/DeployStudio Admin.app" ]
  then
    ditto --rsrc "/Applications/Utilities/DeployStudio Admin.app" "${TMP_MOUNT_PATH}/Applications/Utilities/DeployStudio Admin.app" 2>&1
  elif [ -e "${SYSBUILDER_FOLDER}/../../../../Applications/Utilities/DeployStudio Admin.app" ]
  then
    ditto --rsrc "${SYSBUILDER_FOLDER}/../../../../Applications/Utilities/DeployStudio Admin.app" "${TMP_MOUNT_PATH}/Applications/Utilities/DeployStudio Admin.app" 2>&1
  fi
  chown -R root:admin "${TMP_MOUNT_PATH}/Applications/Utilities/DeployStudio Admin.app" 2>&1

  # disable spotlight indexing again (just in case)
  mdutil -i off "${TMP_MOUNT_PATH}"
  mdutil -E "${TMP_MOUNT_PATH}"
  defaults write "${TMP_MOUNT_PATH}"/.Spotlight-V100/_IndexPolicy Policy -int 3

  rm -rf "${TMP_MOUNT_PATH}"/System/Library/Caches/com.apple.bootstamps
  rm -rf "${TMP_MOUNT_PATH}"/System/Library/Caches/*
  rm -r  "${TMP_MOUNT_PATH}"/System/Library/Extensions.mkext
  rm -r  "${TMP_MOUNT_PATH}"/usr/standalone/bootcaches.plist
  rm -f  "${TMP_MOUNT_PATH}"/var/db/BootCache*

  if [ -e "${TMP_MOUNT_PATH}"/Volumes ]
  then
    rm -rf "${TMP_MOUNT_PATH}"/Volumes/* 2>&1
  fi
}

fill_volume() {
  # disable spotlight indexing
  mdutil -i off "${TMP_MOUNT_PATH}"
  mdutil -E "${TMP_MOUNT_PATH}"
  defaults write "${TMP_MOUNT_PATH}"/.Spotlight-V100/_IndexPolicy Policy -int 3

  # start adding content to the volume
  ditto -bom "${SYSBUILDER_FOLDER}/${SYS_VERS}/${ARCH}.bom" / "${TMP_MOUNT_PATH}" 2>&1

  USR_LIB="samba sasl2 pam libbz2.1.0.5.dylib"
  for A_LIB in ${USR_LIB}
  do
    ditto_file_at_path "${A_LIB}" /usr/lib
  done

  ditto_file_at_path PlistBuddy /usr/libexec

  USR_BIN="curl cut du dscl more chflags chgrp egrep fgrep fs_usage rsync say srm uuidgen syslog"
  for A_BIN in ${USR_BIN}
  do
    ditto_file_at_path "${A_BIN}" /usr/bin
  done

  USR_SBIN="iostat ipconfig ntpdate systemsetup"
  for A_SBIN in ${USR_SBIN}
  do
    ditto_file_at_path "${A_SBIN}" /usr/sbin
  done

  ditto_file_at_path "Disk Utility.app" /Applications/Utilities
  ditto_file_at_path "RAID Utility.app" /Applications/Utilities
  ditto_file_at_path "Terminal.app" /Applications/Utilities

  ditto --rsrc "${SYSBUILDER_FOLDER}"/common/StartupDisk.app "${TMP_MOUNT_PATH}"/Applications/Utilities/StartupDisk.app
  if [ -z ${DISABLE_AD_VIEWER} ]
  then
    ditto --rsrc "${SYSBUILDER_FOLDER}"/common/AdViewer.app "${TMP_MOUNT_PATH}"/Applications/AdViewer.app
  fi

  if [ -n "${ENABLE_PYTHON}" ]
  then
    ditto_file_at_path Python /Library
    ditto_file_at_path Python.framework /System/Library/Frameworks
	cp -p -R /usr/lib/python* "${TMP_MOUNT_PATH}"/usr/lib/ 2>&1
	ditto_file_at_path python /usr/bin
  fi
  
  if [ -n "${ENABLE_RUBY}" ]
  then
    ditto_file_at_path Ruby /Library
    ditto_file_at_path Ruby.framework /System/Library/Frameworks
    ditto_file_at_path ruby /usr/lib
    ditto_file_at_path ruby /usr/bin
  fi

  ditto_file_at_path Perl   /Library
  ditto_file_at_path Perl   /System/Library

  ditto_file_at_path ColorSync   /Library

  ditto_file_at_path CoreTypes.bundle /System/Library/CoreServices
 
  SYS_LIB_FRK="AppKit QuickTime JavaScriptCore IOBluetooth WebKit CoreVideo InputMethodKit LatentSemanticMapping SyncServices AppleConnect"
  for A_SYS_LIB_FRK in ${SYS_LIB_FRK}
  do
    ditto_file_at_path "${A_SYS_LIB_FRK}.framework" /System/Library/Frameworks
  done

  ditto_file_at_path Filesystems /System/Library
  ditto_file_at_path Voices /System/Library/Speech

  SYS_LIB_PRIV_FRK="CommonCandidateWindow FamilyControls DSObjCWrappers DiskImages Install MultitouchSupport SystemMigration Helium MobileDevice"
  for A_SYS_LIB_PRIV_FRK in ${SYS_LIB_PRIV_FRK}
  do
    ditto_file_at_path "${A_SYS_LIB_PRIV_FRK}.framework" /System/Library/PrivateFrameworks
  done

  SYS_LIB_EXT="AppleAirPort AppleI2SModemFamily AppleIRController AppleHDA ApplePlatformEnabler AppleStorageDrivers AppleUSBMultitouch \
               AppleUSBTopCase IO80211Family IOHIDFamily IONetworkingFamily IOSerialFamily IOBluetoothFamily IOBluetoothHIDDriver \
               ATIRNDRV AppleGraphicsControl AppleGraphicsPowerManagement AppleMikeyHIDDriver AppleSMBusController \
               AppleSMBusPCI AppleUpstreamUserClient BJUSBLoad NVSMU nvenet"
  for A_SYS_LIB_EXT in ${SYS_LIB_EXT}
  do
    ditto_file_at_path "${A_SYS_LIB_EXT}.kext" /System/Library/Extensions
  done

  ditto_file_at_path DirectoryServices /System/Library
  ditto_file_at_path Displays /System/Library
  ditto_file_at_path DisplayServices.loginPlugin /System/Library/LoginPlugins
  ditto_file_at_path Fonts /System/Library
  ditto_file_at_path KerberosPlugins /System/Library
  ditto_file_at_path ScreenReader /System/Library
  ditto_file_at_path SCMonitor.plugin /System/Library/UserEventPlugins
  ditto_file_at_path SPUSBReporter.spreporter /System/Library/SystemProfiler
  ditto_file_at_path SystemConfiguration /System/Library/
  ditto_file_at_path SystemProfiler /System/Library/
 
  ditto_file_at_path zoneinfo /usr/share
  ditto_file_at_path terminfo /usr/share

  rm "${TMP_MOUNT_PATH}"/mach
  ln -s /mach_kernel "${TMP_MOUNT_PATH}"/mach

  ditto_file_at_path StartupDisk.prefPane /System/Library/PreferencePanes
  chown -R root:wheel "${TMP_MOUNT_PATH}/System/Library/PreferencePanes/StartupDisk.prefPane" 2>&1

  if [ ! -e "${TMP_MOUNT_PATH}/usr/bin/atos" ]
  then
    if [ -e /usr/bin/atos ]
    then
      ditto_file_at_path atos /usr/bin 2>&1
    else
      ditto --rsrc "${SYSBUILDER_FOLDER}/common/atos" "${TMP_MOUNT_PATH}/usr/bin/atos" 2>&1
      chown root:procview "${TMP_MOUNT_PATH}/usr/bin/atos" 2>&1
      chmod 2555 "${TMP_MOUNT_PATH}/usr/bin/atos" 2>&1
    fi
  fi

  ditto_file_at_path standalone /usr 2>&1
  
  cp "${SYSBUILDER_FOLDER}/common/com.deploystudio.server.plist" "${TMP_MOUNT_PATH}/Library/Preferences/com.deploystudio.server.plist"
  if [ -n "${SERVER_URL}" ]
  then
    defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server server -dict-add url "${SERVER_URL}"
    if [ -n "${SERVER_URL2}" ] && [ "${SERVER_URL2}" != "${SERVER_URL}" ]
    then
      defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server server -dict-add url2 "${SERVER_URL2}"
    fi
  fi
  if [ -n "${SERVER_LOGIN}" ]
  then
    defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server server -dict-add login "${SERVER_LOGIN}"
    if [ -n "${SERVER_PASSWORD}" ]
    then
      defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server server -dict-add password "${SERVER_PASSWORD}"
    fi
  fi
  if [ -n "${SERVER_DISPLAY_LOGS}" ]
  then
    defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server runtime -dict-add displaylogs "YES"
  fi
  if [ -n "${TIMEOUT}" ]
  then
    defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server runtime -dict-add quitAfterCompletion "YES"
    defaults write "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server runtime -dict-add timeoutInSeconds "${TIMEOUT}"
  fi
  chown root:admin "${TMP_MOUNT_PATH}"/Library/Preferences/com.deploystudio.server.plist 2>&1

  if [ ! -e "${TMP_MOUNT_PATH}/System/Installation" ]
  then
    mkdir "${TMP_MOUNT_PATH}/System/Installation" 2>&1
  fi

  if [ ! -e "${TMP_MOUNT_PATH}/Library/Logs" ]
  then
    mkdir "${TMP_MOUNT_PATH}/Library/Logs" 2>&1
  fi

  if [ ${SYS_VERS} == "10.5" ]
  then
    ditto_file_at_path more /usr/bin 2>&1

    if [ -e "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration" ]
    then
      rm -rf "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration" 2>&1
    fi
    ditto --rsrc "${SYSBUILDER_FOLDER}/${SYS_VERS}/SystemConfiguration" "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration" 2>&1

    if [ -e "${TMP_MOUNT_PATH}/System/Library/LaunchDaemons" ]
    then
      rm -rf "${TMP_MOUNT_PATH}/System/Library/LaunchDaemons" 2>&1
    fi
    ditto --rsrc "${SYSBUILDER_FOLDER}/${SYS_VERS}/LaunchDaemons" "${TMP_MOUNT_PATH}/System/Library/LaunchDaemons" 2>&1
    chown -R root:wheel "${TMP_MOUNT_PATH}/System/Library/LaunchDaemons" 2>&1
    chmod 755 "${TMP_MOUNT_PATH}"/System/Library/LaunchDaemons 2>&1
    chmod 644 "${TMP_MOUNT_PATH}"/System/Library/LaunchDaemons/* 2>&1
  
    if [ -e "${TMP_MOUNT_PATH}/System/Library/LaunchAgents" ]
    then
      rm -rf "${TMP_MOUNT_PATH}/System/Library/LaunchAgents" 2>&1
    fi
    ditto --rsrc "${SYSBUILDER_FOLDER}/${SYS_VERS}/LaunchAgents" "${TMP_MOUNT_PATH}/System/Library/LaunchAgents" 2>&1
    chown -R root:wheel "${TMP_MOUNT_PATH}"/System/Library/LaunchAgents 2>&1
    chmod 755 "${TMP_MOUNT_PATH}"/System/Library/LaunchAgents 2>&1
    chmod 644 "${TMP_MOUNT_PATH}"/System/Library/LaunchAgents/* 2>&1

    rm "${TMP_MOUNT_PATH}"/tmp

    ln -s var/tmp "${TMP_MOUNT_PATH}"/tmp
  else
    ditto /var/run/resolv.conf "${TMP_MOUNT_PATH}/var/run/resolv.conf" 2>&1
    ln -s /var/run/resolv.conf "${TMP_MOUNT_PATH}/etc/resolv.conf" 2>&1
  fi

  if [ "${SYS_VERS}" == "10.5" ]
  then
    cp -R "${SYSBUILDER_FOLDER}/${SYS_VERS}"/etc/* "${TMP_MOUNT_PATH}/etc/" 2>&1
    sed s/__DISPLAY_SLEEP__/${DISPLAY_SLEEP}/g "${SYSBUILDER_FOLDER}/${SYS_VERS}"/etc/rc.install > "${TMP_MOUNT_PATH}"/etc/rc.install 2>&1
    chmod 555 "${TMP_MOUNT_PATH}"/etc/rc.install 2>&1
  else
    cp "${SYSBUILDER_FOLDER}/${SYS_VERS}/hostconfig" "${TMP_MOUNT_PATH}/etc/hostconfig" 2>&1
    cp "${SYSBUILDER_FOLDER}/${SYS_VERS}/rc.common" "${TMP_MOUNT_PATH}/etc/rc.common" 2>&1
    sed s/__DISPLAY_SLEEP__/${DISPLAY_SLEEP}/g "${SYSBUILDER_FOLDER}/${SYS_VERS}"/rc.cdrom > "${TMP_MOUNT_PATH}"/etc/rc.cdrom 2>&1
    cp "${SYSBUILDER_FOLDER}/${SYS_VERS}/rc.cdrom.postWS" "${TMP_MOUNT_PATH}/etc/rc.cdrom.postWS" 2>&1
    cp "${SYSBUILDER_FOLDER}/${SYS_VERS}/rc.shutdown" "${TMP_MOUNT_PATH}/etc/rc.shutdown" 2>&1
    chmod 755 "${TMP_MOUNT_PATH}"/etc/rc.postWS 2>&1
    chmod 644 "${TMP_MOUNT_PATH}"/etc/rc.shutdown 2>&1
  fi
  chmod 644 "${TMP_MOUNT_PATH}"/etc/hostconfig 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/etc/rc.common 2>&1
  chmod 755 "${TMP_MOUNT_PATH}"/etc/rc.cdrom 2>&1

  rm -rf "${TMP_MOUNT_PATH}/var/log/"* 2>&1

  if [ -e "/Library/Application Support/DeployStudio" ]
  then
    ditto --rsrc "/Library/Application Support/DeployStudio" "${TMP_MOUNT_PATH}/Library/Application Support/DeployStudio" 2>&1
    chown -R root:admin "${TMP_MOUNT_PATH}/Library/Application Support/DeployStudio" 2>&1
  fi

  if [ -e "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration/preferences.plist" ]
  then
    rm "${TMP_MOUNT_PATH}/Library/Preferences/SystemConfiguration/preferences.plist" 2>&1
  fi

  if [ "${LANGUAGE_CODE}" == "auto" ]
  then
    GLOBAL_PREFERENCES_FILE=`find "${HOME}"/Library/Preferences/ByHost -name ".GlobalPreferences*" | head -n1`
	if [ -z "${GLOBAL_PREFERENCES_FILE}" ]
	then
      GLOBAL_PREFERENCES_FILE="${SYSBUILDER_FOLDER}/common/en.GlobalPreferences.plist"
	fi
    HITOOLBOX_FILE=`find "${HOME}"/Library/Preferences/ByHost -name "com.apple.HIToolbox*" | head -n1`
	if [ -z "${HITOOLBOX_FILE}" ]
	then
      HITOOLBOX_FILE="${SYSBUILDER_FOLDER}/common/en.com.apple.HIToolbox.plist"
	fi
  else
    GLOBAL_PREFERENCES_FILE="${SYSBUILDER_FOLDER}/common/${LANGUAGE_CODE}.GlobalPreferences.plist"
    HITOOLBOX_FILE="${SYSBUILDER_FOLDER}/common/${LANGUAGE_CODE}.com.apple.HIToolbox.plist"
  fi   
  
  ditto "${GLOBAL_PREFERENCES_FILE}" "${TMP_MOUNT_PATH}/Library/Preferences/.GlobalPreferences.plist" 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/Library/Preferences/.GlobalPreferences.plist 2>&1

  ditto "${HITOOLBOX_FILE}" "${TMP_MOUNT_PATH}/Library/Preferences/com.apple.HIToolbox.plist" 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.HIToolbox.plist 2>&1

  ditto "${GLOBAL_PREFERENCES_FILE}" "${TMP_MOUNT_PATH}/var/root/Library/Preferences/.GlobalPreferences.plist" 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/var/root/Library/Preferences/.GlobalPreferences.plist 2>&1

  ditto "${HITOOLBOX_FILE}" "${TMP_MOUNT_PATH}/var/root/Library/Preferences/com.apple.HIToolbox.plist" 2>&1
  chmod 644 "${TMP_MOUNT_PATH}"/var/root/Library/Preferences/com.apple.HIToolbox.plist 2>&1
  
  cp -p -R /System/Library/Extensions/ATTO* "${TMP_MOUNT_PATH}"/System/Library/Extensions/ 2>&1
  cp -p -R /System/Library/Extensions/ATI* "${TMP_MOUNT_PATH}"/System/Library/Extensions/ 2>&1
  cp -p -R /System/Library/Extensions/AppleIntelGMA* "${TMP_MOUNT_PATH}"/System/Library/Extensions/ 2>&1
  cp -p -R /System/Library/Extensions/GeForce* "${TMP_MOUNT_PATH}"/System/Library/Extensions/ 2>&1
  cp -p -R /System/Library/Extensions/NVDA* "${TMP_MOUNT_PATH}"/System/Library/Extensions/ 2>&1
  ditto --rsrc /System/Library/Extensions/AppleIntelIntegratedFramebuffer.kext "${TMP_MOUNT_PATH}"/System/Library/Extensions/AppleIntelIntegratedFramebuffer.kext 2>&1
  ditto --rsrc /System/Library/Extensions/AppleNDRV.kext "${TMP_MOUNT_PATH}"/System/Library/Extensions/AppleNDRV.kext 2>&1
  ditto --rsrc /System/Library/Frameworks/OpenGL.framework "${TMP_MOUNT_PATH}"/System/Library/Frameworks/OpenGL.framework 2>&1
  ditto --rsrc /usr/libexec/oah "${TMP_MOUNT_PATH}"/usr/libexec/oah 2>&1

  # Display mirroring support
  ditto --rsrc  "${SYSBUILDER_FOLDER}"/common/enableDisplayMirroring "${TMP_MOUNT_PATH}"/usr/bin/enableDisplayMirroring 2>&1
  chmod 755 "${TMP_MOUNT_PATH}"/usr/bin/enableDisplayMirroring 2>&1
  chown root:wheel "${TMP_MOUNT_PATH}"/usr/bin/enableDisplayMirroring 2>&1


  # VNC server support
  if [ -n "${ARD_PASSWORD}" ]
  then
    ditto --rsrc /System/Library/CoreServices/RemoteManagement "${TMP_MOUNT_PATH}"/System/Library/CoreServices/RemoteManagement 2>&1

    ditto --rsrc "${SYSBUILDER_FOLDER}"/${SYS_VERS}/com.apple.RemoteManagement.plist "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.RemoteManagement.plist 2>&1
    if [ ${SYS_VERS} == "10.5" ]
    then
      echo enabled > "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.RemoteManagement.launchd
	  echo enabled > "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.ScreenSharing.launchd
    fi

    ditto --rsrc "${SYSBUILDER_FOLDER}/common/OSXvnc-server" "${TMP_MOUNT_PATH}/usr/bin/OSXvnc-server" 2>&1
    chmod 755 "${TMP_MOUNT_PATH}"/usr/bin/OSXvnc-server 2>&1
    chown root:wheel "${TMP_MOUNT_PATH}"/usr/bin/OSXvnc-server 2>&1

    "${SYSBUILDER_FOLDER}"/common/storepasswd "${ARD_PASSWORD}" "${TMP_MOUNT_PATH}/Library/Preferences/com.osxvnc.txt" 2>&1
    chmod 644 "${TMP_MOUNT_PATH}"/Library/Preferences/com.osxvnc.txt 2>&1
    chown root:wheel "${TMP_MOUNT_PATH}"/Library/Preferences/com.osxvnc.txt 2>&1
	echo "${ARD_PASSWORD}" | perl -wne 'BEGIN { @k = unpack "C*", pack "H*", "1734516E8BA8C5E2FF1C39567390ADCA"}; chomp; s/^(.{8}).*/$1/; @p = unpack "C*", $_; foreach (@k) { printf "%02X", $_ ^ (shift @p || 0) }; print "\n"' > "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.VNCSettings.txt
    chmod 400 "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.VNCSettings.txt 2>&1
    chown root:wheel "${TMP_MOUNT_PATH}"/Library/Preferences/com.apple.VNCSettings.txt 2>&1
  fi

  if [ -n "${NTP_SERVER}" ]
  then
    echo "${NTP_SERVER}" > "${TMP_MOUNT_PATH}"/Library/Preferences/ntpserver.txt
    chmod 644 "${TMP_MOUNT_PATH}"/Library/Preferences/ntpserver.txt 2>&1
    chown root:wheel "${TMP_MOUNT_PATH}"/Library/Preferences/ntpserver.txt 2>&1
  fi

  # improve tcp performance (risky)
  if [ -n "${ENABLE_CUSTOM_TCP_STACK_SETTINGS}" ]
  then
    enable_custom_tcp_stack_settings
  fi
  
  chmod -R 644 "${TMP_MOUNT_PATH}"/Library/Preferences/* 2>&1
  chmod 755 "${TMP_MOUNT_PATH}"/Library/Preferences/DirectoryService 2>&1
  chmod 755 "${TMP_MOUNT_PATH}"/Library/Preferences/SystemConfiguration 2>&1
  chown -R root:wheel "${TMP_MOUNT_PATH}"/Library/Preferences/* 2>&1

  touch "${TMP_MOUNT_PATH}"/System/Library/CoreServices/ServerVersion.plist 2>&1
  chmod 444 "${TMP_MOUNT_PATH}"/System/Library/CoreServices/ServerVersion.plist 2>&1
  chown root:wheel "${TMP_MOUNT_PATH}"/System/Library/CoreServices/ServerVersion.plist 2>&1

  if [ -n "${CUSTOM_RUNTIME_BACKGROUND}" ] && [ -f "${CUSTOM_RUNTIME_BACKGROUND}" ]
  then
    ditto --rsrc "${CUSTOM_RUNTIME_BACKGROUND}" "${TMP_MOUNT_PATH}"/System/Library/CoreServices/DefaultDesktop.jpg
  else
    ditto --rsrc "${SYSBUILDER_FOLDER}"/common/DefaultDesktop.jpg "${TMP_MOUNT_PATH}"/System/Library/CoreServices/DefaultDesktop.jpg
  fi

  if [ -e "/Applications/Utilities/DeployStudio Admin.app" ]
  then
    ditto --rsrc "/Applications/Utilities/DeployStudio Admin.app" "${TMP_MOUNT_PATH}/Applications/Utilities/DeployStudio Admin.app" 2>&1
  elif [ -e "${SYSBUILDER_FOLDER}/../../../../Applications/Utilities/DeployStudio Admin.app" ]
  then
    ditto --rsrc "${SYSBUILDER_FOLDER}/../../../../Applications/Utilities/DeployStudio Admin.app" "${TMP_MOUNT_PATH}/Applications/Utilities/DeployStudio Admin.app" 2>&1
  fi
  chown -R root:admin "${TMP_MOUNT_PATH}/Applications/Utilities/DeployStudio Admin.app" 2>&1

  # disable spotlight indexing again (just in case)
  mdutil -i off "${TMP_MOUNT_PATH}"
  mdutil -E "${TMP_MOUNT_PATH}"
  defaults write "${TMP_MOUNT_PATH}"/.Spotlight-V100/_IndexPolicy Policy -int 3

  rm -rf "${TMP_MOUNT_PATH}"/System/Library/Caches/com.apple.bootstamps
  rm -r  "${TMP_MOUNT_PATH}"/usr/standalone/bootcaches.plist
  rm -r  "${TMP_MOUNT_PATH}"/System/Library/Extensions.mkext

  if [ -e "${TMP_MOUNT_PATH}"/Volumes ]
  then
    rm -rf "${TMP_MOUNT_PATH}"/Volumes/* 2>&1
  fi
}

########################################################
# Main
########################################################

echo "Running ${SCRIPT_NAME} v${VERSION} ("`date`")"

# defaults
DISPLAY_SLEEP=10

# parsing arguments
for P in "${@}"
do
  F=`echo ${P} | awk -F= '{ print $1 }'`
  V=`echo ${P} | awk -F= '{ print $2 }'`
  if [ "${F}" == "-type" ]
  then
    SYS_BUILDER_TYPE=${V}
  elif [ "${F}" == "-volume" ]
  then
    if [ -e "/Volumes/${V}" ]
    then
      TARGET_VOLUME="${V}"
    fi
  elif [ "${F}" == "-erasedisk" ]
  then
    ERASE_DISK=1
  elif [ "${F}" == "-id" ]
  then
    NBI_ID=${V}
  elif [ "${F}" == "-dest" ]
  then
    DEST_PATH=${V}
  elif [ "${F}" == "-name" ]
  then
    NBI_NAME=${V}
  elif [ "${F}" == "-loc" ]
  then
    LANGUAGE=${V}
  elif [ "${F}" == "-serverurl" ]
  then
    SERVER_URL=${V}
  elif [ "${F}" == "-serverurl2" ]
  then
    SERVER_URL2=${V}
  elif [ "${F}" == "-displaylogs" ]
  then
    SERVER_DISPLAY_LOGS=1
  elif [ "${F}" == "-login" ]
  then
    SERVER_LOGIN=${V}
  elif [ "${F}" == "-password" ]
  then
    SERVER_PASSWORD=${V}
  elif [ "${F}" == "-ardlogin" ]
  then
    ARD_LOGIN=${V}
  elif [ "${F}" == "-ardpassword" ]
  then
    ARD_PASSWORD=${V}
  elif [ "${F}" == "-timeout" ]
  then
    TIMEOUT=${V}
  elif [ "${F}" == "-displaysleep" ]
  then
    DISPLAY_SLEEP=${V}
  elif [ "${F}" == "-enableruby" ]
  then
    ENABLE_RUBY=1
  elif [ "${F}" == "-enablepython" ]
  then
    ENABLE_PYTHON=1
  elif [ "${F}" == "-enablecustomtcpstacksettings" ]
  then
    ENABLE_CUSTOM_TCP_STACK_SETTINGS=1
  elif [ "${F}" == "-disablewirelesssupport" ]
  then
    DISABLE_WIRELESS_SUPPORT=1
  elif [ "${F}" == "-disableadviewer" ]
  then
    DISABLE_AD_VIEWER=1
  elif [ "${F}" == "-ntp" ]
  then
    NTP_SERVER=${V}
  elif [ "${F}" == "-customtitle" ]
  then
    CUSTOM_RUNTIME_TITLE=${V}
  elif [ "${F}" == "-custombackground" ]
  then
    CUSTOM_RUNTIME_BACKGROUND=${V}
  fi
done

if [ "${SYS_BUILDER_TYPE}" == "local" ] && [ ${#TARGET_VOLUME} -eq 0 ]
then
  print_usage
  echo "RuntimeAbortScript"
  exit 1
fi
if [ "${SYS_BUILDER_TYPE}" == "netboot" ] && [ `expr ${#NBI_ID} \* ${#NBI_NAME} \* ${#DEST_PATH}` -eq 0 ]
then
  print_usage
  echo "RuntimeAbortScript"
  exit 1
fi

# check DeployStudio Admin is installed
if [ ! -e "/Applications/Utilities/DeployStudio Admin.app" ] && [ ! -e "${SYSBUILDER_FOLDER}/../../../../Applications/Utilities/DeployStudio Admin.app" ]
then
    echo "DeployStudio Admin.app not found. Please reinstall DeployStudio on this computer."
	echo "Aborting ${SCRIPT_NAME} v${VERSION} ("`date`")"
    echo "RuntimeAbortScript"
    exit 1
fi

# preparing media
if [ "${SYS_BUILDER_TYPE}" == "local" ]
then
  TESTED_VOLUME="/Volumes/${TARGET_VOLUME}"
else
  TESTED_VOLUME="${DEST_PATH}"
fi
  
VOLUME_SIZE=`df -m "${TESTED_VOLUME}" | tail -n 1 | awk '{ print $2 }'`
if [ ${VOLUME_SIZE} -lt 1750 ]
then
    echo "Volume \"${TESTED_VOLUME}\" is to too small."
	echo "Aborting ${SCRIPT_NAME} v${VERSION} ("`date`")"
    echo "RuntimeAbortScript"
    exit 1
fi

if [ "${LANGUAGE}" == "Current" ]
then
    LANGUAGE_CODE=auto
elif [ "${LANGUAGE}" == "French" ]
then
    LANGUAGE_CODE=fr
elif [ "${LANGUAGE}" == "German" ]
then
    LANGUAGE_CODE=de
elif [ "${LANGUAGE}" == "Canadian French" ]
then
    LANGUAGE_CODE=fr_CA
else
    LANGUAGE="English"
    LANGUAGE_CODE=en
fi

SYS_VERS=10.`sw_vers -productVersion | awk -F. '{ print $2 }'`
if [ "${SYS_VERS}" == "10.6" ] || [ "${SYS_VERS}" == "10.7" ] || [ "${SYS_VERS}" == "10.8" ]
then
  ARCH=i386
elif [ "${SYS_VERS}" == "10.5" ]
then
  ARCH=universal
else  
  ARCH=`arch`
  OS_NAME=`sw_vers -productName`
  if [ "${OS_NAME}" == "Mac OS X Server" ]
  then
    UB_MACH_KERNEL=`lipo -info /mach_kernel | grep i386 | grep ppc`
    if [ -n "${UB_MACH_KERNEL}" ]
	then
      ARCH=universal
    fi
  fi
fi

echo "User:"${UID} 2>&1
echo "System version:"${SYS_VERS} 2>&1
echo "Architecture:"${ARCH} 2>&1

VOL_NAME=DeployStudioRuntime

if [ "${SYS_BUILDER_TYPE}" == "local" ]
then 
  VOL_NAME="${VOL_NAME}HD"
  if [ -n "${ERASE_DISK}" ]
  then
    DEVICE=/dev/disk`diskutil list | grep "${TARGET_VOLUME}" | awk '{ print $6 }' | sed s/disk// | awk -Fs '{ print $1 }' | tail -n1`
    if [ ! -e ${DEVICE} ]
    then
      echo "An error occured while resolving the device for volume \"${TARGET_VOLUME}\"."
	  echo "Aborting ${SCRIPT_NAME} v${VERSION} ("`date`")"
	  echo "RuntimeAbortScript"
      exit 1
    fi

    diskutil eraseDisk "Journaled HFS+" "${VOL_NAME}" GPTFormat "${DEVICE}" 2>&1
    if [ ${?} -ne 0 ]
    then
      echo "An error occured while formating the \"${DEVICE}\" device."
	  echo "Aborting ${SCRIPT_NAME} v${VERSION} ("`date`")"
      echo "RuntimeAbortScript"
      exit 1
    fi
  else
    diskutil eraseVolume "Journaled HFS+" "${VOL_NAME}" "/Volumes/${TARGET_VOLUME}" 2>&1
    if [ ${?} -ne 0 ]
    then
      echo "An error occured while erasing the \"/Volumes/${TARGET_VOLUME}\" volume."
	  echo "Aborting ${SCRIPT_NAME} v${VERSION} ("`date`")"
      echo "RuntimeAbortScript"
      exit 1
    fi
  fi

  DEVICE=/dev/`diskutil list | grep "${VOL_NAME}" | awk '{ print $6 }' | tail -n1`

  vsdbutil -a "/Volumes/${VOL_NAME}" 2>&1
  if [ ${?} -ne 0 ]
  then
    echo "An error occured while modifying the \"${DEVICE}\" device."
	echo "Aborting ${SCRIPT_NAME} v${VERSION} ("`date`")"
    echo "RuntimeAbortScript"
    exit 1
  fi

  TMP_MOUNT_PATH="/Volumes/${VOL_NAME}"
  if [ ! -e "${TMP_MOUNT_PATH}" ]
  then
    echo "An error occured while accessing to the \"${TMP_MOUNT_PATH}\" volume."
	echo "Aborting ${SCRIPT_NAME} v${VERSION} ("`date`")"
    echo "RuntimeAbortScript"
    exit 1
  fi

  chmod 755 "${TMP_MOUNT_PATH}"
  chown root:admin "${TMP_MOUNT_PATH}"
else
  NBI_FOLDER=${DEST_PATH}/`echo ${NBI_NAME} | tr ' ' '-'`.nbi
  SYSTEM_IMAGE_FILE=${NBI_FOLDER}/NetInstall.sparseimage
  SYSTEM_IMAGE_LINK=${NBI_FOLDER}/NetInstall.dmg
  TMP_MOUNT_PATH=/tmp/_tmpDeployStudioRuntimeMount

  if [ ! -e "${DEST_PATH}" ]
  then
    mkdir -p "${DEST_PATH}" 2>&1 
  fi

  ditto --rsrc -k -x "${SYSBUILDER_FOLDER}/common/nbi_folder.zip" "${DEST_PATH}" 2>&1

  if [ -e "${NBI_FOLDER}" ]
  then
    rm -rf "${NBI_FOLDER}" 2>&1
  fi
  mv "${DEST_PATH}/nbi_folder" "${NBI_FOLDER}" 2>&1

  chmod 777 "${NBI_FOLDER}" 2>&1

  hdiutil create "${SYSTEM_IMAGE_FILE}" -volname "${VOL_NAME}" -size 5G -type SPARSE -fs HFS+ -stretch 10G -uid 0 -gid 80 -mode 1775 -layout NONE 2>&1
  if [ ${?} -ne 0 ]
  then
    echo "An error occured while creating the \"${SYSTEM_IMAGE_FILE}\"."
    rm -rf "${NBI_FOLDER}" 2>&1
	echo "Aborting ${SCRIPT_NAME} v${VERSION} ("`date`")"
    echo "RuntimeAbortScript"
    exit 1
  fi

  chmod 777 "${SYSTEM_IMAGE_FILE}" 2>&1

  if [ -e "${TMP_MOUNT_PATH}" ]
  then
    rm -rf "${TMP_MOUNT_PATH}" 2>&1
  fi
  mkdir "${TMP_MOUNT_PATH}" 2>&1

  ATTACHED=`hdiutil attach "${SYSTEM_IMAGE_FILE}" -owners on -mountpoint "${TMP_MOUNT_PATH}" 2>&1`

  DEVICE=`echo ${ATTACHED} | awk '{ print $1 }'`
  if [ ! -e "${DEVICE}" ]
  then
    DEVICE=/dev/`diskutil list | grep "${VOL_NAME}" | awk '{ print $5 }' | tail -n1`
  fi
fi

# filling media
if [ "${SYS_VERS}" == "10.8" ]
then
	fill_volume_1080
elif [ "${SYS_VERS}" == "10.7" ]
then
	fill_volume_1073
elif [ "${SYS_VERS}" == "10.6" ]
then
	fill_volume_1060
else
	fill_volume
fi

# disable Wireless support
if [ -n "${DISABLE_WIRELESS_SUPPORT}" ]
then
  rm -rf "${TMP_MOUNT_PATH}"/System/Library/Extensions/IO80211Family.kext
fi

# closing media
if [ "${SYS_BUILDER_TYPE}" == "local" ]
then
  # save sys_builder version
  defaults write "${TMP_MOUNT_PATH}/etc/DeployStudioAssistantInfo" SysBuilderVersion "${VERSION}"
  plutil -convert xml1 "${TMP_MOUNT_PATH}/etc/DeployStudioAssistantInfo.plist"
  chmod 664 "${TMP_MOUNT_PATH}/etc/DeployStudioAssistantInfo.plist" 2>&1
  chown root:admin "${TMP_MOUNT_PATH}/etc/DeployStudioAssistantInfo.plist" 2>&1

  # add kernel and kext cache
  ditto --norsrc /mach_kernel "${TMP_MOUNT_PATH}"/mach_kernel 2>&1
  if [ -e "${TMP_MOUNT_PATH}"/Volumes ]
  then
    rm -rf "${TMP_MOUNT_PATH}"/Volumes/* 2>&1
  fi

  kextcache -l -m "${TMP_MOUNT_PATH}"/System/Library/Extensions.mkext /System/Library/Extensions

  bless --folder "${TMP_MOUNT_PATH}"/System/Library/CoreServices --label "${VOL_NAME}" --bootinfo --bootefi --verbose
else
  ditto --rsrc "${SYSBUILDER_FOLDER}/${SYS_VERS}/NBImageInfo.plist" "${NBI_FOLDER}/NBImageInfo.plist"
  if [ "${ARCH}" == "universal" ]
  then
    defaults write "${NBI_FOLDER}/NBImageInfo" Architectures -array i386 ppc
  else
    defaults write "${NBI_FOLDER}/NBImageInfo" Architectures -array ${ARCH}
  fi
  defaults write "${NBI_FOLDER}/NBImageInfo" Index -int ${NBI_ID}
  defaults write "${NBI_FOLDER}/NBImageInfo" Name "${NBI_NAME}"
  defaults write "${NBI_FOLDER}/NBImageInfo" Description ${NBI_NAME}
  defaults write "${NBI_FOLDER}/NBImageInfo" Language "${LANGUAGE}"
  defaults write "${NBI_FOLDER}/NBImageInfo" LanguageCode ${LANGUAGE_CODE}
  defaults write "${NBI_FOLDER}/NBImageInfo" osVersion "${SYS_VERS}"
  plutil -convert xml1 "${NBI_FOLDER}/NBImageInfo.plist"

  # save sys_builder version
  defaults write "${NBI_FOLDER}/DeployStudioAssistantInfo" SysBuilderVersion "${VERSION}"
  plutil -convert xml1 "${NBI_FOLDER}/DeployStudioAssistantInfo.plist"

  # add kernel and kext cache
  if [ "${ARCH}" == "universal" ]
  then
    mkdir "${NBI_FOLDER}/ppc" "${NBI_FOLDER}/i386" 2>&1
    chmod 777 "${NBI_FOLDER}/ppc" "${NBI_FOLDER}/i386" 2>&1
    lipo -extract ppc /mach_kernel -output "${NBI_FOLDER}/ppc/mach.macosx" 2>&1
    lipo -extract i386 /mach_kernel -output "${NBI_FOLDER}/i386/mach.macosx" 2>&1
    chmod 664 "${NBI_FOLDER}"/ppc/* "${NBI_FOLDER}"/i386/* 2>&1
  elif [ "${SYS_VERS}" == "10.6" ] || [ "${SYS_VERS}" == "10.7" ] || [ "${SYS_VERS}" == "10.8" ]
  then
    mkdir -p "${NBI_FOLDER}/i386/x86_64" 2>&1
    chmod -R 777 "${NBI_FOLDER}/i386" 2>&1
    lipo -extract i386 /mach_kernel -output "${NBI_FOLDER}/i386/mach.macosx" 2>&1
    lipo -extract x86_64 /mach_kernel -output "${NBI_FOLDER}/i386/x86_64/mach.macosx" 2>&1
    chmod 664 "${NBI_FOLDER}"/i386/mach.macosx "${NBI_FOLDER}"/i386/x86_64/mach.macosx 2>&1
  else
    mkdir "${NBI_FOLDER}/${ARCH}" 2>&1
    chmod 777 "${NBI_FOLDER}/${ARCH}" 2>&1
    ditto --norsrc /mach_kernel "${NBI_FOLDER}/${ARCH}/mach.macosx" 2>&1
  fi

  if [ "universal" == "${ARCH}" ]
  then
    ditto --norsrc /usr/standalone/ppc/bootx.bootinfo "${NBI_FOLDER}/ppc/booter" 2>&1
    ditto --norsrc /usr/standalone/i386/boot.efi "${NBI_FOLDER}/i386/booter" 2>&1
  elif [ "${SYS_VERS}" == "10.6" ] || [ "${SYS_VERS}" == "10.7" ] || [ "${SYS_VERS}" == "10.8" ]
  then
    ditto --norsrc /usr/standalone/i386/boot.efi "${NBI_FOLDER}/${ARCH}/booter" 2>&1
    ditto --norsrc /usr/standalone/i386/boot.efi "${NBI_FOLDER}/${ARCH}/x86_64/booter" 2>&1
  elif [ "i386" == "${ARCH}" ]
  then
    ditto --norsrc /usr/standalone/i386/boot.efi "${NBI_FOLDER}/${ARCH}/booter" 2>&1
  else
    ditto --norsrc /usr/standalone/ppc/bootx.bootinfo "${NBI_FOLDER}/${ARCH}/booter" 2>&1
  fi

  if [ "${SYS_BUILDER_TYPE}" == "local" ]
  then
    KEXTCACHE_OPTIONS="-N -L -S"
  else
    KEXTCACHE_OPTIONS="-N -L"
  fi

  if [ "${ARCH}" == "universal" ]
  then
    kextcache -a i386 \
	          ${KEXTCACHE_OPTIONS} \
              -m "${NBI_FOLDER}/i386/mach.macosx.mkext" \
              -K "${NBI_FOLDER}/i386/booter" \
              "${TMP_MOUNT_PATH}/System/Library/Extensions"

    kextcache -a ppc \
	          ${KEXTCACHE_OPTIONS} \
              -m "${NBI_FOLDER}/ppc/mach.macosx.mkext" \
              -K "${NBI_FOLDER}/ppc/booter" \
              "${TMP_MOUNT_PATH}/System/Library/Extensions"
  elif [ "${SYS_VERS}" == "10.7" ] || [ "${SYS_VERS}" == "10.8" ]
  then
    kextcache -a i386 \
	          ${KEXTCACHE_OPTIONS} -z \
              -K "${TMP_MOUNT_PATH}/mach_kernel" \
              -c "${NBI_FOLDER}/i386/kernelcache" \
              "${TMP_MOUNT_PATH}/System/Library/Extensions"

    kextcache -a x86_64 \
	          ${KEXTCACHE_OPTIONS} -z \
              -K "${TMP_MOUNT_PATH}/mach_kernel" \
              -c "${NBI_FOLDER}/i386/x86_64/kernelcache" \
              "${TMP_MOUNT_PATH}/System/Library/Extensions"
  elif [ "${SYS_VERS}" == "10.6" ]
  then
    kextcache -a i386 \
	          ${KEXTCACHE_OPTIONS} \
              -m "${NBI_FOLDER}/i386/mach.macosx.mkext" \
              -K "${NBI_FOLDER}/i386/booter" \
              "${TMP_MOUNT_PATH}/System/Library/Extensions"

    kextcache -a x86_64 \
	          ${KEXTCACHE_OPTIONS} \
              -m "${NBI_FOLDER}/i386/x86_64/mach.macosx.mkext" \
              -K "${NBI_FOLDER}/i386/x86_64/booter" \
              "${TMP_MOUNT_PATH}/System/Library/Extensions"
  else
    kextcache -a ${ARCH} \
	          ${KEXTCACHE_OPTIONS} \
			  -m "${NBI_FOLDER}/${ARCH}/mach.macosx.mkext" \
			  "${TMP_MOUNT_PATH}/System/Library/Extensions" 2>&1
  fi

  TRIES=2

  hdiutil detach "${TMP_MOUNT_PATH}" 2>&1

  while [ ${?} -ne 0 ];
  do
    TRIES=`expr ${TRIES} + 1` 
    if [ ${TRIES} -gt 5 ]
    then
      echo "An error occured while umount \"${TMP_MOUNT_PATH}\"."
	  echo "Aborting ${SCRIPT_NAME} v${VERSION} ("`date`")"
	  echo "RuntimeAbortScript"
      exit 1
    fi
    sleep 20
    hdiutil detach -force "${TMP_MOUNT_PATH}" 2>&1
  done

  rm -rf "${TMP_MOUNT_PATH}" 2>&1
  chmod -R 664 "${NBI_FOLDER}" 2>&1
  chmod 775 "${NBI_FOLDER}" 2>&1

  if [ "${ARCH}" == "universal" ]
  then
    chmod 775 "${NBI_FOLDER}/ppc" "${NBI_FOLDER}/i386" 2>&1
  elif [ "${SYS_VERS}" == "10.6" ] || [ "${SYS_VERS}" == "10.7" ] || [ "${SYS_VERS}" == "10.8" ]
  then
    chmod 775 "${NBI_FOLDER}/i386" "${NBI_FOLDER}/i386/x86_64" 2>&1
  else
    chmod 775 "${NBI_FOLDER}/${ARCH}" 2>&1
  fi

  ln -s `basename "${SYSTEM_IMAGE_FILE}"` "${SYSTEM_IMAGE_LINK}"

  chown -R root:admin "${NBI_FOLDER}" 2>&1
fi

rm /tmp/DSCustomDefaultDesktop.jpg 2>/dev/null

echo "Exiting ${SCRIPT_NAME} v${VERSION} ("`date`")"

exit 0
