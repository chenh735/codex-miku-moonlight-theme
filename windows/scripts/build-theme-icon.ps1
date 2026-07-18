[CmdletBinding()]
param(
  [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
  $OutputDirectory = Join-Path (Split-Path -Parent $PSScriptRoot) 'assets'
}

$sizes = @(16, 20, 24, 32, 48, 64, 128, 256)
$pngPath = Join-Path $OutputDirectory 'miku-music-mark.png'
$icoPath = Join-Path $OutputDirectory 'miku-music-mark.ico'

function New-RoundedRectanglePath {
  param(
    [Parameter(Mandatory = $true)][System.Drawing.RectangleF]$Bounds,
    [Parameter(Mandatory = $true)][single]$Radius
  )

  $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $diameter = $Radius * 2
  $path.AddArc($Bounds.Left, $Bounds.Top, $diameter, $diameter, 180, 90)
  $path.AddArc($Bounds.Right - $diameter, $Bounds.Top, $diameter, $diameter, 270, 90)
  $path.AddArc($Bounds.Right - $diameter, $Bounds.Bottom - $diameter, $diameter, $diameter, 0, 90)
  $path.AddArc($Bounds.Left, $Bounds.Bottom - $diameter, $diameter, $diameter, 90, 90)
  $path.CloseFigure()
  return $path
}

function New-MikuIconPng {
  param([Parameter(Mandatory = $true)][int]$Size)

  $bitmap = [System.Drawing.Bitmap]::new(
    $Size,
    $Size,
    [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
  )
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  try {
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.Clear([System.Drawing.Color]::Transparent)

    $bounds = [System.Drawing.RectangleF]::new(0, 0, $Size, $Size)
    $backgroundPath = New-RoundedRectanglePath -Bounds $bounds -Radius ([single]($Size * 0.23))
    $background = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
      $bounds,
      [System.Drawing.Color]::FromArgb(255, 13, 28, 76),
      [System.Drawing.Color]::FromArgb(255, 91, 55, 157),
      45
    )
    try {
      $graphics.FillPath($background, $backgroundPath)
    } finally {
      $background.Dispose()
      $backgroundPath.Dispose()
    }

    $glowBrush = [System.Drawing.SolidBrush]::new(
      [System.Drawing.Color]::FromArgb(44, 91, 235, 224)
    )
    try {
      $graphics.FillEllipse(
        $glowBrush,
        [single]($Size * 0.13),
        [single]($Size * 0.17),
        [single]($Size * 0.72),
        [single]($Size * 0.68)
      )
    } finally {
      $glowBrush.Dispose()
    }

    $mPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $mPath.AddLines([System.Drawing.PointF[]]@(
      [System.Drawing.PointF]::new([single]($Size * 0.23), [single]($Size * 0.72)),
      [System.Drawing.PointF]::new([single]($Size * 0.31), [single]($Size * 0.30)),
      [System.Drawing.PointF]::new([single]($Size * 0.50), [single]($Size * 0.55)),
      [System.Drawing.PointF]::new([single]($Size * 0.67), [single]($Size * 0.30)),
      [System.Drawing.PointF]::new([single]($Size * 0.75), [single]($Size * 0.72))
    ))
    $mPen = [System.Drawing.Pen]::new(
      [System.Drawing.Color]::FromArgb(255, 91, 235, 224),
      [single][Math]::Max(1.5, $Size * 0.105)
    )
    $mPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $mPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $mPen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    try {
      $graphics.DrawPath($mPen, $mPath)
    } finally {
      $mPen.Dispose()
      $mPath.Dispose()
    }

    $notePen = [System.Drawing.Pen]::new(
      [System.Drawing.Color]::White,
      [single][Math]::Max(1, $Size * 0.045)
    )
    $notePen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $notePen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $noteBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
    try {
      $graphics.DrawLine(
        $notePen,
        [single]($Size * 0.70), [single]($Size * 0.31),
        [single]($Size * 0.70), [single]($Size * 0.58)
      )
      $graphics.DrawLine(
        $notePen,
        [single]($Size * 0.70), [single]($Size * 0.31),
        [single]($Size * 0.82), [single]($Size * 0.27)
      )
      $graphics.FillEllipse(
        $noteBrush,
        [single]($Size * 0.59), [single]($Size * 0.54),
        [single]($Size * 0.15), [single]($Size * 0.11)
      )

      $spark = [System.Drawing.Pen]::new(
        [System.Drawing.Color]::FromArgb(235, 220, 255, 255),
        [single][Math]::Max(1, $Size * 0.018)
      )
      $spark.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
      $spark.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
      try {
        $graphics.DrawLine(
          $spark,
          [single]($Size * 0.80), [single]($Size * 0.13),
          [single]($Size * 0.80), [single]($Size * 0.24)
        )
        $graphics.DrawLine(
          $spark,
          [single]($Size * 0.745), [single]($Size * 0.185),
          [single]($Size * 0.855), [single]($Size * 0.185)
        )
      } finally {
        $spark.Dispose()
      }
    } finally {
      $notePen.Dispose()
      $noteBrush.Dispose()
    }

    $memory = [System.IO.MemoryStream]::new()
    try {
      $bitmap.Save($memory, [System.Drawing.Imaging.ImageFormat]::Png)
      $bytes = $memory.ToArray()
      return ,$bytes
    } finally {
      $memory.Dispose()
    }
  } finally {
    $graphics.Dispose()
    $bitmap.Dispose()
  }
}

[System.IO.Directory]::CreateDirectory([System.IO.Path]::GetFullPath($OutputDirectory)) | Out-Null
$referencePng = New-MikuIconPng -Size 1024
[System.IO.File]::WriteAllBytes($pngPath, $referencePng)

$frames = @(
  $sizes | ForEach-Object {
    [pscustomobject]@{
      Size = $_
      Bytes = New-MikuIconPng -Size $_
    }
  }
)

$stream = [System.IO.File]::Open(
  $icoPath,
  [System.IO.FileMode]::Create,
  [System.IO.FileAccess]::Write
)
$writer = [System.IO.BinaryWriter]::new($stream)
try {
  $writer.Write([uint16]0)
  $writer.Write([uint16]1)
  $writer.Write([uint16]$frames.Count)

  $offset = 6 + (16 * $frames.Count)
  foreach ($frame in $frames) {
    $dimension = if ($frame.Size -eq 256) { 0 } else { $frame.Size }
    $writer.Write([byte]$dimension)
    $writer.Write([byte]$dimension)
    $writer.Write([byte]0)
    $writer.Write([byte]0)
    $writer.Write([uint16]1)
    $writer.Write([uint16]32)
    $writer.Write([uint32]$frame.Bytes.Length)
    $writer.Write([uint32]$offset)
    $offset += $frame.Bytes.Length
  }

  foreach ($frame in $frames) {
    $writer.Write([byte[]]$frame.Bytes)
  }
} finally {
  $writer.Dispose()
  $stream.Dispose()
}

Write-Host "Generated $pngPath and $icoPath"
