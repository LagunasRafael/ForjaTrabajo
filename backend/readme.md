# Forja Trabajo – Backend

## Auth
POST /auth/register
POST /auth/login
GET  /auth/me

## Headers
Authorization: Bearer <access_token>

## Roles
- admin
- user
- provider

## Errores comunes
401 → Token inválido
403 → Rol insuficiente
