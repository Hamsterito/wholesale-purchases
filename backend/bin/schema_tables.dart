part of 'backend.dart';

const List<Map<String, Object?>> _catalogHierarchySeed = [
  {
    'name': 'Напитки',
    'subtitle': 'Вода, соки, газировка',
    'imagePath': 'assets/catalog/water.jpg',
    'sortOrder': 1,
    'subcategories': [
      {
        'name': 'Вода',
        'imagePath': 'assets/catalog/water.jpg',
        'keywords': 'вода,минеральная',
        'sortOrder': 1,
      },
      {
        'name': 'Соки',
        'imagePath': 'assets/catalog/juice.jpg',
        'keywords': 'сок,соки,juice',
        'sortOrder': 2,
      },
      {
        'name': 'Газировка',
        'imagePath': 'assets/catalog/soda.jpg',
        'keywords': 'газировка,газированный,лимонад,soda',
        'sortOrder': 3,
      },
    ],
  },
  {
    'name': 'Овощи и фрукты',
    'subtitle': 'Фрукты, ягоды, овощи и зелень',
    'imagePath': 'assets/catalog/fruits_berries.jpg',
    'sortOrder': 2,
    'subcategories': [
      {
        'name': 'Фрукты, ягоды',
        'imagePath': 'assets/catalog/fruits_berries.jpg',
        'keywords': 'фрукты,ягоды,фрукт,ягода',
        'sortOrder': 1,
      },
      {
        'name': 'Овощи, грибы и зелень',
        'imagePath': 'assets/catalog/vegetables_greens.jpg',
        'keywords': 'овощи,грибы,зелень,овощ,гриб',
        'sortOrder': 2,
      },
    ],
  },
  {
    'name': 'Хлеб и пекарня',
    'subtitle': 'Хлеб, булочки, пироги',
    'imagePath': 'assets/catalog/bakery_pastry.jpg',
    'sortOrder': 3,
    'subcategories': [
      {
        'name': 'Выпечка от Манса',
        'imagePath': 'assets/catalog/bakery_pastry.jpg',
        'keywords': 'выпечка,пекарня,булочки,круассан',
        'sortOrder': 1,
      },
      {
        'name': 'Хлеб',
        'imagePath': 'assets/catalog/bread.jpg',
        'keywords': 'хлеб,батон,багет',
        'sortOrder': 2,
      },
      {
        'name': 'Выпечка и пироги',
        'imagePath': 'assets/catalog/pie.jpg',
        'keywords': 'выпечка,пирог,пироги',
        'sortOrder': 3,
      },
    ],
  },
  {
    'name': 'Молочная продукция',
    'subtitle': 'Молоко, сыр, йогурты и яйца',
    'imagePath': 'assets/catalog/milk.jpg',
    'sortOrder': 4,
    'subcategories': [
      {
        'name': 'Сыр',
        'imagePath': 'assets/catalog/cheese.jpg',
        'keywords': 'сыр',
        'sortOrder': 1,
      },
      {
        'name': 'Творог, сметана',
        'imagePath': 'assets/catalog/cottage_cheese.jpg',
        'keywords': 'творог,сметана,кисломолочные',
        'sortOrder': 2,
      },
      {
        'name': 'Йогурт и десерты',
        'imagePath': 'assets/catalog/yogurt_dessert.jpg',
        'keywords': 'йогурт,десерт,десерты',
        'sortOrder': 3,
      },
      {
        'name': 'Молоко и кисломолочные продукты',
        'imagePath': 'assets/catalog/milk.jpg',
        'keywords': 'молоко,кефир,ряженка,айран',
        'sortOrder': 4,
      },
      {
        'name': 'Масло и яйца',
        'imagePath': 'assets/catalog/butter_eggs.jpg',
        'keywords': 'масло,яйца,яйцо',
        'sortOrder': 5,
      },
    ],
  },
  {
    'name': 'Мясо и птица',
    'subtitle': 'Мясо, колбасы и деликатесы',
    'imagePath': 'assets/catalog/meat.jpg',
    'sortOrder': 5,
    'subcategories': [
      {
        'name': 'Мясо и птица',
        'imagePath': 'assets/catalog/meat.jpg',
        'keywords': 'мясо,птица,курица,говядина,свинина',
        'sortOrder': 1,
      },
      {
        'name': 'Колбасы и сосиски',
        'imagePath': 'assets/catalog/sausages.jpg',
        'keywords': 'колбаса,колбасы,сосиски,сардельки',
        'sortOrder': 2,
      },
      {
        'name': 'Мясные деликатесы',
        'imagePath': 'assets/catalog/deli_meats.jpg',
        'keywords': 'деликатесы,ветчина,бекон,хамон',
        'sortOrder': 3,
      },
    ],
  },
];

Future<void> _ensureDatabaseSchema(Connection connection) async {
  await _ensureUserSchema(connection);
  await _ensureAddressSchema(connection);
  await _ensureProductSchema(connection);
  await _ensureCategorySchema(connection);
  await _ensureOrderSchema(connection);
  await _ensureOrderItemsSchema(connection);
  await _ensureReviewSchema(connection);
  await _ensureSupportSchema(connection);
}

Future<void> _ensureUserSchema(Connection connection) async {
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
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);',
  );
}

Future<void> _ensureProductSchema(Connection connection) async {
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

Future<void> _ensureCategorySchema(Connection connection) async {
  await connection.execute('''
    CREATE TABLE IF NOT EXISTS public.categories (
      id SERIAL PRIMARY KEY,
      name VARCHAR(120) NOT NULL,
      parent_id INTEGER REFERENCES public.categories(id) ON DELETE SET NULL,
      subtitle VARCHAR(255),
      image_path VARCHAR(255),
      keywords TEXT,
      sort_order INTEGER NOT NULL DEFAULT 0,
      is_active BOOLEAN NOT NULL DEFAULT true,
      created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
    );
  ''');
  await connection.execute('''
    ALTER TABLE public.categories
      ADD COLUMN IF NOT EXISTS sort_order INTEGER NOT NULL DEFAULT 0;
  ''');
  await connection.execute('''
    ALTER TABLE public.categories
      ADD COLUMN IF NOT EXISTS parent_id INTEGER;
  ''');
  await connection.execute('''
    ALTER TABLE public.categories
      ADD COLUMN IF NOT EXISTS subtitle VARCHAR(255);
  ''');
  await connection.execute('''
    ALTER TABLE public.categories
      ADD COLUMN IF NOT EXISTS image_path VARCHAR(255);
  ''');
  await connection.execute('''
    ALTER TABLE public.categories
      ADD COLUMN IF NOT EXISTS keywords TEXT;
  ''');
  await connection.execute('''
    ALTER TABLE public.categories
      ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT true;
  ''');
  await connection.execute('''
    ALTER TABLE public.categories
      ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW();
  ''');
  await connection.execute('''
    ALTER TABLE public.categories
      ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW();
  ''');
  await connection.execute(r'''
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'fk_categories_parent'
      ) THEN
        ALTER TABLE public.categories
          ADD CONSTRAINT fk_categories_parent
          FOREIGN KEY (parent_id)
          REFERENCES public.categories(id)
          ON DELETE SET NULL;
      END IF;
    END
    $$;
  ''');
  await connection.execute(
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_categories_parent_name_ci ON public.categories (COALESCE(parent_id, 0), LOWER(name));',
  );
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_categories_active_sort ON public.categories(is_active, sort_order, id);',
  );
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_categories_parent_sort ON public.categories(parent_id, sort_order, id);',
  );

  final rootIdsByName = <String, int>{};

  for (final root in _catalogHierarchySeed) {
    final rootName = (root['name'] ?? '').toString().trim();
    if (rootName.isEmpty) {
      continue;
    }
    final inserted = await connection.execute(
      Sql.named('''
        INSERT INTO public.categories (
          name,
          parent_id,
          subtitle,
          image_path,
          keywords,
          sort_order,
          is_active
        )
        VALUES (
          @name::varchar(120),
          NULL,
          @subtitle::varchar(255),
          @image_path::varchar(255),
          NULL,
          @sort_order::integer,
          true
        )
        ON CONFLICT ((COALESCE(parent_id, 0)), (LOWER(name))) DO UPDATE
        SET subtitle = EXCLUDED.subtitle,
            image_path = EXCLUDED.image_path,
            keywords = NULL,
            sort_order = EXCLUDED.sort_order,
            is_active = EXCLUDED.is_active,
            updated_at = NOW()
        RETURNING id;
      '''),
      parameters: {
        'name': rootName,
        'subtitle': (root['subtitle'] ?? '').toString(),
        'image_path': (root['imagePath'] ?? '').toString(),
        'sort_order': _toPositiveInt(root['sortOrder'], fallback: 0),
      },
    );
    if (inserted.isNotEmpty) {
      final row = inserted.first.toColumnMap();
      rootIdsByName[rootName.toLowerCase()] = _toPositiveInt(row['id']);
    }
  }

  for (final root in _catalogHierarchySeed) {
    final rootName = (root['name'] ?? '').toString().trim();
    if (rootName.isEmpty) {
      continue;
    }
    final parentId = rootIdsByName[rootName.toLowerCase()];
    if (parentId == null || parentId <= 0) {
      continue;
    }

    final rawChildren = root['subcategories'];
    if (rawChildren is! List) {
      continue;
    }

    for (final item in rawChildren) {
      if (item is! Map) {
        continue;
      }
      final child = Map<String, dynamic>.from(item);
      final childName = (child['name'] ?? '').toString().trim();
      if (childName.isEmpty) {
        continue;
      }
      await connection.execute(
        Sql.named('''
          INSERT INTO public.categories (
            name,
            parent_id,
            subtitle,
            image_path,
            keywords,
            sort_order,
            is_active
          )
          VALUES (
            @name::varchar(120),
            @parent_id::integer,
            NULL,
            @image_path::varchar(255),
            @keywords::text,
            @sort_order::integer,
            true
          )
          ON CONFLICT ((COALESCE(parent_id, 0)), (LOWER(name))) DO UPDATE
          SET parent_id = EXCLUDED.parent_id,
              subtitle = NULL,
              image_path = EXCLUDED.image_path,
              keywords = EXCLUDED.keywords,
              sort_order = EXCLUDED.sort_order,
              is_active = EXCLUDED.is_active,
              updated_at = NOW();
        '''),
        parameters: {
          'name': childName,
          'parent_id': parentId,
          'image_path': (child['imagePath'] ?? '').toString(),
          'keywords': (child['keywords'] ?? '').toString(),
          'sort_order': _toPositiveInt(child['sortOrder'], fallback: 0),
        },
      );
    }
  }
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
            OR c.confdeltype <> 'r'
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
          ON DELETE RESTRICT;
      END IF;
    END
    $$;
  ''');
  await connection.execute(
    'ALTER TABLE public.order_items ALTER COLUMN product_id SET NOT NULL;',
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
            OR c.confdeltype <> 'r'
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
          ON DELETE RESTRICT;
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

