part of 'backend.dart';



Future<void> _ensureDatabaseSchema(Connection connection) async {
  await _ensureUserSchema(connection);
  await _ensureTwoFactorSchema(connection);
  await _ensureEmailVerificationSchema(connection);
  await _ensurePasswordResetSchema(connection);
  await _ensureAddressSchema(connection);
  await _ensureProductSchema(connection);
  await _ensureOrderSchema(connection);
  await _ensureOrderItemsSchema(connection);
  await _ensureReviewSchema(connection);
  await _ensureSupplierReviewResponsesSchema(connection);
  await _ensureSupportSchema(connection);
  await _dropLegacyChatsSchema(connection);
  await _ensureQuestionsSchema(connection);
  await _ensureExchangeRatesSchema(connection);
  await _ensureModerationDeletionsSchema(connection);
}

/// Создание таблицы курсов валют и заполнение начальных значений.
Future<void> _ensureExchangeRatesSchema(Connection connection) async {
  await connection.execute('''
    CREATE TABLE IF NOT EXISTS public.exchange_rates (
      currency_code VARCHAR(10) PRIMARY KEY,
      rate NUMERIC(10, 6) NOT NULL,
      updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
    );
  ''');

  // Добавление дефолтного значения для рубля при первой инициализации
  await connection.execute('''
    INSERT INTO public.exchange_rates (currency_code, rate, updated_at)
    VALUES ('RUB', 0.1, NOW())
    ON CONFLICT (currency_code) DO NOTHING;
  ''');
}

Future<void> _ensureUserSchema(Connection connection) async {
  // Базовая таблица пользователей. Раньше создавалась только через shop_db.sql,
  // из-за чего на свежей БД backend падал на первом ALTER TABLE.
  await connection.execute('''
    CREATE TABLE IF NOT EXISTS public.users (
      id SERIAL PRIMARY KEY,
      name VARCHAR(100) NOT NULL,
      email VARCHAR(100) NOT NULL UNIQUE,
      password VARCHAR(100) NOT NULL,
      is_verified BOOLEAN NOT NULL DEFAULT false,
      role VARCHAR(20) NOT NULL DEFAULT 'buyer',
      supplier_name VARCHAR(255),
      phone VARCHAR(20),
      created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
    );
  ''');
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);',
  );
  await connection.execute('''
    ALTER TABLE public.users
      ADD COLUMN IF NOT EXISTS role VARCHAR(20) NOT NULL DEFAULT 'buyer';
  ''');
  await connection.execute('''
    ALTER TABLE public.users
      ADD COLUMN IF NOT EXISTS supplier_name VARCHAR(255);
  ''');
  await connection.execute('''
    ALTER TABLE public.users
      ADD COLUMN IF NOT EXISTS phone VARCHAR(20);
  ''');
  await connection.execute('''
    ALTER TABLE public.users
      ADD COLUMN IF NOT EXISTS is_verified BOOLEAN NOT NULL DEFAULT false;
  ''');
  // Аватарка: относительный путь вида /uploads/avatars/<filename> или NULL.
  // На существующих записях PostgreSQL заполнит NULL автоматически, новые
  // регистрации тоже не указывают avatar_url явно - получают NULL по умолчанию.
  await connection.execute('''
    ALTER TABLE public.users
      ADD COLUMN IF NOT EXISTS avatar_url VARCHAR(500);
  ''');
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);',
  );
}

Future<void> _ensureEmailVerificationSchema(Connection connection) async {
  await connection.execute('''
    CREATE TABLE IF NOT EXISTS public.email_verifications (
      id SERIAL PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
      code_hash VARCHAR(255) NOT NULL,
      expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
      used BOOLEAN NOT NULL DEFAULT false,
      created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
    );
  ''');

  // Мигрируем существующую колонку, если она WITHOUT TIME ZONE
  try {
    await connection.execute('''
      ALTER TABLE public.email_verifications
      ALTER COLUMN expires_at TYPE TIMESTAMP WITH TIME ZONE
      USING expires_at AT TIME ZONE 'UTC';
    ''');
  } catch (e) {
    // Колонка уже может быть WITH TIME ZONE, игнорируем ошибку
    print(
      'Примечание: миграция email_verifications.expires_at пропущена (возможно уже TIMESTAMPTZ): $e',
    );
  }

  try {
    await connection.execute('''
      ALTER TABLE public.email_verifications
      ALTER COLUMN created_at TYPE TIMESTAMP WITH TIME ZONE
      USING created_at AT TIME ZONE 'UTC';
    ''');
  } catch (e) {
    // Колонка уже может быть WITH TIME ZONE, игнорируем ошибку
    print(
      'Примечание: миграция email_verifications.created_at пропущена (возможно уже TIMESTAMPTZ): $e',
    );
  }

  // purpose: назначение OTP - enable/disable/regenerate/revoke для 2FA, NULL
  // для не-2FA (регистрация, forgot-password). Verify-эндпоинты фильтруют по
  // нему, чтобы код, выпущенный под одну операцию, не проходил под другую.
  await connection.execute('''
    ALTER TABLE public.email_verifications
      ADD COLUMN IF NOT EXISTS purpose VARCHAR(32);
  ''');

  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_email_verifications_user_id ON public.email_verifications(user_id);',
  );
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_email_verifications_expires_at ON public.email_verifications(expires_at);',
  );
}

Future<void> _ensurePasswordResetSchema(Connection connection) async {
  await connection.execute('''
    CREATE TABLE IF NOT EXISTS public.password_resets (
      id SERIAL PRIMARY KEY,
      email VARCHAR(255) NOT NULL,
      code_hash VARCHAR(255) NOT NULL,
      expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
      used BOOLEAN NOT NULL DEFAULT false,
      created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
    );
  ''');

  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_password_resets_email ON public.password_resets(email);',
  );
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_password_resets_expires_at ON public.password_resets(expires_at);',
  );
}

Future<void> _ensureProductSchema(Connection connection) async {
  // Базовая таблица товаров. Раньше создавалась только через shop_db.sql,
  // из-за чего на свежей БД backend падал на первом ALTER TABLE.
  await connection.execute('''
    CREATE TABLE IF NOT EXISTS public.products (
      id SERIAL PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      description TEXT,
      image_url TEXT,
      ingredients TEXT,
      nutrition_calories NUMERIC(10,2) NOT NULL DEFAULT 0,
      nutrition_protein NUMERIC(10,2) NOT NULL DEFAULT 0,
      nutrition_fat NUMERIC(10,2) NOT NULL DEFAULT 0,
      nutrition_carbohydrates NUMERIC(10,2) NOT NULL DEFAULT 0,
      characteristics TEXT,
      stock_quantity INTEGER NOT NULL DEFAULT 0,
      rating NUMERIC(2,1) NOT NULL DEFAULT 0.0,
      review_count INTEGER NOT NULL DEFAULT 0,
      category VARCHAR(100),
      price_per_unit INTEGER NOT NULL DEFAULT 0,
      min_quantity INTEGER NOT NULL DEFAULT 1,
      max_quantity INTEGER,
      supplier_name VARCHAR(255),
      delivery_date VARCHAR(100),
      delivery_badge VARCHAR(100),
      supplier_user_id INTEGER,
      moderation_status VARCHAR(20) NOT NULL DEFAULT 'approved',
      moderation_comment TEXT
    );
  ''');
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category);',
  );
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_products_supplier_name ON public.products(supplier_name);',
  );
  await connection.execute('''
    ALTER TABLE public.products
      ADD COLUMN IF NOT EXISTS supplier_user_id INTEGER;
  ''');
  await connection.execute(
    'ALTER TABLE public.products ALTER COLUMN image_url TYPE TEXT;',
  );
  await connection.execute('''
    ALTER TABLE public.products
      ADD COLUMN IF NOT EXISTS ingredients TEXT;
  ''');
  await connection.execute('''
    ALTER TABLE public.products
      ADD COLUMN IF NOT EXISTS nutrition_calories NUMERIC(10,2) NOT NULL DEFAULT 0;
  ''');
  await connection.execute('''
    ALTER TABLE public.products
      ADD COLUMN IF NOT EXISTS nutrition_protein NUMERIC(10,2) NOT NULL DEFAULT 0;
  ''');
  await connection.execute('''
    ALTER TABLE public.products
      ADD COLUMN IF NOT EXISTS nutrition_fat NUMERIC(10,2) NOT NULL DEFAULT 0;
  ''');
  await connection.execute('''
    ALTER TABLE public.products
      ADD COLUMN IF NOT EXISTS nutrition_carbohydrates NUMERIC(10,2) NOT NULL DEFAULT 0;
  ''');
  await connection.execute('''
    ALTER TABLE public.products
      ADD COLUMN IF NOT EXISTS characteristics TEXT;
  ''');
  await connection.execute('''
    ALTER TABLE public.products
      ADD COLUMN IF NOT EXISTS stock_quantity INTEGER NOT NULL DEFAULT 0;
  ''');
  await connection.execute('''
    ALTER TABLE public.products
      ADD COLUMN IF NOT EXISTS moderation_status VARCHAR(20)
      NOT NULL DEFAULT 'approved';
  ''');
  await connection.execute('''
    ALTER TABLE public.products
      ADD COLUMN IF NOT EXISTS moderation_comment TEXT;
  ''');
  await connection.execute('''
    ALTER TABLE public.products
      ADD COLUMN IF NOT EXISTS name_kk VARCHAR(255);
  ''');
  await connection.execute('''
    ALTER TABLE public.products
      ADD COLUMN IF NOT EXISTS description_kk TEXT;
  ''');
  await connection.execute('''
    ALTER TABLE public.products
      ADD COLUMN IF NOT EXISTS category_kk VARCHAR(100);
  ''');
  await connection.execute('''
    ALTER TABLE public.products
      ADD COLUMN IF NOT EXISTS ingredients_kk TEXT;
  ''');
  await connection.execute('''
    ALTER TABLE public.products
      ADD COLUMN IF NOT EXISTS characteristics_kk TEXT;
  ''');
  await connection.execute('''
    UPDATE public.products p
    SET supplier_user_id = NULL
    WHERE supplier_user_id IS NOT NULL
      AND NOT EXISTS (
        SELECT 1
        FROM public.users u
        WHERE u.id = p.supplier_user_id
      );
  ''');
  await connection.execute(r'''
    DO $$
    DECLARE
      constraint_name text;
    BEGIN
      FOR constraint_name IN
        SELECT c.conname
        FROM pg_constraint c
        JOIN pg_class t ON t.oid = c.conrelid
        JOIN pg_namespace n ON n.oid = t.relnamespace
        WHERE c.contype = 'f'
          AND n.nspname = 'public'
          AND t.relname = 'products'
          AND (
            c.conname <> 'fk_products_supplier_user_id'
            OR c.confrelid <> 'public.users'::regclass
            OR c.confdeltype <> 'n'
          )
          AND EXISTS (
            SELECT 1
            FROM unnest(c.conkey) AS col_num
            JOIN pg_attribute a
              ON a.attrelid = c.conrelid
             AND a.attnum = col_num
            WHERE a.attname = 'supplier_user_id'
          )
      LOOP
        EXECUTE format(
          'ALTER TABLE public.products DROP CONSTRAINT %I',
          constraint_name
        );
      END LOOP;
    END
    $$;
  ''');
  await connection.execute(r'''
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'fk_products_supplier_user_id'
          AND conrelid = 'public.products'::regclass
      ) THEN
        ALTER TABLE public.products
          ADD CONSTRAINT fk_products_supplier_user_id
          FOREIGN KEY (supplier_user_id)
          REFERENCES public.users(id)
          ON DELETE SET NULL;
      END IF;
    END
    $$;
  ''');
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_products_supplier_user_id ON public.products(supplier_user_id);',
  );
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_products_stock_quantity ON public.products(stock_quantity);',
  );
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_products_moderation_status ON public.products(moderation_status);',
  );
}



Future<void> _ensureOrderItemsSchema(Connection connection) async {
  await connection.execute('''
    ALTER TABLE public.order_items
      ADD COLUMN IF NOT EXISTS image_url TEXT;
  ''');
  await connection.execute(
    'ALTER TABLE public.order_items ALTER COLUMN image_url TYPE TEXT;',
  );
  await connection.execute('''
    ALTER TABLE public.order_items
      ADD COLUMN IF NOT EXISTS supplier_name VARCHAR(255);
  ''');
  await connection.execute('''
    ALTER TABLE public.order_items
      ADD COLUMN IF NOT EXISTS name_kk VARCHAR(255);
  ''');
  await connection.execute('''
    ALTER TABLE public.order_items
      ADD COLUMN IF NOT EXISTS product_id INTEGER;
  ''');
  await connection.execute('''
    ALTER TABLE public.order_items
      ADD COLUMN IF NOT EXISTS supplier_user_id INTEGER;
  ''');
  await connection.execute('''
    DELETE FROM public.order_items oi
    WHERE oi.product_id IS NULL
      OR NOT EXISTS (
        SELECT 1
        FROM public.products p
        WHERE p.id = oi.product_id
      );
  ''');
  await connection.execute(r'''
    DO $$
    DECLARE
      constraint_name text;
    BEGIN
      FOR constraint_name IN
        SELECT c.conname
        FROM pg_constraint c
        JOIN pg_class t ON t.oid = c.conrelid
        JOIN pg_namespace n ON n.oid = t.relnamespace
        WHERE c.contype = 'f'
          AND n.nspname = 'public'
          AND t.relname = 'order_items'
          AND (
            c.conname <> 'fk_order_items_product_id'
            OR c.confrelid <> 'public.products'::regclass
            OR c.confdeltype <> 'n'
          )
          AND EXISTS (
            SELECT 1
            FROM unnest(c.conkey) AS col_num
            JOIN pg_attribute a
              ON a.attrelid = c.conrelid
             AND a.attnum = col_num
            WHERE a.attname = 'product_id'
          )
      LOOP
        EXECUTE format(
          'ALTER TABLE public.order_items DROP CONSTRAINT %I',
          constraint_name
        );
      END LOOP;
    END
    $$;
  ''');
  await connection.execute(r'''
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'fk_order_items_product_id'
          AND conrelid = 'public.order_items'::regclass
      ) THEN
        ALTER TABLE public.order_items
          ADD CONSTRAINT fk_order_items_product_id
          FOREIGN KEY (product_id)
          REFERENCES public.products(id)
          ON DELETE SET NULL;
      END IF;
    END
    $$;
  ''');
  await connection.execute(
    'ALTER TABLE public.order_items ALTER COLUMN product_id DROP NOT NULL;',
  );
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_order_items_supplier_name ON public.order_items(supplier_name);',
  );
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_order_items_supplier_user_id ON public.order_items(supplier_user_id);',
  );
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON public.order_items(product_id);',
  );
}

Future<void> _ensureAddressSchema(Connection connection) async {
  await connection.execute('''
    CREATE TABLE IF NOT EXISTS public.addresses (
      id SERIAL PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
      label VARCHAR(50) NOT NULL,
      address_line TEXT NOT NULL,
      street VARCHAR(100),
      zip VARCHAR(20),
      apartment VARCHAR(20),
      created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
    );
  ''');
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_addresses_user_id ON public.addresses(user_id);',
  );
}

Future<void> _ensureReviewSchema(Connection connection) async {
  await connection.execute('''
    CREATE TABLE IF NOT EXISTS public.reviews (
      id SERIAL PRIMARY KEY,
      order_id INTEGER NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
      order_item_id INTEGER NOT NULL REFERENCES public.order_items(id) ON DELETE CASCADE,
      product_id INTEGER NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
      user_id INTEGER REFERENCES public.users(id) ON DELETE SET NULL,
      rating INTEGER NOT NULL,
      review_text TEXT,
      created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
      CONSTRAINT chk_reviews_rating CHECK (rating >= 1 AND rating <= 5),
      CONSTRAINT uq_reviews_order_item UNIQUE (order_item_id)
    );
  ''');
  await connection.execute('''
    UPDATE public.reviews r
    SET product_id = oi.product_id
    FROM public.order_items oi
    WHERE oi.id = r.order_item_id
      AND (
        r.product_id IS NULL
        OR r.product_id <> oi.product_id
      );
  ''');
  await connection.execute('''
    DELETE FROM public.reviews r
    WHERE r.product_id IS NULL
      OR NOT EXISTS (
        SELECT 1
        FROM public.products p
        WHERE p.id = r.product_id
      );
  ''');
  await connection.execute(r'''
    DO $$
    DECLARE
      constraint_name text;
    BEGIN
      FOR constraint_name IN
        SELECT c.conname
        FROM pg_constraint c
        JOIN pg_class t ON t.oid = c.conrelid
        JOIN pg_namespace n ON n.oid = t.relnamespace
        WHERE c.contype = 'f'
          AND n.nspname = 'public'
          AND t.relname = 'reviews'
          AND (
            c.conname <> 'fk_reviews_product_id'
            OR c.confrelid <> 'public.products'::regclass
            OR c.confdeltype <> 'c'
          )
          AND EXISTS (
            SELECT 1
            FROM unnest(c.conkey) AS col_num
            JOIN pg_attribute a
              ON a.attrelid = c.conrelid
             AND a.attnum = col_num
            WHERE a.attname = 'product_id'
          )
      LOOP
        EXECUTE format(
          'ALTER TABLE public.reviews DROP CONSTRAINT %I',
          constraint_name
        );
      END LOOP;
    END
    $$;
  ''');
  await connection.execute(r'''
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'fk_reviews_product_id'
          AND conrelid = 'public.reviews'::regclass
      ) THEN
        ALTER TABLE public.reviews
          ADD CONSTRAINT fk_reviews_product_id
          FOREIGN KEY (product_id)
          REFERENCES public.products(id)
          ON DELETE CASCADE;
      END IF;
    END
    $$;
  ''');
  await connection.execute(
    'ALTER TABLE public.reviews ALTER COLUMN product_id SET NOT NULL;',
  );
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_reviews_product_id ON public.reviews(product_id);',
  );
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_reviews_user_id ON public.reviews(user_id);',
  );
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_reviews_order_id ON public.reviews(order_id);',
  );
}

Future<void> _ensureSupplierReviewResponsesSchema(Connection connection) async {
  await connection.execute('''
    CREATE TABLE IF NOT EXISTS public.supplier_review_responses (
      id SERIAL PRIMARY KEY,
      review_id INTEGER NOT NULL UNIQUE REFERENCES public.reviews(id) ON DELETE CASCADE,
      response_text TEXT NOT NULL,
      created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
    );
  ''');
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_supplier_review_responses_review_id ON public.supplier_review_responses(review_id);',
  );
}

Future<void> _ensureSupportSchema(Connection connection) async {
  await connection.execute('''
    CREATE TABLE IF NOT EXISTS public.support_chats (
      id SERIAL PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
      status VARCHAR(20) NOT NULL DEFAULT 'open',
      category VARCHAR(120),
      subject VARCHAR(255),
      close_reason TEXT,
      created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
      closed_at TIMESTAMP WITHOUT TIME ZONE,
      closed_by_user_id INTEGER REFERENCES public.users(id) ON DELETE SET NULL
    );
  ''');
  await connection.execute('''
    ALTER TABLE public.support_chats
      ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'open';
  ''');
  await connection.execute('''
    ALTER TABLE public.support_chats
      ADD COLUMN IF NOT EXISTS category VARCHAR(120);
  ''');
  await connection.execute('''
    ALTER TABLE public.support_chats
      ADD COLUMN IF NOT EXISTS subject VARCHAR(255);
  ''');
  await connection.execute('''
    ALTER TABLE public.support_chats
      ADD COLUMN IF NOT EXISTS close_reason TEXT;
  ''');
  await connection.execute('''
    ALTER TABLE public.support_chats
      ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW();
  ''');
  await connection.execute('''
    ALTER TABLE public.support_chats
      ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW();
  ''');
  await connection.execute('''
    ALTER TABLE public.support_chats
      ADD COLUMN IF NOT EXISTS closed_at TIMESTAMP WITHOUT TIME ZONE;
  ''');
  await connection.execute('''
    ALTER TABLE public.support_chats
      ADD COLUMN IF NOT EXISTS closed_by_user_id INTEGER;
  ''');

  await connection.execute('''
    CREATE TABLE IF NOT EXISTS public.support_messages (
      id SERIAL PRIMARY KEY,
      chat_id INTEGER REFERENCES public.support_chats(id) ON DELETE CASCADE,
      user_id INTEGER NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
      sender_role VARCHAR(20) NOT NULL,
      sender_user_id INTEGER REFERENCES public.users(id) ON DELETE SET NULL,
      category VARCHAR(120),
      subject VARCHAR(255),
      message_text TEXT NOT NULL,
      created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
    );
  ''');
  await connection.execute('''
    ALTER TABLE public.support_messages
      ADD COLUMN IF NOT EXISTS chat_id INTEGER;
  ''');
  await connection.execute('''
    ALTER TABLE public.support_messages
      ADD COLUMN IF NOT EXISTS sender_user_id INTEGER;
  ''');
  await connection.execute('''
    ALTER TABLE public.support_messages
      ADD COLUMN IF NOT EXISTS category VARCHAR(120);
  ''');
  await connection.execute('''
    ALTER TABLE public.support_messages
      ADD COLUMN IF NOT EXISTS subject VARCHAR(255);
  ''');
  await connection.execute('''
    INSERT INTO public.support_chats (
      user_id,
      status,
      category,
      subject,
      created_at,
      updated_at
    )
    SELECT
      sm.user_id,
      'open',
      (
        SELECT s1.category
        FROM public.support_messages s1
        WHERE s1.user_id = sm.user_id
          AND s1.category IS NOT NULL
          AND btrim(s1.category) <> ''
        ORDER BY s1.id ASC
        LIMIT 1
      ),
      (
        SELECT s2.subject
        FROM public.support_messages s2
        WHERE s2.user_id = sm.user_id
          AND s2.subject IS NOT NULL
          AND btrim(s2.subject) <> ''
        ORDER BY s2.id ASC
        LIMIT 1
      ),
      MIN(sm.created_at),
      NOW()
    FROM public.support_messages sm
    WHERE sm.user_id IS NOT NULL
      AND NOT EXISTS (
        SELECT 1
        FROM public.support_chats sc
        WHERE sc.user_id = sm.user_id
      )
    GROUP BY sm.user_id;
  ''');
  await connection.execute('''
    UPDATE public.support_messages sm
    SET chat_id = (
      SELECT sc.id
      FROM public.support_chats sc
      WHERE sc.user_id = sm.user_id
      ORDER BY
        CASE WHEN sc.status = 'open' THEN 0 ELSE 1 END ASC,
        sc.id DESC
      LIMIT 1
    )
    WHERE sm.chat_id IS NULL;
  ''');
  await connection.execute('''
    DO \$\$
    BEGIN
      IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'fk_support_messages_chat_id'
          AND conrelid = 'public.support_messages'::regclass
      ) THEN
        ALTER TABLE public.support_messages
          ADD CONSTRAINT fk_support_messages_chat_id
          FOREIGN KEY (chat_id) REFERENCES public.support_chats(id) ON DELETE CASCADE;
      END IF;
    END \$\$;
  ''');
  await connection.execute(
    "CREATE UNIQUE INDEX IF NOT EXISTS uq_support_chats_open_user ON public.support_chats(user_id) WHERE status = 'open';",
  );
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_support_chats_user_id ON public.support_chats(user_id);',
  );
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_support_chats_status_updated ON public.support_chats(status, updated_at);',
  );
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_support_messages_chat_id ON public.support_messages(chat_id);',
  );
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_support_messages_user_id ON public.support_messages(user_id);',
  );
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_support_messages_created_at ON public.support_messages(created_at);',
  );
}

/// Дроп таблиц устаревшего модератор-поставщикского чата. Функциональность
/// свёрнута в обычные support_chats — модератор инициирует чат через
/// find-or-create. На старте дропаем безусловно: в бою таблицы не жили.
Future<void> _dropLegacyChatsSchema(Connection connection) async {
  await connection.execute('DROP TABLE IF EXISTS public.chat_reads CASCADE;');
  await connection.execute(
    'DROP TABLE IF EXISTS public.chat_messages CASCADE;',
  );
  await connection.execute('DROP TABLE IF EXISTS public.chats CASCADE;');
}

Future<void> _ensureOrderSchema(Connection connection) async {
  await connection.execute('''
    CREATE TABLE IF NOT EXISTS public.orders (
      id SERIAL PRIMARY KEY,
      status TEXT NOT NULL,
      delivery_address TEXT,
      user_id INTEGER,
      created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
    );
  ''');
  await connection.execute('''
    ALTER TABLE public.orders
      ALTER COLUMN status TYPE TEXT;
  ''');

  await connection.execute('''
    ALTER TABLE public.orders
      ADD COLUMN IF NOT EXISTS delivery_address TEXT;
  ''');
  await connection.execute('''
    ALTER TABLE public.orders
      ADD COLUMN IF NOT EXISTS user_id INTEGER;
  ''');
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_orders_user_id ON public.orders(user_id);',
  );

  await connection.execute('''
    CREATE TABLE IF NOT EXISTS public.order_items (
      id SERIAL PRIMARY KEY,
      order_id INTEGER NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
      product_id INTEGER NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
      name VARCHAR(255) NOT NULL,
      name_kk VARCHAR(255),
      price INTEGER NOT NULL,
      quantity INTEGER NOT NULL,
      image_url TEXT,
      is_received BOOLEAN NOT NULL DEFAULT false
    );
  ''');

  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON public.order_items(order_id);',
  );
}

Future<void> _ensureQuestionsSchema(Connection connection) async {
  // Таблица вопросов
  await connection.execute('''
    CREATE TABLE IF NOT EXISTS public.questions (
      id SERIAL PRIMARY KEY,
      product_id INTEGER NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
      user_id INTEGER NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
      question_text TEXT NOT NULL CHECK (char_length(question_text) >= 10 AND char_length(question_text) <= 500),
      created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
      is_answered BOOLEAN NOT NULL DEFAULT false
    );
  ''');

  await connection.execute('''
    CREATE INDEX IF NOT EXISTS idx_questions_product_id ON public.questions(product_id);
  ''');
  await connection.execute('''
    CREATE INDEX IF NOT EXISTS idx_questions_user_id ON public.questions(user_id);
  ''');
  await connection.execute('''
    CREATE INDEX IF NOT EXISTS idx_questions_created_at ON public.questions(created_at DESC);
  ''');

  // Таблица ответов
  await connection.execute('''
    CREATE TABLE IF NOT EXISTS public.question_answers (
      id SERIAL PRIMARY KEY,
      question_id INTEGER NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
      supplier_user_id INTEGER NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
      answer_text TEXT NOT NULL CHECK (char_length(answer_text) >= 10 AND char_length(answer_text) <= 1000),
      answered_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
      UNIQUE (question_id)
    );
  ''');

  await connection.execute('''
    CREATE INDEX IF NOT EXISTS idx_question_answers_question_id ON public.question_answers(question_id);
  ''');
}

/// Таблица уведомлений об удалении товара модератором.
/// Поставщик получает уведомление-баннер; чат поддержки
/// открывается только если поставщик нажмет "Обратиться в поддержку".
Future<void> _ensureModerationDeletionsSchema(Connection connection) async {
  await connection.execute('''
    CREATE TABLE IF NOT EXISTS public.moderation_deletions (
      id SERIAL PRIMARY KEY,
      supplier_user_id INTEGER NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
      product_name VARCHAR(255) NOT NULL,
      reason TEXT NOT NULL,
      moderator_id INTEGER REFERENCES public.users(id) ON DELETE SET NULL,
      dismissed BOOLEAN NOT NULL DEFAULT false,
      created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
    );
  ''');
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_moderation_deletions_supplier ON public.moderation_deletions(supplier_user_id);',
  );
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_moderation_deletions_active ON public.moderation_deletions(supplier_user_id) WHERE dismissed = false;',
  );
}

Future<void> _ensureTwoFactorSchema(Connection connection) async {
  // Флаг включения 2FA на пользователе
  await connection.execute('''
    ALTER TABLE public.users
      ADD COLUMN IF NOT EXISTS two_factor_enabled BOOLEAN NOT NULL DEFAULT false;
  ''');

  // Backup-коды
  await connection.execute('''
    CREATE TABLE IF NOT EXISTS public.two_factor_backup_codes (
      id SERIAL PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
      code_hash VARCHAR(255) NOT NULL,
      used BOOLEAN NOT NULL DEFAULT false,
      created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
      used_at TIMESTAMP WITH TIME ZONE
    );
  ''');
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_2fa_backup_codes_user ON public.two_factor_backup_codes(user_id);',
  );
  // Частичный индекс для быстрого выбора неиспользованных кодов
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_2fa_backup_codes_user_unused ON public.two_factor_backup_codes(user_id) WHERE used = false;',
  );

  // Доверенные устройства
  await connection.execute('''
    CREATE TABLE IF NOT EXISTS public.two_factor_trusted_devices (
      id SERIAL PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
      token_hash VARCHAR(255) NOT NULL,
      expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
      revoked BOOLEAN NOT NULL DEFAULT false,
      created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
    );
  ''');
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_2fa_trusted_user ON public.two_factor_trusted_devices(user_id);',
  );
  // Частичный индекс для быстрого подбора активных устройств при логине
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_2fa_trusted_active ON public.two_factor_trusted_devices(user_id, expires_at) WHERE revoked = false;',
  );

  // Pending-сессии 2FA-челленджа при логине
  await connection.execute('''
    CREATE TABLE IF NOT EXISTS public.two_factor_pending_sessions (
      id UUID PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
      code_hash VARCHAR(255) NOT NULL,
      attempts INTEGER NOT NULL DEFAULT 0,
      expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
      used BOOLEAN NOT NULL DEFAULT false,
      created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
      last_resend_at TIMESTAMP WITH TIME ZONE
    );
  ''');
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_2fa_pending_user ON public.two_factor_pending_sessions(user_id);',
  );
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_2fa_pending_expires ON public.two_factor_pending_sessions(expires_at);',
  );

  // Журнал аудита 2FA-действий
  await connection.execute('''
    CREATE TABLE IF NOT EXISTS public.two_factor_audit (
      id BIGSERIAL PRIMARY KEY,
      actor_user_id INTEGER REFERENCES public.users(id) ON DELETE SET NULL,
      target_user_id INTEGER NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
      action VARCHAR(40) NOT NULL,
      context VARCHAR(40),
      ip_address VARCHAR(64),
      created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
    );
  ''');
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_2fa_audit_target ON public.two_factor_audit(target_user_id, created_at DESC);',
  );
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_2fa_audit_action ON public.two_factor_audit(action, created_at DESC);',
  );
}

// наличие учётной записи Super_Admin (dota@gmail.com).
Future<void> _ensureSuperAdminUser(Connection connection) async {
  try {
    final existing = await connection.execute(
      Sql.named(
        'SELECT id, role FROM public.users WHERE LOWER(email) = @email LIMIT 1',
      ),
      parameters: {'email': _superAdminEmail},
    );

    if (existing.isEmpty) {
      await connection.execute(
        Sql.named('''
          INSERT INTO public.users (name, email, password, role, is_verified, created_at)
          VALUES (@name, @email, @password, 'super_admin', true, NOW());
        '''),
        parameters: {
          'name': _superAdminName,
          'email': _superAdminEmail,
          'password': _hashPassword(_superAdminInitialPassword),
        },
      );
      return;
    }

    final row = existing.first.toColumnMap();
    final currentRole = (row['role']?.toString() ?? '').trim().toLowerCase();
    if (currentRole == 'super_admin') {
      // Уже корректен — имя/телефон/пароль не трогаем
      return;
    }

    await connection.execute(
      Sql.named('''
        UPDATE public.users
        SET role = 'super_admin', is_verified = true
        WHERE id = @id;
      '''),
      parameters: {'id': row['id']},
    );
  } catch (e, st) {
    // Не валим запуск сервера, если БД временно недоступна или схема не готова
    print('Не удалось подготовить Super_Admin: $e\n$st');
  }
}

// Дефолтный поставщик dima@gmail.com / 123456: создаётся при старте, если
// такой записи ещё нет. Если запись есть, но заблокирована флагом is_verified
// = false (например, осталась с прошлого старта без подтверждения почты),
// мягко её допиливаем до рабочего supplier-аккаунта.
Future<void> _ensureDefaultSupplierUser(Connection connection) async {
  try {
    final existing = await connection.execute(
      Sql.named(
        'SELECT id, role, is_verified FROM public.users WHERE LOWER(email) = @email LIMIT 1',
      ),
      parameters: {'email': _defaultSupplierEmail},
    );

    if (existing.isEmpty) {
      await connection.execute(
        Sql.named('''
          INSERT INTO public.users (
            name, email, password, role, supplier_name, is_verified, created_at
          )
          VALUES (
            @name, @email, @password, 'supplier', @supplier_name, true, NOW()
          );
        '''),
        parameters: {
          'name': _defaultSupplierName,
          'email': _defaultSupplierEmail,
          'password': _hashPassword(_defaultSupplierInitialPassword),
          'supplier_name': _defaultSupplierCompanyName,
        },
      );
      return;
    }

    final row = existing.first.toColumnMap();
    final currentRole = (row['role']?.toString() ?? '').trim().toLowerCase();
    final isVerified = row['is_verified'] == true;

    // Уже supplier и подтверждён - ничего не трогаем, чтобы не перетирать
    // настоящие данные/пароль пользователя.
    if (currentRole == 'supplier' && isVerified) {
      return;
    }

    // Иначе чиним до рабочего состояния: роль supplier, подтверждён.
    // Пароль не сбрасываем - вдруг пользователь его уже менял.
    await connection.execute(
      Sql.named('''
        UPDATE public.users
        SET role = 'supplier',
            is_verified = true,
            supplier_name = COALESCE(NULLIF(supplier_name, ''), @supplier_name)
        WHERE id = @id;
      '''),
      parameters: {
        'id': row['id'],
        'supplier_name': _defaultSupplierCompanyName,
      },
    );
  } catch (e, st) {
    // Не валим запуск сервера, если БД временно недоступна или схема не готова
    print('Не удалось подготовить дефолтного поставщика: $e\n$st');
  }
}
