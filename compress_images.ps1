Add-Type -AssemblyName System.Drawing

$imageFolder = "c:\Users\MC\Desktop\mo_V_24\mojohrti_pro\assets\images\categories"
$files = Get-ChildItem -Path $imageFolder -Include *.jpg,*.jpeg,*.png -Recurse

foreach ($file in $files) {
    try {
        $img = [System.Drawing.Image]::FromFile($file.FullName)
        $originalSize = (Get-Item $file.FullName).Length
        
        $maxWidth = 600 # 600px is perfect for mobile category cards
        $isJpg = ($file.Extension -match "\.jpe?g$")
        
        if ($img.Width -gt $maxWidth -or $originalSize -gt 500000) {
            $ratio = $maxWidth / $img.Width
            if ($ratio -gt 1) { $ratio = 1 } # Don't upscale
            
            $newWidth = [math]::Max(1, [int]($img.Width * $ratio))
            $newHeight = [math]::Max(1, [int]($img.Height * $ratio))
            
            $newImg = New-Object System.Drawing.Bitmap($newWidth, $newHeight)
            $graph = [System.Drawing.Graphics]::FromImage($newImg)
            $graph.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graph.DrawImage($img, 0, 0, $newWidth, $newHeight)
            
            $img.Dispose()
            $tmpPath = $file.FullName + ".tmp"
            
            if ($isJpg) {
                $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
                $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
                $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]70)
                $newImg.Save($tmpPath, $codec, $encoderParams)
            } else {
                # For PNG, just save resized
                $newImg.Save($tmpPath, [System.Drawing.Imaging.ImageFormat]::Png)
            }
            
            $newImg.Dispose()
            $graph.Dispose()
            
            # Replace original
            Remove-Item $file.FullName -Force
            Rename-Item $tmpPath -NewName $file.Name
            
            $newSize = (Get-Item $file.FullName).Length
            Write-Host "Compressed $($file.Name): $([math]::Round($originalSize/1MB, 2))MB -> $([math]::Round($newSize/1KB, 2))KB"
        } else {
            $img.Dispose()
            Write-Host "Skipped $($file.Name) (Already optimized)"
        }
    } catch {
        Write-Host "Error processing $($file.Name): $($_.Exception.Message)"
        if ($img -ne $null) { $img.Dispose() }
    }
}
