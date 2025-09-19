param(
    [string]$BucketName = "my-bucket",
    [string]$RepoUrl = "https://github.com/TUUSUARIO/my-bucket.git"
)

# 1. Crear estructura
if (!(Test-Path $BucketName)) {
    git clone https://github.com/ScoopInstaller/BucketTemplate.git $BucketName
    Set-Location $BucketName
    Remove-Item -Recurse -Force .git
    git init
    git remote add origin $RepoUrl
} else {
    Set-Location $BucketName
}

# Crear carpeta bucket si no existe
if (!(Test-Path "bucket")) {
    New-Item -ItemType Directory -Path "bucket" | Out-Null
}

# 2. Datos de VeraCrypt
$version = "1.26.7"
$url = "https://github.com/veracrypt/VeraCrypt/releases/download/VeraCrypt_$version/VeraCrypt%20Setup%20$version.exe"
$tempFile = "$env:TEMP\veracrypt-$version.exe"

# Descargar instalador
Invoke-WebRequest -Uri $url -OutFile $tempFile

# 3. Calcular hash
$hash = (Get-FileHash $tempFile -Algorithm SHA256).Hash.ToLower()

# 4. Crear manifiesto JSON con autoupdate y regex
$manifest = @{
    version     = $version
    description = "Open-source disk encryption software"
    homepage    = "https://www.veracrypt.fr"
    license     = "Apache-2.0"
    url         = $url
    hash        = $hash
    innosetup   = $true
    bin         = "VeraCrypt.exe"
    shortcuts   = @(
        @("VeraCrypt.exe", "VeraCrypt")
    )
    autoupdate  = @{
        url = "https://github.com/veracrypt/VeraCrypt/releases/download/VeraCrypt_$version/VeraCrypt%20Setup%20$version.exe"
        checkver = @{
            url   = "https://github.com/veracrypt/VeraCrypt/releases"
            regex = "VeraCrypt ([0-9.]+)"
        }
    }
}

$manifest | ConvertTo-Json -Depth 5 | Out-File "bucket/veracrypt.json" -Encoding UTF8

# 5. Commit inicial
git add bucket/veracrypt.json
git commit -m "Add VeraCrypt $version manifest with autoupdate"
Write-Host "✅ Manifest for VeraCrypt $version created successfully with autoupdate regex!"
