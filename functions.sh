CheckVariablesExist() {
  if [[ -z $SourceTreeLoc ]]; then
    HandleError 230; fi
  if [[ -z $DeviceList ]]; then
    HandleError 231; fi
  if ! [[ "$(declare -p DeviceList)" =~ "declare -a" ]]; then
    HandleError 232; fi
  if [[ -z $LogFileLoc ]]; then
    HandleError 233; fi
  if [[ -z $RomVariant ]]; then
    HandleError 234; fi
  if [[ -z $RomBuildType ]]; then
    HandleError 235; fi
  if [[ -z $RomVersion ]]; then
    HandleError 236; fi
  if [[ -z $JackRAM ]]; then
    HandleError 243; fi
  if [[ -z $MakeClean ]]; then
    HandleError 237; fi
  if ! [[ -z $RepoPicks ]]; then
    if ! [[ "$(declare -p RepoPicks)" =~ "declare -a" ]]; then
      HandleError 242; fi
  fi
  if ! [[ -z $RepoTopics ]]; then
    if ! [[ "$(declare -p RepoTopics)" =~ "declare -a" ]]; then
      HandleError 244; fi
  fi
  if [[ $SSHUpload = true ]]; then
    if [[ -z $SSHHost ]]; then
      HandleError 238; fi
    if [[ -z $SSHUser ]]; then
      HandleError 239; fi
    if [[ -z $SSHPort ]]; then
      HandleError 240; fi
    if [[ -z $SSHDirectory ]]; then
      HandleError 241; fi
  fi
}

HandleError() {
  # Check we were passed an error code as 1st argument
  if ! [[ -z "$1" ]]; then
    # If it's error 210 (log file not writable), exit without writing to log file (otherwise we go round in circles)
    if [[ $1 = 210 ]]; then
      # Log file not writable
      echo "Log file directory not writable, aborting"
      exit 210
    elif [[ $1 = 233 ]]; then
      # If it's error 233, $LogFileLoc has not been set, so don't write a log
      echo "\$LogFileLoc not defined in settings.sh. This is needed desperately"
      exit 233
    else
      # All other error codes are looked up
      ErrorNum=$1
      # Get error description (listed in ./errors.sh)
      GetErrorDesc $ErrorNum
      LogMain "Error $ErrorNum: $ErrorDesc"
      LogMain 'Killing jack-server and stopping due to error'
      LogCommandMainErrors "KillJack"
      exit $ErrorNum
    fi
  else
    # We weren't passed an error code, so exit
    LogMain "Unspecified Error" "a"
    LogMain 'Killing jack-server and stopping due to error' "a"
    LogCommandMainErrors "KillJack"
    exit 255
  fi
}

HandleWarn() {
  # Check we were passed a warning code as 1st argument
  if ! [[ -z "$1" ]]; then
    WarnNum=$1
    GetErrorDesc $WarnNum
    LogMain "Warning $WarnNum: $ErrorDesc"
    # If StopOnWarn in settings is set, then we stop on non-trivial errors (==warnings)
    if [[ $StopOnWarn = true ]]; then
      LogMain 'Stopping as \$StopOnWarn set' "a"
      exit $WarnNum
    fi
  else
    LogMain "Unspecified Warning (probably non-breaking)" "a"
    if [[ $StopOnWarn = true ]]; then
      LogMain 'Stopping as \$StopOnWarn set' "a"
      exit 255
    fi
  fi
}

LogCommandMake() {
  MakeLogFile=$LogFileLoc'/'$RomVariant'-'$RomVersion'-'$BuildDate'-'UNOFFICIAL'-'$Device'.zip.log'
  # If log file folder isn't writable, error code 210 passed
  if ! [[ -w $LogFileLoc ]]; then
    HandleError 210
  fi
  if ! [[ -z "$2" ]]; then
    # If Log is called in rewrite mode (Log "Blah blah" "r"), overwrite log file
    if [[ "$2" = "r" ]]; then
      $1 >  "$MakeLogFile" 2>&1
                #          ^^^^ redirect errors too
    # Otherwise, append
    else
      $1 >>  "$MakeLogFile" 2>&1
    fi
  else
    $1 >>  "$MakeLogFile" 2>&1
  fi;
}

LogMake() {
  MakeLogFile=$LogFileLoc'/'$RomVariant'-'$RomVersion'-'$BuildDate'-'UNOFFICIAL'-'$Device'.zip.log'
  # If log file folder isn't writable, error code 210 passed
  if ! [[ -w $LogFileLoc ]]; then
    HandleError 210
  fi
  if ! [[ -z "$2" ]]; then
    # If Log is called in rewrite mode (Log "Blah blah" "r"), overwrite log file
    if [[ "$2" = "r" ]]; then
      printf "%b\r\n"  "$1" >  "$MakeLogFile" 2>&1
                     #          ^^^^ redirect errors too
    # Otherwise, append
    else
      printf "%b\r\n"  "$1" >>  "$MakeLogFile" 2>&1
    fi
  else
    printf "%b\r\n"  "$1" >>  "$MakeLogFile" 2>&1
  fi;
}

LogCommandMain() {
  MainLogFile=$LogFileLoc'/'$RomVariant'-'$RomVersion'-'$BuildDate'-'UNOFFICIAL'.log'
  # If log file folder isn't writable, error code 210 passed
  if ! [[ -w $LogFileLoc ]]; then
    HandleError 210
  fi
  if ! [[ -z "$2" ]]; then
    # If Log is called in rewrite mode (Log "Blah blah" "r"), overwrite log file
    if [[ "$2" = "r" ]]; then
      $1 >  "$MainLogFile" 2>&1
                #          ^^^^ redirect errors too
    # Otherwise, append
    else
      $1 >>  "$MainLogFile" 2>&1
    fi
  else
    $1 >>  "$MainLogFile" 2>&1
  fi;
}

LogCommandMainErrors() {
  MainLogFile=$LogFileLoc'/'$RomVariant'-'$RomVersion'-'$BuildDate'-'UNOFFICIAL'.log'
  # If log file folder isn't writable, error code 210 passed
  if ! [[ -w $LogFileLoc ]]; then
    HandleError 210
  fi
  if ! [[ -z "$2" ]]; then
    # If Log is called in rewrite mode (Log "Blah blah" "r"), overwrite log file
    if [[ "$2" = "r" ]]; then
      $1 >/dev/null 2> "$MainLogFile"
      #             ^^^^^^^^^^^^^^^^^ redirect errors to MainLog
      #  ^^^^^^^^^^ discard stdout
    # Otherwise, append
    else
      $1 >>/dev/null 2>> "$MainLogFile"
    fi
  else
    $1 >>/dev/null 2>> "$MainLogFile"
  fi;
}

LogMain() {
  MainLogFile=$LogFileLoc'/'$RomVariant'-'$RomVersion'-'$BuildDate'-'UNOFFICIAL'.log'
  # If log file folder isn't writable, error code 210 passed
  if ! [[ -w $LogFileLoc ]]; then
    HandleError 210
  fi
  if ! [[ -z "$2" ]]; then
  # If log file folder isn't writable, error code 210 passed
    if [[ "$2" = "r" ]]; then
      printf "%b\r\n" "$1" > "$MainLogFile" 2>&1
    # Otherwise, append
    else
      printf "%b\r\n" "$1" >> "$MainLogFile" 2>&1
    fi
  else
    printf "%b\r\n" "$1" >> "$MainLogFile" 2>&1
  fi;
}

MidnightSnackLunch() {
  # Check we've been given argument 1 (device)
  if ! [[ -z $1 ]]; then
    # Run this from source directory...
    cd $SourceTreeLoc
    # ... for envsetup.sh to work
    LogCommandMainErrors "source build/envsetup.sh"
    LunchCommand=$RomVariant'_'$1'-'$RomBuildType
    LogCommandMake "lunch $LunchCommand" || HandleError 202
  else
    # Gimme more arguments
    HandleError 201
  fi
}

MidnightSnackMake() {
  if [[ -z $MakeThreadCount ]]; then
    if [[ $SignBuilds = true ]]; then
      LogCommandMake "mka target-files-package" || HandleError 200
    else
      LogCommandMake "mka otapackage" || HandleError 200
    fi
  else
    if [[ $SignBuilds = true ]]; then
      LogCommandMake "make -j$MakeThreadCount target-files-package" || HandleError 200
    else
      LogCommandMake "make -j$MakeThreadCount otapackage" || HandleError 200
    fi
  fi
}

GetBuildDate() {
  if [[ $BuildTomorrow = true ]]; then
      # Get YYYYMMDD for tomorrow
      BuildDate=$(date --date="+1 day" +%Y%m%d);
  else
    # Get YYYYMMDD for today
    BuildDate=$(date +%Y%m%d);
  fi
}

GetNewName() {
  # Check we've been given the first argument (device)
  if ! [[ -z $1 ]]; then
    if [[ $SignBuilds = true ]]; then
      NewName=$RomVariant'-'$RomVersion'-'$BuildDate'-'UNOFFICIAL'-'$1'-signed.zip'
    else
      NewName=$RomVariant'-'$RomVersion'-'$BuildDate'-'UNOFFICIAL'-'$1'.zip'
    fi
  else
    # Can I haz moar argument?
    HandleError 211
  fi
}

GetNewOTAName() {
  # Check we've been given the first argument (device)
  if ! [[ -z $1 ]]; then
    if [[ $SignBuilds = true ]]; then
      NewOTAName=$RomVariant'-'$RomVersion'-'$PreviousOTAHash'-to-'$OTAHash'-'UNOFFICIAL'-'$1'-signed.zip'
    else
      NewOTAName=$RomVariant'-'$RomVersion'-'$PreviousOTAHash'-to-'$OTAHash'-'UNOFFICIAL'-'$1'.zip'
    fi
  else
    # Can I haz moar argument?
    HandleError 211
  fi
}

GetOutputZip() {
  # Check we've been given first argument (device)
  if ! [[ -z $1 ]]; then
    # Check device output folder exists
    if [[ -e $SourceTreeLoc/out/target/product/$1 ]]; then
                # find *.zip in the root of the output directory, reverse ordered by date modified, take the top line
      OutputZip=$(find $SourceTreeLoc/out/target/product/$1/ -maxdepth 1 -name '*.zip' -printf "%T+\t%p\n" | sort -r | cut -f 2- | head -n 1)
                #                                                                                                                  ^^^^^^^^^ take top line
                #                                                                                                      ^^^^^^^^^ take the second field after the tab (chop date modified off front)
                #                                                                                            ^^^^^^^ sort numerically in reverse
                #                                                                      ^^^^^^^^^^^^^^^^^^^ print as "2017-01-02+18:45:41.7878729150 android/system/out/target/product/angler/cm_angler-ota-a0db5d5712.zip"
                #                                                        ^^^^^^^^^^^^^ All zip files
                #                                            ^^^^^^^^^^^ Only files in the root of the directory
      # If find found a zip, output it
      if [[ -z $OutputZip ]]; then
        HandleError 212
      fi
    else
      # The device output folder doesn't exist
      HandleError 213
    fi
  else
    # Not given device argument
    HandleError 214
  fi
}

GetLocalMD5SUM() {
  # Check we've been given first argument (OutputZip)
  if ! [[ -z $1 ]]; then
    # Check output zip exists
    if [[ -e $1 ]]; then
      MD5SUM=$(md5sum $1)
    else
      # Output file doesn't exist
      HandleError 215
    fi
  else
    # First argument not given
    HandleError 216
  fi
}

UploadZipAndRename() {
  # Check we've been given first argument (Absolute path to zip)
  if ! [[ -z $1 ]]; then
    # Check we've been given second argument (Name of zip file)
    if ! [[ -z $2 ]]; then
      LocalZipPath=$1
      LocalZipName=$2
      ssh $SSHUser@$SSHHost -p $SSHPort "mkdir -p $SSHDirectory/$Device"
      # Upload Zip file to nameofzipfile.zip.part
      scp -P $SSHPort $LocalZipPath $SSHUser@$SSHHost:"$SSHDirectory/$Device/$LocalZipName.part"
      # Move nameofzipfile.zip.part to nameofzipfile
      ssh $SSHUser@$SSHHost -p $SSHPort "mv $SSHDirectory/$Device/$LocalZipName.part $SSHDirectory/$Device/$LocalZipName"
    else
      # Second argument not given
      HandleError 217
    fi
  else
    # First argument not given
    HandleError 218
fi
}

UploadMD5() {
  # Check for first argument (Absolute path to zip file)
  if ! [[ -z $1 ]]; then
    # Check for second argument (Name of zip file)
    if ! [[ -z $2 ]]; then
      LocalZipPath=$1
      LocalZipName=$2
      ssh $SSHUser@$SSHHost -p $SSHPort "mkdir -p $SSHDirectory/$Device"
      scp -P $SSHPort $LocalZipPath.md5sum $SSHUser@$SSHHost:"$SSHDirectory/$Device/$LocalZipName.md5sum"
    else
      # Second argument not given
      HandleError 219
    fi
  else
    # First argument given
    HandleError 220
fi
}

KillJack() {
  # Kill the jack-server so we can restart with more RAM
  cd $SourceTreeLoc
  ./prebuilts/sdk/tools/jack-admin list-server && ./prebuilts/sdk/tools/jack-admin kill-server
}

ResuscitateJack() {
  # Bring Jack back with more RAM
  cd $SourceTreeLoc
  export JACK_SERVER_VM_ARGUMENTS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx$JackRAM"
  ./prebuilts/sdk/tools/jack-admin start-server
}

TrapCtrlC() {
  LogMain "Ctrl-C caught. Beginning clean up and ending..."
  echo "We've got your message, give us a second to clean up and we'll hand back control"
  LogMain "We leave no men or women behind. We're taking Jack and Jill with us"
  # Oops, we killed him
  LogCommandMainErrors "KillJack"
  LogMain "Cleanup finished. Now we quit."
  echo "All done. See you in the afterlife"
  HandleError 245
}

AddRomToUpdater() {
  LogMain "\tAdding ROM into lineageos_updater app"
  curl -H "Apikey: $LineageUpdaterApikey" -H "Content-Type: application/json" -X POST -d '{ "device": "'"$Device"'", "filename": "'"$NewName"'", "md5sum": "'"${MD5SUM:0:32}"'", "romtype": "unofficial", "url": "'"$DownloadBaseURL/$Device/$NewName"'", "version": "'"$RomVersion"'" }' "$LineageUpdaterURL/api/v1/add_build"
}

GetCurrentOTAHash() {
  if [[ $SignBuilds = true ]]; then
    OTAHash=$(ls -t $SourceTreeLoc/out/target/product/$Device/obj/PACKAGING/target_files_intermediates | head -1 | sed -nr 's/lineage_'"$Device"'-target_files-([0-9a-f]{10})-signed.zip/\1/p')
  else
    OTAHash=$(ls -t $SourceTreeLoc/out/target/product/$Device/obj/PACKAGING/target_files_intermediates | head -1 | sed -nr 's/lineage_'"$Device"'-target_files-([0-9a-f]{10}).zip/\1/p')
  fi
}

GetPreviousOTAHash() {
  if [[ $SignBuilds = true ]]; then
    PreviousOTAHash=$(ls -t $SourceTreeLoc/out/target/product/$Device/obj/PACKAGING/target_files_intermediates -I "*$OTAHash*" | head -1 | sed -nr 's/lineage_'"$Device"'-target_files-([0-9a-f]{10})-signed.zip/\1/p')
  else
    PreviousOTAHash=$(ls -t $SourceTreeLoc/out/target/product/$Device/obj/PACKAGING/target_files_intermediates -I "*$OTAHash*" | head -1 | sed -nr 's/lineage_'"$Device"'-target_files-([0-9a-f]{10}).zip/\1/p')
  fi
}

CleanupAfterBuild() {
  LogMain "\tDelete $NewName"
  LogCommandMainErrors "rm $NewOutputZip"
  LogMain "\tDelete $NewName.md5sum"
  LogCommandMainErrors "rm $NewOutputZip.md5sum"

  if [[ $IncrementalOTA = true ]]; then
    GetCurrentOTAHash
    if [[ $SkipOTA = false ]]; then
      GetNewOTAName $Device
      LogMain "\tDelete $NewOTAName"
      LogCommandMainErrors "rm $SourceTreeLoc/out/target/product/$Device/$NewOTAName"
      LogMain "\tDelete $NewOTAName.md5sum"
      LogCommandMainErrors "rm $SourceTreeLoc/out/target/product/$Device/$NewOTAName.md5sum"
    fi

    if [[ -d "$SourceTreeLoc/out/target/product/$Device/obj/PACKAGING" ]]; then
      if [[ -d "$SourceTreeLoc/out/target/product/$Device/obj/PACKAGING/apkcerts_intermediates" ]]; then
        LogMain "\tCleanup apkcerts_intermediates"
        LogMain $(find $SourceTreeLoc/out/target/product/$Device/obj/PACKAGING/apkcerts_intermediates/* -maxdepth 0 -not -name "*$OTAHash*" -exec rm -r {} \;)
      fi
      if [[ -d "$SourceTreeLoc/out/target/product/$Device/obj/PACKAGING/target_files_intermediates" ]]; then
        LogMain "\tCleanup target_files_intermediates"
        LogMain $(find $SourceTreeLoc/out/target/product/$Device/obj/PACKAGING/target_files_intermediates/* -maxdepth 0 -not -name "*$OTAHash*" -exec rm -r {} \;)
      fi
    fi
  else
    if [[ -d "$SourceTreeLoc/out/target/product/$Device/obj/PACKAGING" ]]; then
      if [[ -d "$SourceTreeLoc/out/target/product/$Device/obj/PACKAGING/apkcerts_intermediates" ]]; then
        LogMain "\tCleanup apkcerts_intermediates"
        LogCommandMainErrors "rm $SourceTreeLoc/out/target/product/$Device/obj/PACKAGING/apkcerts_intermediates/*"
      fi
      if [[ -d "$SourceTreeLoc/out/target/product/$Device/obj/PACKAGING/target_files_intermediates" ]]; then
        LogMain "\tCleanup target_files_intermediates"
        LogCommandMainErrors "rm -r $SourceTreeLoc/out/target/product/$Device/obj/PACKAGING/target_files_intermediates/*"
      fi
    fi
  fi
}

SignBuild() {
  if ! [[ -z $1 ]]; then
    OTAHash=$(ls -t $SourceTreeLoc/out/target/product/$1/obj/PACKAGING/target_files_intermediates | head -1 | sed -nr 's/lineage_'"$1"'-target_files-([0-9a-f]{10}).zip/\1/p')
    if [[ -f $SourceTreeLoc/out/target/product/$1/ota_script_path ]]; then
      OtaScriptPath=$(cat $SourceTreeLoc/out/target/product/$1/ota_script_path)
    else
      OtaScriptPath="build/tools/releasetools/ota_from_target_files"
    fi
    LogCommandMake "build/tools/releasetools/sign_target_files_apks -o -d $SigningKeysPath $SourceTreeLoc/out/target/product/$1/obj/PACKAGING/target_files_intermediates/lineage_$1-target_files-$OTAHash.zip $SourceTreeLoc/out/target/product/$1/obj/PACKAGING/target_files_intermediates/lineage_$1-target_files-$OTAHash-signed.zip"
    LogCommandMake "$OtaScriptPath -k $SigningKeysPath/releasekey --block --backup=true $SourceTreeLoc/out/target/product/$1/obj/PACKAGING/target_files_intermediates/lineage_$1-target_files-$OTAHash-signed.zip $SourceTreeLoc/out/target/product/$1/lineage_$1-ota-$OTAHash.zip"
    LogCommandMake "build/tools/releasetools/sign_zip.py -k $SigningKeysPath/releasekey $SourceTreeLoc/out/target/product/$1/lineage_$1-ota-$OTAHash.zip $SourceTreeLoc/out/target/product/$1/lineage_$1-ota-$OTAHash-signed.zip"
    LogCommandMake "rm $SourceTreeLoc/out/target/product/$1/lineage_$1-ota-$OTAHash.zip"
  else
    # First argument given
    HandleError 220
  fi
}

RemoveBuilds() {
  FileToDelete="$RomVariant-$RomVersion-$DeleteOlderThan-UNOFFICIAL-$Device.zip"
  # delete old build from lineageos updater
  if [[ $LineageUpdater = true ]]; then
    # delete the build from the updater
    curl -H "Apikey: $LineageUpdaterApikey" -X DELETE $LineageUpdaterURL/api/v1/$FileToDelete > /dev/null 2>&1
    # purge cache to remove it from the listing
    curl -H "Apikey: $LineageUpdaterApikey" -X POST $LineageUpdaterURL/api/v1/purgecache > /dev/null 2>&1
  fi

  # delete builds from remote server
  if [[ $SSHUpload = true ]]; then
    ssh $SSHUser@$SSHHost -p $SSHPort "rm $SSHDirectory/$Device/$FileToDelete*" > /dev/null 2>&1
  fi

  if [[ -f $LogFileLoc/archives/$RomVariant-$RomVersion-$DeleteOlderThan-UNOFFICIAL.tar.gz ]]; then
    rm $LogFileLoc/archives/$RomVariant-$RomVersion-$DeleteOlderThan-UNOFFICIAL.tar.gz
  fi
}
