# Script de administración de Active Directory Creado por: Ángel Torres Morano


$pathDominio = (Get-ADDomain).DistinguishedName # Obtenemos la ruta base del dominio de forma dinámica


# 1) Mostrar el menú
do {
 
  Clear-Host #limpia la pantalla
  Write-Host "=========================================="
  Write-Host "     MENU DE ADMINISTRACION AD"
  Write-Host "=========================================="
  Write-Host "1. Información del dominio"
  Write-Host "2. Crear OU"
  Write-Host "3. Crear grupo"
  Write-Host "4. Crear usuario"
  Write-Host "5. Salir"

  # 2) Leer la opción
  $opcion = Read-Host "Elige una opción"

  # 3) Según la opción, hacer una cosa u otra
  switch ($opcion) {
    "1" {
      $equipo = $env:COMPUTERNAME
      $dominio = (Get-ADDomain).DNSRoot
      $numOUs = (Get-ADOrganizationalUnit -Filter *).Count
      $numGroup = (Get-ADGroup -Filter *).Count
      $numUser = (Get-ADUser -Filter *).Count
      Write-Host "Nombre del equipo → $equipo"
      Write-Host "Nombre del dominio → $dominio"
      Write-Host "Nº de OUs → $numOUs"
      Write-Host "Nº de grupos → $numGroup"
      Write-Host "Nº de usuarios → $numUser"
      Pause
    }

    "2" {
      Write-Host "Indique el nombre de la OU a crear"
      $nombreOU = Read-Host "Nombre de la OU"
      New-ADOrganizationalUnit -Name $nombreOU -Path $pathDominio
      Write-Host "OU '$nombreOU' creada correctamente."
      Pause
    }

    "3" { 
      Write-Host "Indique el nombre del grupo a crear" 
      $nombreGrupo = Read-Host "Nombre del grupo"
      Write-Host "Indique el nombre de la OU donde se creará el grupo"
      $nombreOU = Read-Host "Nombre de la OU"
      New-ADGroup -Name $nombreGrupo -GroupScope Global -Path "OU=$nombreOU,$pathDominio"
      Write-Host "Grupo '$nombreGrupo' creado correctamente en la OU '$nombreOU'."
      Pause
    }

    "4" {
      Write-Host "Indique el nombre del usuario a crear"
      $nombreUsuario = Read-Host "Nombre del usuario"
      Write-Host "Indique el nombre de inicio de sesión"
      $nombreInicioSesion = Read-Host "Nombre de inicio de sesión"
      Write-Host "Indique el nombre de la OU donde se creará el usuario"
      $nombreOU = Read-Host "Nombre de la OU"
      Write-host "indique la contraseña inicial del usuario"
      $clave = Read-Host "Contraseña inicial" -AsSecureString
      New-ADUser -Name $nombreUsuario -SamAccountName $nombreInicioSesion -Path "OU=$nombreOU,$pathDominio" -AccountPassword $clave -Enabled $true -ChangePasswordAtLogon $true
      write-host "Indique el grupo al que se añadirá el usuario"
      $nombreGrupo = Read-Host "Nombre del grupo"
      Add-ADGroupMember -Identity $nombreGrupo -Members $nombreInicioSesion
      Write-Host "Usuario '$nombreUsuario' creado correctamente en la OU '$nombreOU' en el grupo '$nombreGrupo'."
      Pause
  
    }
    "5" { Write-Host "Adiós" }
    default { Write-Host "Opción no válida" }
  }

} while ($opcion -ne "5")    # 4) Repetir mientras la opción NO sea 5