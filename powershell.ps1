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

# 2. Datos de VeraCrypt versión actual
$version = "1.26.24"

# URLs correctas
$url64 = "https://github.com/veracrypt/VeraCrypt/releases/download/VeraCrypt_$version/VeraCrypt_Setup_$version.exe"
$url32 = "https://github.com/veracrypt/VeraCrypt/releases/download/VeraCrypt_$version/VeraCrypt_Setup_x86_$version.exe"

$temp64 = "$env:TEMP\veracrypt_$version_x64.exe"
$temp32 = "$env:TEMP\veracrypt_$version_x86.exe"

# 3. Descargar instaladores
Invoke-WebRequest -Uri $url64 -OutFile $temp64
Invoke-WebRequest -Uri $url32 -OutFile $temp32

# 4. Calcular hashes
$hash64 = (Get-FileHash $temp64 -Algorithm SHA256).Hash.ToLower()
$hash32 = (Get-FileHash $temp32 -Algorithm SHA256).Hash.ToLower()

# 5. Crear manifiesto JSON con autoupdate
$manifest = @{
    version     = $version
    description = "Open-source disk encryption software"
    homepage    = "https://veracrypt.fr"
    license     = "Apache-2.0"
    innosetup   = $true
    architecture = @{
        "64bit" = @{
            url  = $url64
            hash = $hash64
        }
        "32bit" = @{
            url  = $url32
            hash = $hash32
        }
    }
    bin         = "VeraCrypt.exe"
    shortcuts   = @(
        @("VeraCrypt.exe", "VeraCrypt")
    )
    autoupdate = @{
        architecture = @{
            "64bit" = @{
                url = "https://github.com/veracrypt/VeraCrypt/releases/download/VeraCrypt_$version/VeraCrypt_Setup_$version.exe"
            }
            "32bit" = @{
                url = "https://github.com/veracrypt/VeraCrypt/releases/download/VeraCrypt_$version/VeraCrypt_Setup_x86_$version.exe"
            }
        }
        checkver = @{
            url   = "https://github.com/veracrypt/VeraCrypt/releases"
            regex = "VeraCrypt_([0-9.]+)"
        }
    }
}

$manifest | ConvertTo-Json -Depth 5 | Out-File "bucket/veracrypt.json" -Encoding UTF8

# 6. Commit
git add bucket/veracrypt.json
git commit -m "Add VeraCrypt $version manifest with correct URLs & autoupdate"
Write-Host "✅ Manifest for VeraCrypt $version creado con éxito!"

