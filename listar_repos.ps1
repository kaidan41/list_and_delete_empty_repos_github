# Nome de usuário do GitHub
$username = "kaidan41"
# Token de acesso pessoal do GitHub
$token = "insira aqui seu token"


# URL base da API do GitHub
$apiUrl = "https://api.github.com"

# Função para listar repositórios vazios e com no máximo 130 arquivos
function List-Repos {
    $page = 1
    $reposVaziosOuPequenos = @()

    while ($true) {
        Write-Output "Fetching page $page..."  # Mensagem de depuração
        $authHeader = "Basic $([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($username):$($token)")))"
        $response = Invoke-RestMethod -Uri "$apiUrl/users/$username/repos?per_page=100&page=$page" -Headers @{Authorization = $authHeader}
        if ($response.Count -eq 0) {
            Write-Output "No more repositories found."  # Mensagem de depuração
            break
        }

        foreach ($repo in $response) {
            Write-Output "Checking repository: $($repo.full_name)"  # Mensagem de depuração
            try {
                $fileCount = Get-FileCount -repoFullName $repo.full_name -authHeader $authHeader
                Write-Output "File count for $($repo.full_name): $fileCount"  # Mensagem de depuração
                if ($fileCount -le 2) {
                    $reposVaziosOuPequenos += $repo.full_name
                }
            } catch {
                Write-Output "Error fetching contents for $($repo.full_name): $_"  # Mensagem de depuração
            }
        }

        $page++
    }

    $reposVaziosOuPequenos | Out-File -FilePath "repos_vazios_ou_pequenos.txt"
}

# Função para contar arquivos recursivamente
function Get-FileCount {
    param (
        [string]$repoFullName,
        [string]$authHeader
    )

    $fileCount = 0
    $contents = Invoke-RestMethod -Uri "$apiUrl/repos/$repoFullName/contents" -Headers @{Authorization = $authHeader}

    foreach ($item in $contents) {
        if ($item.type -eq "file") {
            $fileCount++
        } elseif ($item.type -eq "dir") {
            $fileCount += Get-FileCount -repoFullName "$repoFullName/contents/$($item.path)" -authHeader $authHeader
        }
    }

    return $fileCount
}

# Função para deletar repositórios listados no arquivo

function Delete-Repos {
    $filePath = "repos_vazios_ou_pequenos.txt"
    $repos = Get-Content $filePath

    foreach ($repo in $repos) {
        Write-Output "Deleting repository: $repo"
        try {
            $authHeader = "Basic $([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($username):$($token)")))"
            Invoke-RestMethod -Uri "$apiUrl/repos/$repo" -Method Delete -Headers @{Authorization = $authHeader}
            Write-Output "Successfully deleted: $repo"
        } catch {
            Write-Output "Error deleting repository: $repo - $_"
        }
    }
}

# Executa a função para listar repositórios
List-Repos

# Executa a função para deletar repositórios
# Delete-Repos

# Mensagem final de depuração
Write-Output "Script concluído. Verifique o arquivo repos_vazios_ou_pequenos.txt para os resultados."