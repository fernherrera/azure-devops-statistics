function Write-ProgressHelper {
	param (
      [int]$ProcessId = 0,
      [int]$Steps,
	    [int]$StepNumber,
	    [string]$Message = "Progress"
	)

  $PercentageComplete = 0
  $PercentageComplete = ($StepNumber / $Steps) * 100
  $Status = ($StepNumber / $Steps).ToString("P1")
 
  # Make sure percentage is correct
  if ($PercentageComplete -gt 100) { $PercentageComplete = 100 }

  Write-Debug "PID: $ProcessId - Current Step: $StepNumber - Total Steps: $Steps - PercentageComplete: $PercentageComplete"
	Write-Progress -Id $ProcessId -Activity $Message -Status $Status -PercentComplete $PercentageComplete
}

function Write-JsonFile {
  [CmdletBinding()]
	param (
		[PSCustomObject]$Data,
		[int]$Depth = 5,
		[string]$Path,
		[string]$Filename
	)
  begin { 
    $outputFile = (Join-Path $Path $Filename)
    Write-Debug "Writing JSON file: $($outputFile)" 
  }
  process {
    $Data | ConvertTo-Json -Depth $Depth | Out-File -FilePath $outputFile
  }
  end { }

}

function Test-Debug {
  [CmdletBinding()]
  param (
      [Parameter(Mandatory = $false)]
      [switch]$IgnorePSBoundParameters
      ,
      [Parameter(Mandatory = $false)]
      [switch]$IgnoreDebugPreference
      ,
      [Parameter(Mandatory = $false)]
      [switch]$IgnorePSDebugContext
  )
  process {
      ((-not $IgnoreDebugPreference.IsPresent) -and ($DebugPreference -ne "SilentlyContinue")) -or
      ((-not $IgnorePSBoundParameters.IsPresent) -and $PSBoundParameters.Debug.IsPresent) -or
      ((-not $IgnorePSDebugContext.IsPresent) -and ($PSDebugContext))
  }
}

function Split-Array {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [String[]] $InputObject
        ,
        [ValidateRange(1, [int]::MaxValue)]
        [int] $Size = 10
    )
    begin   { $items = New-Object System.Collections.Generic.List[object] }
    process { $items.AddRange($InputObject) }
    end {
      $chunkCount = [Math]::Floor($items.Count / $Size)
      foreach ($chunkNdx in 0..($chunkCount-1)) {
        , $items.GetRange($chunkNdx * $Size, $Size).ToArray()
      }
      if ($chunkCount * $Size -lt $items.Count) {
        , $items.GetRange($chunkCount * $Size, $items.Count - $chunkCount * $Size).ToArray()
      }
    }
}

function Get-BatchRanges {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [int]$TotalItems
    ,
    [Parameter(Mandatory)]
    [ValidateRange(1, [int]::MaxValue)]
    [int]$BatchSize
    ,
    [Parameter()]
    [switch]$ZeroIndex
  )
  begin { $batches = @() }
  process {
    $batchCount = [Math]::Ceiling($TotalItems / $BatchSize)
    $idxStart   = ($ZeroIndex) ? 0 : 1
    $batchCount = ($ZeroIndex -and $batchCount -gt 0) ? ($batchCount - 1) : $batchCount

    foreach ($batchIdx in ($idxStart)..($batchCount))
    {
      $rangeLow  = ($batchIdx * $batchSize)
      $rangeHigh = $batchSize

      if ($batchIdx -eq ($batchCount))
      {
          $rangeHigh = ($TotalItems - $rangeLow)
      }

      $batches += [PSCustomObject]@{
        idx   = $batchIdx
        range = @(($rangeLow), ($rangeHigh))
        count = $TotalItems
      }
    }
  }
  end { return $batches }
}
