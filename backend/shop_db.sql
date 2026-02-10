	BEGIN;

-- ---------- users ----------
CREATE TABLE IF NOT EXISTS public.users (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    email       VARCHAR(100) NOT NULL UNIQUE,
    password    VARCHAR(100) NOT NULL,
    created_at  TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

-- поиск по email
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);


-- ---------- products ----------
CREATE TABLE IF NOT EXISTS public.products (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(255) NOT NULL,
    description     TEXT,
    image_url       VARCHAR(500),
    rating          NUMERIC(2,1) NOT NULL DEFAULT 0.0,
    review_count    INTEGER NOT NULL DEFAULT 0,
    category        VARCHAR(100),
    price_per_unit  INTEGER NOT NULL,
    min_quantity    INTEGER NOT NULL DEFAULT 1,
    max_quantity    INTEGER,
    supplier_name   VARCHAR(255),
    delivery_date   VARCHAR(100),
    delivery_badge  VARCHAR(100),

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

-- ---------- orders ----------
CREATE TABLE IF NOT EXISTS public.orders (
    id          SERIAL PRIMARY KEY,
    status      VARCHAR(50) NOT NULL,
    created_at  TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.order_items (
    id          SERIAL PRIMARY KEY,
    order_id    INTEGER NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    name        VARCHAR(255) NOT NULL,
    volume      VARCHAR(50),
    price       INTEGER NOT NULL,
    quantity    INTEGER NOT NULL,
    image_url   VARCHAR(500),
    is_received BOOLEAN NOT NULL DEFAULT false
);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON public.order_items(order_id);

-- тесты и команды
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
    'Coca-Cola 1L',
    'Газированный безалкогольный напиток',
    'assets/coca_cola.jpeg',
    4.5,
    12,
    'Напитки, Газировка',
    600,
    1,
    'Coca-Cola Kazakhstan',
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
    name,
    volume,
    price,
    quantity,
    image_url,
    is_received
) VALUES
    (1, 'Напиток Coca-Cola газированный', '1.5 л', 3160, 2, 'https://via.placeholder.com/80', false),
    (1, 'Вода питьевая Nestle Pure Life', '5 л', 1200, 1, 'https://via.placeholder.com/80', false),
    (2, 'Напиток Fanta газированный', '1.5 л', 2900, 3, 'https://via.placeholder.com/80', true),
    (3, 'Напиток Sprite газированный', '1.5 л', 3000, 1, 'https://via.placeholder.com/80', true),
    (3, 'Сок Rich апельсиновый', '1 л', 1500, 2, 'https://via.placeholder.com/80', true),
    (4, 'Лимонад Tarkhuna', '1 л', 980, 4, 'https://via.placeholder.com/80', false);

select * from product;
COMMIT;
