-- Проверка существования
SELECT id, name, email, role
FROM public.users
WHERE email = 'kabdrashev111@gmail.com';

-- Удаление
DELETE FROM public.users
WHERE email = 'kabdrashev111@gmail.com'
RETURNING id, name, email, role;
