create type ginzburg_food.restaurant_status as enum (
    'активен',
    'неактивен'
);

create type ginzburg_food.product_status as enum (
    'доступно',
    'нет_в_наличии',
    'архив'
);

create type ginzburg_food.courier_status as enum (
    'свободен',
    'занят',
    'на_доставке',
    'уволен'
);

create type ginzburg_food.order_status as enum (
    'создан',
    'готовится',
    'в_доставке',
    'доставлен',
    'отменён'
);

create type ginzburg_food.order_pay_status as enum (
    'ожидает',
    'оплачен',
    'ошибка'
);

create type ginzburg_food.payment_status as enum (
    'успех',
    'ошибка',
    'в_обработке'
);

create type ginzburg_food.payment_type as enum (
    'карта',
    'наличные',
    'безнал'
);

create type ginzburg_food.review_entity_type as enum (
    'блюдо',
    'ресторан',
    'заказ'
);
