-- Row Level Security (RLS) para RoomMate Match (PostgreSQL)
-- Aplica estas políticas DESPUÉS de ejecutar schema.sql y con un usuario no superusuario.
-- La app backend debe conectar con un rol que NO sea propietario de las tablas
-- para que las políticas de RLS se apliquen.

-- 1. Crear rol de aplicación (cambia la contraseña en producción y léela desde un secret manager)
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_user') THEN
    CREATE ROLE app_user LOGIN PASSWORD 'CHANGE_ME_IN_ENV';
  END IF;
END
$$;

GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;

-- 2. Habilitar RLS en todas las tablas de usuario
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE swipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE housing_listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorite_housing ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE verification ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filters ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_limits ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_cancellations ENABLE ROW LEVEL SECURITY;

-- 3. Forzar RLS también para el propietario (si usas el owner en algunos scripts admin, retíralo)
-- ALTER TABLE users FORCE ROW LEVEL SECURITY;

-- 4. Políticas de ejemplo. El backend debe ejecutar antes de cada consulta:
--    SET LOCAL app.firebase_uid = '<uid_del_usuario_autenticado>';
-- o configurarlo en un interceptor/middleware de NestJS.

CREATE POLICY users_self_policy ON users
  FOR ALL
  TO app_user
  USING (firebase_uid = current_setting('app.firebase_uid', true))
  WITH CHECK (firebase_uid = current_setting('app.firebase_uid', true));

CREATE POLICY profiles_self_policy ON profiles
  FOR ALL
  TO app_user
  USING (user_id = (SELECT id FROM users WHERE firebase_uid = current_setting('app.firebase_uid', true)));

CREATE POLICY swipes_self_policy ON swipes
  FOR ALL
  TO app_user
  USING (
    swiper_id = (SELECT id FROM users WHERE firebase_uid = current_setting('app.firebase_uid', true))
    OR swiped_id = (SELECT id FROM users WHERE firebase_uid = current_setting('app.firebase_uid', true))
  );

CREATE POLICY matches_self_policy ON matches
  FOR ALL
  TO app_user
  USING (
    user1_id = (SELECT id FROM users WHERE firebase_uid = current_setting('app.firebase_uid', true))
    OR user2_id = (SELECT id FROM users WHERE firebase_uid = current_setting('app.firebase_uid', true))
  );

CREATE POLICY messages_participant_policy ON messages
  FOR ALL
  TO app_user
  USING (
    sender_id = (SELECT id FROM users WHERE firebase_uid = current_setting('app.firebase_uid', true))
    OR receiver_id = (SELECT id FROM users WHERE firebase_uid = current_setting('app.firebase_uid', true))
  );

CREATE POLICY notifications_self_policy ON notifications
  FOR ALL
  TO app_user
  USING (user_id = (SELECT id FROM users WHERE firebase_uid = current_setting('app.firebase_uid', true)));

CREATE POLICY subscriptions_self_policy ON subscriptions
  FOR ALL
  TO app_user
  USING (user_id = (SELECT id FROM users WHERE firebase_uid = current_setting('app.firebase_uid', true)));

CREATE POLICY payments_self_policy ON payments
  FOR ALL
  TO app_user
  USING (user_id = (SELECT id FROM users WHERE firebase_uid = current_setting('app.firebase_uid', true)));

-- Nota: para lecturas que requieren joins cruzados (matching, descubrimiento de perfiles)
-- se recomienda usar una función SQL de alto nivel o un rol específico de 'matcher'
-- en lugar de conectar directamente con app_user a esas tablas.
