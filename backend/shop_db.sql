	BEGIN;

-- ---------- пользователи ----------
CREATE TABLE IF NOT EXISTS public.users (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    email       VARCHAR(100) NOT NULL UNIQUE,
    password    VARCHAR(100) NOT NULL,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    role        VARCHAR(20) NOT NULL DEFAULT 'buyer',
    supplier_name VARCHAR(255),
    phone       VARCHAR(20),
    created_at  TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

-- поиск по email
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);


-- ---------- товары ----------


CREATE TABLE IF NOT EXISTS public.products (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(255) NOT NULL,
    name_kk         VARCHAR(255),
    description     TEXT,
    description_kk  TEXT,
    image_url       TEXT,
    ingredients     TEXT,
    ingredients_kk  TEXT,
    nutrition_calories NUMERIC(10,2) NOT NULL DEFAULT 0,
    nutrition_protein NUMERIC(10,2) NOT NULL DEFAULT 0,
    nutrition_fat NUMERIC(10,2) NOT NULL DEFAULT 0,
    nutrition_carbohydrates NUMERIC(10,2) NOT NULL DEFAULT 0,
    characteristics TEXT,
    characteristics_kk TEXT,
    stock_quantity  INTEGER NOT NULL DEFAULT 0,
    rating          NUMERIC(2,1) NOT NULL DEFAULT 0.0,
    review_count    INTEGER NOT NULL DEFAULT 0,
    category        VARCHAR(100),
    category_kk     VARCHAR(100),
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
    name_kk     VARCHAR(255),
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



COMMIT;

-- таблица для хранения одноразовых кодов подтверждения почты
BEGIN;
CREATE TABLE IF NOT EXISTS public.email_verifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    code_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    used BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_email_verifications_user_id ON public.email_verifications(user_id);
CREATE INDEX IF NOT EXISTS idx_email_verifications_expires_at ON public.email_verifications(expires_at);
COMMIT;



