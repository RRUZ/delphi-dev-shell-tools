![](https://dl.dropboxusercontent.com/u/12733424/github/delphi-dev-shell-tools/logo.png)The <strong>Delphi Dev. Shell Tools</strong> is a  Windows shell extension with useful tasks for Object Pascal Developers (Delphi, Free Pascal).

## Features ##
<lu>
 <li>Supports Delphi 5, 6, 7, 2005, BDS/Turbo 2006 and RAD Studio 2007, 2009, 2010, XE, XE2, XE3, XE4, XE5, XE6, XE7 Appmethod 1.13, Lazarus v1.0.1.3</li>
 <li>Works in Windows 8/7/Vista/XP. (x86 and x64 versions)</li>
</lu>
[![](https://dl.dropboxusercontent.com/u/12733424/Images/followrruz.png)](https://twitter.com/RRUZ)

---



## Important ##
> We detect a conflict with the <strong>AVG Antivirus 2014 Shell extension</strong> . This cause which the <strong>Delphi Dev. Shell Tools</strong>  menu is not show. To fix this you must disable and enable  the  AVG Antivirus Shell extension.


Please follow the next steps to fix.

  1. Download and Run the [ShellExView](http://www.nirsoft.net/utils/shexview.html) utility
  1. Locate the AVG Antivirus Shell extensions and disable it as is shown in the below image.
  1. log-off and log-on or restart Windows
  1. Test the **Delphi Dev. Shell Tools** extension
  1. Run the **ShellExView** utility again and enable the **AVG Antivirus Shell** extensions
  1. log-off and log-on or restart Windows
  1. Now both shell extensions should work normally.


![](https://dl.dropboxusercontent.com/u/12733424/Blog/DevShell/AVG.png)


## Installer ##

[Download the installer - Mirror 1](https://goo.gl/RJanwS)

[Download the installer - Mirror 2](https://docs.google.com/uc?export=download&id=0B7KzPH8HQCZNQmRnWUpxbEtaT3c)


---

### Common Tasks for .pas, .dpr, .inc, .pp, .dpk, . dproj, .dfm, .fmx, .rc, .lpk, lpr, .lpi extensions ###

![](https://dl.dropboxusercontent.com/u/12733424/Blog/DevShell/Images/common_tasks.png)

<lu>
 <li><strong>Copy File Path to the clipboard</strong>  : Copy the path of the selected file to the clipboard.</li>
 <li><strong>Copy Full FileName to the clipboard</strong>  : Copy the full file-name (Path + Name) of the selected file to the clipboard.</li>
 <li><strong>Copy FileName using URL format to the clipboard</strong>  : Copy the full file-name (Path + Name) of the selected file to the clipboard using the Internet Path format</li>
 <li><strong>Copy FileName using UNC format to the clipboard</strong>  : Copy the full file-name (Path + Name) of the selected file to the clipboard UNC format</li>
 <li><strong>Copy file content to the clipboard</strong>  : Copy the content of the selected file to the clipboard.</li>
 <li><strong>Open In Notepad</strong>  : Open the selected file in the notepad editor.</li>
 <li><strong>Open In Default text file editor</strong>  : Open the selected file in the default text editor installed.</li>
 <li><strong>Open In associated text editor</strong>  : Open the selected file in the associated text editor.</li>
 <li><strong>Open Command Line here</strong>  : Open the cmd.exe application in the folder of the selected file.</li>
 <li><strong>Open Command Line here as Administrator</strong>  : Open the cmd.exe application in the folder of the selected file as Administrator.</li>
</lu>

---

![](https://dl.dropboxusercontent.com/u/12733424/Blog/DevShell/Images/CmdRAD.png)
> <li><strong>Open RAD Studio Command prompt here</strong>  : Open the RAD Studio Command prompt (of any installed Delphi version) in the folder of the selected file</li>

---

![](https://dl.dropboxusercontent.com/u/12733424/Blog/DevShell/Images/pas_menu.png)
> <li><strong>Open with Delphi(N)</strong>  : Open the selected file with any version of Delphi or Rad Studio installed</li>

---

## Specific Tasks for .dpr, .dproj files (Rad Studio Projects), .groupproj (Group Projects) ##
![](https://dl.dropboxusercontent.com/u/12733424/Blog/DevShell/Images/dproj_menu_new.png)

<lu>
 <li><strong>Run MSBuild (Default Settings)</strong> : Execute MSBuild using the default settings of the selected .dproj file</li>
 <li><strong>Run MSBuild With .. </strong>: Execute MSBuild using any of the platforms and targets detected in the selected .dproj file</li>
 <li><strong>MSBuild</strong>: Allow to select and execute the MSBuild tool (associated to any version of the RAD Studio installed) using the default configuration of the project</li>
</lu>

---

## Specific Tasks for .lpi, .lpk files (Lazarus Projects and packages) ##
![](https://dl.dropboxusercontent.com/u/12733424/Blog/DevShell/Images/lazarus_menu.png)
<lu>
 <li><strong>Open with Lazarus IDE</strong>: Allow to open the selected file with the installed Lazarus IDE</li>
 <li><strong>Build with lazbuild</strong>: Allow to build a project or package using the lazbuild tool</li>
</lu>

---

## Calculate CheckSum ##
![](https://dl.dropboxusercontent.com/u/12733424/Blog/DevShell/Images/checksum_menu.png)

This option allow to calculate the checksum for the selected file, this option supports  <strong>CRC32, MD4, MD5, SHA1, SHA256, SHA384, SHA512</strong>

![](https://dl.dropboxusercontent.com/u/12733424/Blog/DevShell/Images/checksum.png)

---

## Support for customs extensions ##

The shell extension can be customized to support additional  file extensions in some tasks.

![](https://dl.dropboxusercontent.com/u/12733424/Blog/DevShell/Images/settings1.png)

## Support for register customs applications ##
![](https://dl.dropboxusercontent.com/u/12733424/Blog/DevShell/Images/Custom_Tools.png)

This option allows you register a script which will be associated  to any specified extension.

