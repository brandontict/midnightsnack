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
  if [[ -z UNOFFICIAL ]]; then
    HandleError 237; fi
  if [[ $SSHUpload = true ]]; then
    if [[ -z $SSHHost ]]; then
      HandleError 234; fi
    if [[ -z $SSHUser ]]; then
      HandleError 235; fi
    if [[ -z $SSHPort ]]; then
      HandleError 236; fi
    if [[ -z $SSHDirectory ]]; then
      HandleError 237; fi
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
      LogMain 'Stopping due to error'
      exit $ErrorNum
    fi
  else
    # We weren't passed an error code, so exit
    LogMain "Unspecified Error" "a"
    LogMain 'Stopping due to error' "a"
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
      echo $1 >  "$MakeLogFile" 2>&1
                     #          ^^^^ redirect errors too
    # Otherwise, append
    else
      echo $1 >>  "$MakeLogFile" 2>&1
    fi
  else
    echo $1 >>  "$MakeLogFile" 2>&1
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
      echo $1 > "$MainLogFile" 2>&1
    # Otherwise, append
    else
      echo $1 >> "$MainLogFile" 2>&1
    fi
  else
    echo $1 >> "$MainLogFile" 2>&1
  fi;
}

SupperLunch() {
  # Check we've been given argument 1 (device)
  if ! [[ -z $1 ]]; then
    # Run this from source directory...
    cd $SourceTreeLoc
    # ... for envsetup.sh to work
    LogCommandMainErrors "source build/envsetup.sh"
    LunchCommand=$RomVariant'_'$1'-'$RomBuildType
    LogCommandMake "lunch $LunchCommand";
  else
    # Gimme more arguments
    HandleError 214
  fi
}

SupperMake() {
  LogCommandMake "mka otapackage"
  # mka outputs "*** make completed successfully (MM:SS) ***" if successful
  # Check the log for this to make sure we're good to continue
  if grep -q "make completed successfully" $MakeLogFile; then
    return 0
  else
    # Make failed
    HandleError 200
  fi
}

GetBuildDate() {
  if [[ $BuildTomorrow = true ]]; then
      # Get YYYYMMDD for tomorrow
      echo $(date --date="+1 day" +%Y%m%d);
  else
    # Get YYYYMMDD for today
    echo $(date +%Y%m%d);
  fi
}

GetNewName() {
  # Check we've been given the first argument (device)
  if ! [[ -z $1 ]]; then
    NewName=$RomVariant'-'$RomVersion'-'$BuildDate'-'UNOFFICIAL'-'$1'.zip'
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
      if ! [[ -z $OutputZip ]]; then
        echo $OutputZip
      else
        # Find didn't find a zip ($OutputZip was zero length)
        HandleError 213
      fi
    else
      # The device output folder doesn't exist
      HandleError 212
    fi
  else
    # Not given device argument
    HandleError 213
  fi
}

GetLocalMD5SUM() {
  # Check we've been given first argument (OutputZip)
  if ! [[ -z $1 ]]; then
    # Check output zip exists
    if [[ -e $1 ]]; then
      MD5SUM=$(md5sum $1)
      echo $MD5SUM
    else
      # Output file doesn't exist
      HandleError 214
    fi
  else
    # First argument not given
    HandleError 215
  fi
}

UploadZipAndRename() {
  # Check we've been given first argument (Absolute path to zip)
  if ! [[ -z $1 ]]; then
    # Check we've been given second argument (Name of zip file)
    if ! [[ -z $2 ]]; then
      LocalZipPath=$1
      LocalZipName=$2
      # Upload Zip file to nameofzipfile.zip.part
      scp $SSHUser@$SSHHost -P $SSHPort $LocalZipPath $SSHUser@$SSHHost:"$SSHDirectory/$LocalZipName.part"
      # Move nameofzipfile.zip.part to nameofzipfile
      ssh $SSHUser@$SSHHost -P $SSHPort mv $SSHDirectory/$LocalZipName.part $SSHDirectory/$LocalZipName
    else
      # Second argument not given
      HandleError 216
    fi
  else
    # First argument not given
    HandleError 217
fi
}

UploadMD5() {
  # Check for first argument (Absolute path to zip file)
  if ! [[ -z $1 ]]; then
    # Check for second argument (Name of zip file)
    if ! [[ -z $2 ]]; then
      LocalZipPath=$1
      LocalZipName=$2
      scp -P $SSHPort $LocalZipPath.md5sum $SSHUser@$SSHHost:"$SSHDirectory/$LocalZipName.md5sum"
    else
      # Second argument not given
      HandleError 218
    fi
  else
    # First argument given
    HandleError 219
fi
}
