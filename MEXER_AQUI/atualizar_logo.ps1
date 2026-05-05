$ErrorActionPreference = 'Stop'

$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$source = Join-Path $root 'Tdetalmax.png'

if (-not (Test-Path -LiteralPath $source)) {
  throw "Arquivo Tdetalmax.png nao encontrado na raiz do projeto."
}

Add-Type -AssemblyName System.Drawing

$targets = @(
  @{ Path = 'android\app\src\main\res\mipmap-mdpi\ic_launcher.png'; Size = 48 },
  @{ Path = 'android\app\src\main\res\mipmap-hdpi\ic_launcher.png'; Size = 72 },
  @{ Path = 'android\app\src\main\res\mipmap-xhdpi\ic_launcher.png'; Size = 96 },
  @{ Path = 'android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png'; Size = 144 },
  @{ Path = 'android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png'; Size = 192 },
  @{ Path = 'web\favicon.png'; Size = 32 },
  @{ Path = 'web\icons\Icon-192.png'; Size = 192 },
  @{ Path = 'web\icons\Icon-maskable-192.png'; Size = 192 },
  @{ Path = 'web\icons\Icon-512.png'; Size = 512 },
  @{ Path = 'web\icons\Icon-maskable-512.png'; Size = 512 }
)

$image = [System.Drawing.Image]::FromFile($source)

try {
  foreach ($target in $targets) {
    $size = [int]$target.Size
    $destination = Join-Path $root $target.Path
    $folder = Split-Path -Parent $destination

    if (-not (Test-Path -LiteralPath $folder)) {
      New-Item -ItemType Directory -Path $folder | Out-Null
    }

    $bitmap = New-Object System.Drawing.Bitmap $size, $size

    try {
      $graphics = [System.Drawing.Graphics]::FromImage($bitmap)

      try {
        $graphics.Clear([System.Drawing.Color]::Transparent)
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.DrawImage($image, 0, 0, $size, $size)
      } finally {
        $graphics.Dispose()
      }

      $bitmap.Save($destination, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
      $bitmap.Dispose()
    }
  }
} finally {
  $image.Dispose()
}

Write-Host 'Logo atualizado nos icones do Android e da web.'
