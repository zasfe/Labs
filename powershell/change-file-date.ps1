 $filePath = "C:\Users\User\Documents\example.txt"
    $newCreationTime = "2025-07-10 10:00:00"
    $newLastWriteTime = "2025-07-10 10:00:00"
    $newLastAccessTime = "2025-07-10 10:00:00"

    if (Test-Path $filePath) {
        try {
            (Get-Item $filePath).CreationTime = $newCreationTime
            (Get-Item $filePath).LastWriteTime = $newLastWriteTime
            (Get-Item $filePath).LastAccessTime = $newLastAccessTime
            Write-Host "파일 속성 변경 완료"
        }
        catch {
            Write-Host "오류 발생: $($_.Exception.Message)"
        }
    } else {
        Write-Host "파일을 찾을 수 없습니다."
    }
