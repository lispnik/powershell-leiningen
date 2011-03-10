#Requires -Version 2.0

function Lein {
  <#
  .Synopsis
  .Description
  .Parameter Command
  .Parameter LeinVersion
  .Parameter LeinJar
  .Parameter LeinUrl
  .Parameter LeinHome
  .Parameter ClojureVersion
  .Parameter ClojureJar
  .Parameter JavaCommand
  .Parameter JavaOptions
  .Parameter JLine
  .Notes
  .Example
  .Example
  #>
  param(
    [Parameter(Mandatory = $true, Position = 0)] $Command = "help",
    [string] $LeinVersion = "1.4.2",
    [string] $LeinJar = "$env:USERPROFILE\.m2\repository\leiningen\leiningen\$LeinVersion\leiningen-$LeinVersion-standalone.jar",
    [string] $LeinUrl = "https://github.com/downloads/technomancy/leiningen/leiningen-$LeinVersion-standalone.jar",
    [string] $LeinHome = 
      (& {if ($env:LEIN_HOME) {
           $env:LEIN_HOME
         } else {
           Join-Path $env:USERPROFILE ".lein"
         }}),
    [string] $ClojureVersion = "1.2.0",
    [string] $ClojureJar = "$env:USERPROFILE\.m2\repository\org\clojure\clojure\$ClojureVersion\clojure-$ClojureVersion.jar",
    [string] $JavaCommand = 
      (& {if ($env:JAVA_CMD) {
            $env:JAVA_CMD
          } else {
            "java"
          }}),
    [string] $JavaOptions = "",
    [string] $JLine = "jline.ConsoleRunner",
    [Parameter(ValueFromRemainingArguments = $true)] $args
  )
  Write-Verbose $LeinJar
  Write-Verbose $LeinVersion
  Write-Verbose $LeinUrl
  Write-Verbose $LeinHome
  Write-Verbose $ClojureVersion
  Write-Verbose $ClojureJar
  Write-Verbose $JavaCommand
  Write-Verbose $JavaOptions
  Write-Verbose $JLine
  $leinPlugins = (Get-LeinPlugins (Join-Path $LeinHome plugins))
  $userPlugins = (Get-LeinPlugins lib\dev)
  $classpath =  @($leinPlugins) `
    + @($userPlugins) `
    + , "src" `
    + ($env:CLASSPATH -split ";")
  if ($false) {
    # FIXME: Source checkout
  } else {
    if (-not (Test-Path -PathType Leaf $LeinJar) -and ($Command -ne "self-install")) {
      Write-Host "Leiningen is not installed. Please run `"lein self-install`""
      return
    }
    $classpath = , $LeinJar + $classpath
  }
  switch ($Command) {
    "self-install" {
      Download $LeinUrl $LeinJar
      return
    }
    default {
      if (("interactive", "int", "repl" -contains $Command) -and (-not $env:INSIDE_EMACS) -and ($env:TERM -ne 'dumb') -and ($command -ne 'swank')) {
        $jlineClass = $JLine
      } else {
        $jlineClass = ''
      }
      $expr = "(use 'leiningen.core)(-main " `
        + ((, $Command + $args | ? {$_} | % {$_ -replace '"', '\"'} | % {"\`"$_\`""}) -join ' ') +  ")"
      Write-Verbose $expr
      & $JavaCommand `
        "-Xbootclasspath/a:$ClojureJar" `
        -client `
        $JavaOptions `
        -cp ($classpath -join ';') `
        "-Dleiningen.version=$LeinVersion" `
        $jlineClass clojure.main -e $expr
      break
    }
  }
}

function Get-LeinPlugins {
  param([string] $Path)
  if (Test-Path -PathType Container $Path) {
    Get-ChildItem $Path\* -Include *.jar 
  }
}

function Get-ProjectPath {
  param([string] $Path)
  if ($Path) { 
    $file = Join-Path $Path "project.clj"
    if (Test-Path -PathType Leaf $file) {
      Resolve-Path $file
    } else {
      Get-ProjectPath (Split-Path $Path)
    }
  }
}

function Download {
  param([string] $Url, [string] $Path)
  $directory = (Split-Path $Path)
  if (-not (Test-Path -PathType Container $directory)) {
    New-Item -Force -ItemType Directory -Path $directory | Out-Null
  }
  $client = New-Object System.Net.WebClient
  $client.DownloadFile($Url, $Path)
}

Export-ModuleMember -Function Lein
