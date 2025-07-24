Write-Host "This script will create signs.sc file for SMU controllers / Цей скрипт створить файл signs.sc для SMU контролера" -ForegroundColor Cyan
Write-Host "Please select language / Будь ласка, виберіть мову:"
Write-Host "1: English"
Write-Host "2: Українська"
$languageChoice = Read-Host "Enter choice (1 or 2)"

switch ($languageChoice) {
    "1" { $lang = "en" }
    "2" { $lang = "uk" }
    default {
        Write-Host "Invalid choice. Defaulting to English."
        $lang = "en"
    }
}

# Language function
function Get-Prompt {
    param ([string]$key)

    $prompts = @{
        "en" = @{
            "dbName" = "Enter database name (from 3 to 10 characters):"
            "dbError" = "Database name must be at least 3, but not more, than 10 characters"
            "pathPrompt" = "Enter the path to the folder where the file will be saved:"
            "pathError" = "The specified path does not exist. Please try again"
            "numSigns" = "Enter number of signs:"
            "signWidth" = "Enter width for sign"
            "signHeight" = "Enter height for sign"
            "signAddr" = "Enter address for sign"
            "fileExists" = "File 'signs.sc' already exists. Overwrite? (Y/N):"
            "newFilename" = "Enter new filename (with .sc extension):"
            "invalidFilename" = "Invalid filename or file already exists"
            "writing" = "Writing configuration to file..."
            "done" = "Done. Created file:"
        }
        "uk" = @{
            "dbName" = "Введіть назву бази даних (від 3 до 10 символів):"
            "dbError" = "Назва бази даних має містити від 3 до 10 символів"
            "pathPrompt" = "Введіть шлях до папки, де буде збережено файл:"
            "pathError" = "Вказаний шлях не існує. Спробуйте ще раз."
            "numSigns" = "Введіть кількість табло в конфігурації:"
            "signWidth" = "Введіть ширину для табло"
            "signHeight" = "Введіть висоту для табло"
            "signAddr" = "Введіть адресу для табло"
            "fileExists" = "Файл 'signs.sc' вже існує. Перезаписати? (Y/N):"
            "newFilename" = "Введіть нову назву файлу (з розширенням .sc):"
            "invalidFilename" = "Не правильна назва файлу або файл з такою назвою вже існує"
            "writing" = "Запис конфігурації у файл..."
            "done" = "Готово. Створено файл:"
        }
    }

    return $prompts[$lang][$key]
}

# Ask for the database name
do {
    $dbName = Read-Host (Get-Prompt "dbName")
    $validDb = $dbName.Length -ge 3 -le 10
    if (-not $validDb) {
        Write-Host (Get-Prompt "dbError") -ForegroundColor Red
    }
} until ($validDb)

# Ask for direktory path
do {
    $inputPath = Read-Host (Get-Prompt "pathPrompt")
    $validPath = Test-Path $inputPath
    if (-not $validPath) {
        Write-Host (Get-Prompt "pathError") -ForegroundColor Red
    }
} until ($validPath)

# Ask user for no. of signs
do {
    $numSigns = Read-Host (Get-Prompt "numSigns")
    $isValidNum = $numSigns -as [int] -and ([int]$numSigns -gt 0)
} until ($isValidNum)
$numSigns = [int]$numSigns

# Collect sign data
$signConfigs = @()
for ($i = 0; $i -lt $numSigns; $i++) {
    $index = "s$i"
    $width = Read-Host ("$(Get-Prompt 'signWidth') [$index]")
    $height = Read-Host ("$(Get-Prompt 'signHeight') [$index]")
    $address = Read-Host ("$(Get-Prompt 'signAddr') [$index]")
    $signConfigs += "$index=$width,$height,$address"
}

# Prepare data
# Config
$configBlock = @()
$configBlock += "[config]"
$configBlock += "db=$dbName"
$configBlock += $signConfigs

# Temp solution for signs
$hexBlock = @()
$hexBlock += "[4DigitDestinationCode]"
foreach ($i in 0..($numSigns - 1)) {
    $hexBlock += "[s$i]"
    $hexBlock += "<hex binary data>"
}

# Check if file already exists, and if yes< ask user for input
$outputFile = Join-Path $inputPath "signs.sc"
if (Test-Path $outputFile) {
    $overwrite = Read-Host (Get-Prompt "fileExists")
    if ($overwrite -notmatch "^[Yy]") {
        do {
            $newName = Read-Host (Get-Prompt "newFilename")
            $outputFile = Join-Path $inputPath $newName
            $validName = ($newName -match '\.sc$') -and (-not (Test-Path $outputFile))
            if (-not $validName) {
                Write-Host (Get-Prompt "invalidFilename") -ForegroundColor Red
            }
        } until ($validName)
    }
}

#Create and populate file
Write-Host (Get-Prompt "writing") -ForegroundColor Cyan
$finalOutput = $configBlock + "" + $hexBlock
$finalOutput | Out-File -FilePath $outputFile

Write-Host "$(Get-Prompt 'done') $outputFile" -ForegroundColor Green
