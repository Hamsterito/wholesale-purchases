	BEGIN;

-- ---------- пользователи ----------
CREATE TABLE IF NOT EXISTS public.users (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    email       VARCHAR(100) NOT NULL UNIQUE,
    password    VARCHAR(100) NOT NULL,
    role        VARCHAR(20) NOT NULL DEFAULT 'buyer',
    supplier_name VARCHAR(255),
    phone       VARCHAR(20),
    created_at  TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

-- поиск по email
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);


-- ---------- товары ----------
CREATE TABLE IF NOT EXISTS public.categories (
    id            SERIAL PRIMARY KEY,
    name          VARCHAR(120) NOT NULL,
    parent_id     INTEGER REFERENCES public.categories(id) ON DELETE SET NULL,
    subtitle      VARCHAR(255),
    image_path    VARCHAR(255),
    keywords      TEXT,
    sort_order    INTEGER NOT NULL DEFAULT 0,
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

ALTER TABLE public.categories
    ADD COLUMN IF NOT EXISTS parent_id INTEGER;
ALTER TABLE public.categories
    ADD COLUMN IF NOT EXISTS subtitle VARCHAR(255);
ALTER TABLE public.categories
    ADD COLUMN IF NOT EXISTS image_path VARCHAR(255);
ALTER TABLE public.categories
    ADD COLUMN IF NOT EXISTS keywords TEXT;
ALTER TABLE public.categories
    ADD COLUMN IF NOT EXISTS sort_order INTEGER NOT NULL DEFAULT 0;
ALTER TABLE public.categories
    ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE public.categories
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW();
ALTER TABLE public.categories
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW();

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

DROP INDEX IF EXISTS idx_categories_name_ci;
CREATE UNIQUE INDEX IF NOT EXISTS idx_categories_parent_name_ci
    ON public.categories (COALESCE(parent_id, 0), LOWER(name));
CREATE INDEX IF NOT EXISTS idx_categories_active_sort
    ON public.categories (is_active, sort_order, id);
CREATE INDEX IF NOT EXISTS idx_categories_parent_sort
    ON public.categories (parent_id, sort_order, id);

CREATE TABLE IF NOT EXISTS public.products (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(255) NOT NULL,
    description     TEXT,
    image_url       TEXT,
    ingredients     TEXT,
    nutrition_calories NUMERIC(10,2) NOT NULL DEFAULT 0,
    nutrition_protein NUMERIC(10,2) NOT NULL DEFAULT 0,
    nutrition_fat NUMERIC(10,2) NOT NULL DEFAULT 0,
    nutrition_carbohydrates NUMERIC(10,2) NOT NULL DEFAULT 0,
    characteristics TEXT,
    stock_quantity  INTEGER NOT NULL DEFAULT 0,
    rating          NUMERIC(2,1) NOT NULL DEFAULT 0.0,
    review_count    INTEGER NOT NULL DEFAULT 0,
    category        VARCHAR(100),
    price_per_unit  INTEGER NOT NULL,
    min_quantity    INTEGER NOT NULL DEFAULT 1,
    max_quantity    INTEGER,
    supplier_name   VARCHAR(255),
    delivery_date   VARCHAR(100),
    delivery_badge  VARCHAR(100),
    supplier_user_id INTEGER REFERENCES public.users(id) ON DELETE SET NULL,
    moderation_status VARCHAR(20) NOT NULL DEFAULT 'approved',
    moderation_comment TEXT,

    -- базовые проверки
    CONSTRAINT chk_products_rating CHECK (rating >= 0 AND rating <= 5),
    CONSTRAINT chk_products_review_count CHECK (review_count >= 0),
    CONSTRAINT chk_products_price CHECK (price_per_unit >= 0),
    CONSTRAINT chk_products_min_quantity CHECK (min_quantity >= 1),
    CONSTRAINT chk_products_max_quantity CHECK (
        max_quantity IS NULL OR max_quantity >= min_quantity
    )
);

-- индексы под типовые фильтры
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category);
CREATE INDEX IF NOT EXISTS idx_products_supplier_name ON public.products(supplier_name);
CREATE INDEX IF NOT EXISTS idx_products_supplier_user_id ON public.products(supplier_user_id);
CREATE INDEX IF NOT EXISTS idx_products_stock_quantity ON public.products(stock_quantity);
CREATE INDEX IF NOT EXISTS idx_products_moderation_status ON public.products(moderation_status);

-- ---------- адреса ----------
CREATE TABLE IF NOT EXISTS public.addresses (
    id          SERIAL PRIMARY KEY,
    user_id     INTEGER NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    label       VARCHAR(50) NOT NULL,
    address_line TEXT NOT NULL,
    street      VARCHAR(100),
    zip         VARCHAR(20),
    apartment   VARCHAR(20),
    created_at  TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_addresses_user_id ON public.addresses(user_id);

-- ---------- заказы ----------
CREATE TABLE IF NOT EXISTS public.orders (
    id          SERIAL PRIMARY KEY,
    status      TEXT NOT NULL,
    delivery_address TEXT,
    user_id     INTEGER,
    created_at  TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.order_items (
    id          SERIAL PRIMARY KEY,
    order_id    INTEGER NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id  INTEGER NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
    name        VARCHAR(255) NOT NULL,
    price       INTEGER NOT NULL,
    quantity    INTEGER NOT NULL,
    image_url   TEXT,
    is_received BOOLEAN NOT NULL DEFAULT false,
    supplier_name VARCHAR(255),
    supplier_user_id INTEGER
);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_supplier_name ON public.order_items(supplier_name);
CREATE INDEX IF NOT EXISTS idx_order_items_supplier_user_id ON public.order_items(supplier_user_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON public.order_items(product_id);
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON public.orders(user_id);

-- ---------- отзывы ----------
CREATE TABLE IF NOT EXISTS public.reviews (
    id            SERIAL PRIMARY KEY,
    order_id      INTEGER NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    order_item_id INTEGER NOT NULL REFERENCES public.order_items(id) ON DELETE CASCADE,
    product_id    INTEGER NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
    user_id       INTEGER REFERENCES public.users(id) ON DELETE SET NULL,
    rating        INTEGER NOT NULL,
    review_text   TEXT,
    created_at    TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_reviews_rating CHECK (rating >= 1 AND rating <= 5),
    CONSTRAINT uq_reviews_order_item UNIQUE (order_item_id)
);

CREATE INDEX IF NOT EXISTS idx_reviews_product_id ON public.reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user_id ON public.reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_order_id ON public.reviews(order_id);

-- ---------- техподдержка ----------
CREATE TABLE IF NOT EXISTS public.support_chats (
    id               SERIAL PRIMARY KEY,
    user_id          INTEGER NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    status           VARCHAR(20) NOT NULL DEFAULT 'open',
    category         VARCHAR(120),
    subject          VARCHAR(255),
    close_reason     TEXT,
    created_at       TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    closed_at        TIMESTAMP WITHOUT TIME ZONE,
    closed_by_user_id INTEGER REFERENCES public.users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS public.support_messages (
    id            SERIAL PRIMARY KEY,
    chat_id       INTEGER REFERENCES public.support_chats(id) ON DELETE CASCADE,
    user_id       INTEGER NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    sender_role   VARCHAR(20) NOT NULL,
    sender_user_id INTEGER REFERENCES public.users(id) ON DELETE SET NULL,
    category      VARCHAR(120),
    subject       VARCHAR(255),
    message_text  TEXT NOT NULL,
    created_at    TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_support_chats_open_user
    ON public.support_chats(user_id)
    WHERE status = 'open';
CREATE INDEX IF NOT EXISTS idx_support_chats_user_id
    ON public.support_chats(user_id);
CREATE INDEX IF NOT EXISTS idx_support_chats_status_updated
    ON public.support_chats(status, updated_at);
CREATE INDEX IF NOT EXISTS idx_support_messages_chat_id
    ON public.support_messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_support_messages_user_id
    ON public.support_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_support_messages_created_at
    ON public.support_messages(created_at);

-- тестовые данные
INSERT INTO public.categories (
    name,
    parent_id,
    subtitle,
    image_path,
    keywords,
    sort_order,
    is_active
)
VALUES
    ('Напитки', NULL, 'Вода, соки, газировка', 'assets/catalog/water.jpg', NULL, 1, TRUE),
    ('Овощи и фрукты', NULL, 'Фрукты, ягоды, овощи и зелень', 'assets/catalog/fruits_berries.jpg', NULL, 2, TRUE),
    ('Хлеб и пекарня', NULL, 'Хлеб, булочки, пироги', 'assets/catalog/bakery_pastry.jpg', NULL, 3, TRUE),
    ('Молочная продукция', NULL, 'Молоко, сыр, йогурты и яйца', 'assets/catalog/milk.jpg', NULL, 4, TRUE),
    ('Мясо и птица', NULL, 'Мясо, колбасы и деликатесы', 'assets/catalog/meat.jpg', NULL, 5, TRUE)
ON CONFLICT ((COALESCE(parent_id, 0)), (LOWER(name))) DO UPDATE
SET
    subtitle = EXCLUDED.subtitle,
    image_path = EXCLUDED.image_path,
    keywords = EXCLUDED.keywords,
    sort_order = EXCLUDED.sort_order,
    is_active = EXCLUDED.is_active,
    updated_at = NOW();

WITH parents AS (
    SELECT id, name
    FROM public.categories
    WHERE parent_id IS NULL
)
INSERT INTO public.categories (name, parent_id, image_path, keywords, sort_order, is_active)
VALUES
    ('Вода', (SELECT id FROM parents WHERE LOWER(name) = LOWER('Напитки')), 'assets/catalog/water.jpg', 'вода,минеральная', 1, TRUE),
    ('Соки', (SELECT id FROM parents WHERE LOWER(name) = LOWER('Напитки')), 'assets/catalog/juice.jpg', 'сок,соки,juice', 2, TRUE),
    ('Газировка', (SELECT id FROM parents WHERE LOWER(name) = LOWER('Напитки')), 'assets/catalog/soda.jpg', 'газировка,газированный,лимонад,soda', 3, TRUE),
    ('Фрукты, ягоды', (SELECT id FROM parents WHERE LOWER(name) = LOWER('Овощи и фрукты')), 'assets/catalog/fruits_berries.jpg', 'фрукты,ягоды,фрукт,ягода', 1, TRUE),
    ('Овощи, грибы и зелень', (SELECT id FROM parents WHERE LOWER(name) = LOWER('Овощи и фрукты')), 'assets/catalog/vegetables_greens.jpg', 'овощи,грибы,зелень,овощ,гриб', 2, TRUE),
    ('Выпечка от Манса', (SELECT id FROM parents WHERE LOWER(name) = LOWER('Хлеб и пекарня')), 'assets/catalog/bakery_pastry.jpg', 'выпечка,пекарня,булочки,круассан', 1, TRUE),
    ('Хлеб', (SELECT id FROM parents WHERE LOWER(name) = LOWER('Хлеб и пекарня')), 'assets/catalog/bread.jpg', 'хлеб,батон,багет', 2, TRUE),
    ('Выпечка и пироги', (SELECT id FROM parents WHERE LOWER(name) = LOWER('Хлеб и пекарня')), 'assets/catalog/pie.jpg', 'выпечка,пирог,пироги', 3, TRUE),
    ('Сыр', (SELECT id FROM parents WHERE LOWER(name) = LOWER('Молочная продукция')), 'assets/catalog/cheese.jpg', 'сыр', 1, TRUE),
    ('Творог, сметана', (SELECT id FROM parents WHERE LOWER(name) = LOWER('Молочная продукция')), 'assets/catalog/cottage_cheese.jpg', 'творог,сметана,кисломолочные', 2, TRUE),
    ('Йогурт и десерты', (SELECT id FROM parents WHERE LOWER(name) = LOWER('Молочная продукция')), 'assets/catalog/yogurt_dessert.jpg', 'йогурт,десерт,десерты', 3, TRUE),
    ('Молоко и кисломолочные продукты', (SELECT id FROM parents WHERE LOWER(name) = LOWER('Молочная продукция')), 'assets/catalog/milk.jpg', 'молоко,кефир,ряженка,айран', 4, TRUE),
    ('Масло и яйца', (SELECT id FROM parents WHERE LOWER(name) = LOWER('Молочная продукция')), 'assets/catalog/butter_eggs.jpg', 'масло,яйца,яйцо', 5, TRUE),
    ('Мясо и птица', (SELECT id FROM parents WHERE LOWER(name) = LOWER('Мясо и птица')), 'assets/catalog/meat.jpg', 'мясо,птица,курица,говядина,свинина', 1, TRUE),
    ('Колбасы и сосиски', (SELECT id FROM parents WHERE LOWER(name) = LOWER('Мясо и птица')), 'assets/catalog/sausages.jpg', 'колбаса,колбасы,сосиски,сардельки', 2, TRUE),
    ('Мясные деликатесы', (SELECT id FROM parents WHERE LOWER(name) = LOWER('Мясо и птица')), 'assets/catalog/deli_meats.jpg', 'деликатесы,ветчина,бекон,хамон', 3, TRUE)
ON CONFLICT ((COALESCE(parent_id, 0)), (LOWER(name))) DO UPDATE
SET
    parent_id = EXCLUDED.parent_id,
    image_path = EXCLUDED.image_path,
    keywords = EXCLUDED.keywords,
    sort_order = EXCLUDED.sort_order,
    is_active = EXCLUDED.is_active,
    updated_at = NOW();
INSERT INTO public.products (
    name,
    description,
    image_url,
    rating,
    review_count,
    category,
    price_per_unit,
    min_quantity,
    supplier_name,
    delivery_date,
    delivery_badge
) VALUES (
    'Coca-Cola 1 л',
    'Газированный безалкогольный напиток',
    'assets/coca_cola.jpeg',
    4.5,
    12,
    'Напитки, Газировка',
    600,
    1,
    'Coca-Cola Казахстан',
    'завтра',
    'Четверг 17:00'
);

INSERT INTO public.orders (status, created_at) VALUES
    ('В пути', NOW() - INTERVAL '2 days'),
    ('Доставлен', NOW() - INTERVAL '1 day'),
    ('Принят', NOW() - INTERVAL '5 days'),
    ('В пути', NOW() - INTERVAL '3 hours');

INSERT INTO public.order_items (
    order_id,
    product_id,
    name,
    price,
    quantity,
    image_url,
    is_received
) VALUES
    (1, (SELECT id FROM public.products ORDER BY id DESC LIMIT 1), 'Coca-Cola газированный напиток', 3160, 2, 'https://via.placeholder.com/80', false),
    (1, (SELECT id FROM public.products ORDER BY id DESC LIMIT 1), 'Вода Nestle Pure Life', 1200, 1, 'https://via.placeholder.com/80', false),
    (2, (SELECT id FROM public.products ORDER BY id DESC LIMIT 1), 'Fanta газированный напиток', 2900, 3, 'https://via.placeholder.com/80', true),
    (3, (SELECT id FROM public.products ORDER BY id DESC LIMIT 1), 'Sprite газированный напиток', 3000, 1, 'https://via.placeholder.com/80', true),
    (3, (SELECT id FROM public.products ORDER BY id DESC LIMIT 1), 'Апельсиновый сок Rich', 1500, 2, 'https://via.placeholder.com/80', true),
    (4, (SELECT id FROM public.products ORDER BY id DESC LIMIT 1), 'Лимонад Тархун', 980, 4, 'https://via.placeholder.com/80', false);

COMMIT;



