#!/bin/bash
# angeltorresldap.sh - Gestión del atributo "mail" de los usuarios del dominio LDAP
# Este script permite eliminar, modificar y buscar correos electrónicos en un servidor LDAP.

echo "=== Configuración de conexión LDAP ==="

# 1. SOLICITUD DE CREDENCIALES Y RUTAS
# Pedimos la base DN al usuario para que sirva en cualquier dominio.
read -p "Introduce la Base DN (ej. dc=empresa,dc=local): " BASE

# Verificamos que no se haya dejado en blanco. Si está vacío, salimos del script.
if [ -z "$BASE" ]; then
    echo "Error: La Base DN no puede estar vacía."
    exit 1
fi

# Pedimos el usuario administrador. 
# La sintaxis ${ADMIN_CN:-cn=admin} asigna "cn=admin" si el usuario pulsa Enter sin escribir nada.
read -p "Introduce el CN del administrador [por defecto: cn=admin]: " ADMIN_CN
ADMIN_CN=${ADMIN_CN:-cn=admin}
ADMIN="${ADMIN_CN},${BASE}"

# Pedimos la contraseña. El parámetro '-s' oculta los caracteres por seguridad.
read -s -p "Contraseña de ${ADMIN}: " PASS
echo
echo "======================================"
echo

# 2. FUNCIONES DE VALIDACIÓN Y BÚSQUEDA

# Función para validar que el nombre de usuario (uid) solo contenga caracteres permitidos.
validar_uid() {
    [[ "$1" =~ ^[a-zA-Z0-9._-]+$ ]]
}

# Función para obtener el Distinguished Name (DN) exacto de un usuario.
dn_usuario() {
    ldapsearch -x -LLL -o ldif-wrap=no -b "$BASE" "(&(objectClass=inetOrgPerson)(uid=$1))" dn \
        | sed -n 's/^dn: //p'
}

# Función para formatear la salida en columnas usando AWK.
formatear() {
    awk '
        /^uid:/  { u = $2 }
        /^mail:/ { m = $2 }
        /^$/     { if (u != "") printf "%-20s %s\n", u, (m == "" ? "(sin correo)" : m); u = ""; m = "" }
        END      { if (u != "") printf "%-20s %s\n", u, (m == "" ? "(sin correo)" : m) }
    '
}

# 3. FUNCIONES DE MODIFICACIÓN LDAP

# Función para borrar el atributo "mail" de un usuario existente.
eliminar_correo() {
    read -p "Usuario (uid) al que eliminar el correo: " USUARIO
    validar_uid "$USUARIO" || { echo "Nombre de usuario no válido."; return; }
    
    DN=$(dn_usuario "$USUARIO")
    [ -z "$DN" ] && { echo "El usuario '$USUARIO' no existe."; return; }
    
    ldapmodify -x -D "$ADMIN" -w "$PASS" <<EOF
dn: $DN
changetype: modify
delete: mail
EOF
    [ $? -eq 0 ] && echo "Correo eliminado correctamente para '$USUARIO'." || echo "No se pudo eliminar el correo."
}

# Función para añadir o reemplazar el atributo "mail" de un usuario.
modificar_correo() {
    read -p "Usuario (uid) al que modificar el correo: " USUARIO
    validar_uid "$USUARIO" || { echo "Nombre de usuario no válido."; return; }
    
    DN=$(dn_usuario "$USUARIO")
    [ -z "$DN" ] && { echo "El usuario '$USUARIO' no existe."; return; }
    
    read -p "Nuevo correo: " NUEVO
    [[ "$NUEVO" =~ ^[^@[:space:]]+@[^@[:space:]]+$ ]] || { echo "Correo no válido."; return; }
    
    ldapmodify -x -D "$ADMIN" -w "$PASS" <<EOF
dn: $DN
changetype: modify
replace: mail
mail: $NUEVO
EOF
    [ $? -eq 0 ] && echo "Correo de '$USUARIO' actualizado a $NUEVO." || echo "Error al modificar el correo."
}

# Función para buscar y listar usuarios y sus correos.
buscar() {
    echo "  a) Consultar un usuario concreto"
    echo "  b) Listar todos los usuarios (nombre y correo)"
    read -p "Elija una opción: " SUB
    case "$SUB" in
        a|A)
            read -p "Usuario (uid): " USUARIO
            validar_uid "$USUARIO" || { echo "Nombre de usuario no válido."; return; }
            RES=$(ldapsearch -x -LLL -b "$BASE" "(&(objectClass=inetOrgPerson)(uid=$USUARIO))" uid mail | formatear)
            [ -z "$RES" ] && echo "El usuario '$USUARIO' no existe." || { printf "%-20s %s\n" "USUARIO" "CORREO"; echo "$RES"; }
            ;;
        b|B)
            printf "%-20s %s\n" "USUARIO" "CORREO"
            ldapsearch -x -LLL -b "$BASE" "(objectClass=inetOrgPerson)" uid mail | formatear
            ;;
        *) echo "Opción no válida." ;;
    esac
}

# 4. MENÚ PRINCIPAL (Sin while true)
# Encapsulamos el menú en una función que se llama a sí misma (recursividad)
mostrar_menu() {
    echo
    echo "===== GESTIÓN LDAP - ${BASE} ====="
    echo "1) Eliminar correo de un usuario"
    echo "2) Modificar correo de un usuario"
    echo "3) Realizar búsquedas"
    echo "0) Salir"
    read -p "Seleccione una opción: " OP
    
    case "$OP" in
        1) eliminar_correo; mostrar_menu ;;  # Tras ejecutar la acción, vuelve a llamar al menú
        2) modificar_correo; mostrar_menu ;; # Tras ejecutar la acción, vuelve a llamar al menú
        3) buscar; mostrar_menu ;;           # Tras ejecutar la acción, vuelve a llamar al menú
        0) echo "Saliendo..."; exit 0 ;;     # Sale del script por completo
        *) echo "Opción no válida."; mostrar_menu ;; # Si se equivoca, vuelve a llamar al menú
    esac
}

# Iniciamos el menú por primera vez para arrancar el programa
mostrar_menu
