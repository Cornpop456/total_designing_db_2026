# Обоснование ограничений

## Как заполнять

- **CHECK, UNIQUE, FK** — обосновывать обязательно. Ссылка на `BR-N.M` + краткое «почему».
- **NOT NULL** — обосновывать **только** когда бизнес явно требует. Очевидные случаи (PK, FK на NOT NULL поле, поля из BR с явным «обязательно») — не дублировать.
- **NULL** (где разрешено) — обосновывать, потому что это осознанное решение, а не забывчивость.
- **DEFAULT, GENERATED** — кратко, если не очевидно.

**Правило:** если не можешь указать `BR-N.M` — либо ограничение лишнее, либо пропущено бизнес-правило. Разберись, прежде чем оставлять.

**Формат обоснования:** «<что ограничиваем> — потому что <BR-N.M> требует <что>».

Пример хорошего обоснования:

> `CHECK (rating BETWEEN 0 AND 5)` на `restaurant.rating` — потому что BR-4.2 задаёт диапазон рейтинга.

> `UNIQUE (address_id)` на `restaurant` — потому что BR-3.3 запрещает двум ресторанам делить один адрес.

> `FK (restaurant_id) → restaurant(restaurant_id)` на `product` — потому что BR-5.1 требует, чтобы блюдо принадлежало ресторану.

Пример плохого обоснования (не принимается):

> `NOT NULL` на `name` — потому что имя должно быть.

> `CHECK` на `price` — потому что цена не может быть отрицательной.

(Второе — обоснование «здравым смыслом», а не ссылкой на BR. Не принимается.)

---

## Enum-типы

Перечисли типы, которые создал. Если добавил/изменил значения относительно BR — обоснуй.

| Тип | Значения | BR |
|---|---|---|
|restaurant_status|`активен`, `неактивен`|BR-4.3|
|product_status|`доступно`, `нет_в_наличии`, `архив`|BR-5.5|
|courier_status|`свободен`, `занят`, `на_доставке`, `уволен`|BR-6.2|
|order_status|`создан`, `готовится`, `в_доставке`, `доставлен`, `отменён`|BR-7.7|
|order_pay_status|`ожидает`, `оплачен`, `ошибка`|BR-7.9|
|payment_status|`успех`, `ошибка`, `в_обработке`|BR-8.2|
|payment_type|`карта`, `наличные`, `безнал`|BR-8.2|
|review_entity_type|`блюдо`, `ресторан`, `заказ`|BR-9.1|

---

## Режим повторного запуска `insert_test_data`

Процедура `insert_test_data(value)` работает в режиме полной замены тестового
набора. В начале каждого вызова она очищает таблицы тестовых данных через
`TRUNCATE`, после чего создаёт новый согласованный набор.

## Ловушки

Здесь — не готовые решения, а **фиксация того, как ты решил** каждую ловушку. Преподаватель читает, чтобы понять ход мысли.

### Ловушка 1: `payment` — неполная сущность

**Какие атрибуты добавил в `payment` и почему** (BR-8.2):

```
В payment добавлены payment_type, amount, transaction_id,
transaction_timestamp и status: тип оплаты, сумма попытки, внешний
идентификатор транзакции, время операции и результат попытки.

payment_type нужен для определения типа платежа BR-8.2
transaction_id нужен для внешнего идентификатора финансовой транзакции BR-8.3
transaction_timestamp нужен для времени платежа BR-8.2
status нужен для определения статуса платежа BR-8.2
```

**Где хранится тип оплаты — `payment` или `order`** (BR-8.6):

```
Тип оплаты хранится в таблице payment, поскольку является атрибутом  попытки оплаты, а не заказа.
При успешной попытке, её тип при необходимости можно получить с помощью SELECT с JOIN и фильтрацией по статусу 'успех'.
Наличие не более одной успешной попытки для каждого заказа гарантируется частичным уникальным индексом по order_id.
Таким образом можно избежать дублирования данных в таблице order.
```

### Ловушка 2: `order.address_id` — принадлежность клиенту (BR-7.4)

**Как обеспечено, что адрес доставки принадлежит клиенту:**

```
Использован составной внешний ключ:
`FOREIGN KEY (client_id, address_id)
REFERENCES client_address(client_id, address_id)`.
Он разрешает заказ только на адрес, который уже связан с клиентом,
оформляющим заказ, и проверяет это на уровне БД согласно BR-7.4.
```

### Ловушка 3: `order_structure` — один ресторан в заказе (BR-7.3)

**Как обеспечено, что все блюда из `order.restaurant_id`:**

```
В order_structure добавлен restaurant_id. Составной FK
(order_id, restaurant_id) → "order"(order_id, restaurant_id) связывает
позицию заказа с рестораном, а составной FK
(product_id, restaurant_id) → product(product_id, restaurant_id) требует,
чтобы блюдо принадлежало тому же ресторану.
```

### Ловушка 4: `review` — полиморфизм (BR-9.1)

**Как реализована валидность `review.entity_id`:**

```
Выбранный подход: полиморфная модель

Для хранения отзывов используется общая таблица review, в которой находятся основные данные отзыва:
идентификатор, клиент, заказ, дата создания, текст, фотография, рейтинг,
тип объекта (entity_type) и идентификатор объекта (entity_id).

Связь реализована полиморфно в одной таблице review. Внешний ключ
для entity_id невозможен, поскольку он может ссылаться на product,
restaurant или order. Триггер validate_review_target() проверяет
существование объекта и его принадлежность заказу клиента.
```

---

## CHECK-ограничения

Каждое — с ссылкой на BR.

| Таблица | Столбец | Условие | BR | Обоснование |
|---|---|---|---|---|
|`restaurant`|`rating`|0 <= `rating` <= 5|BR-4.2|`CHECK (rating BETWEEN 0 AND 5)` на `restaurant.rating` — потому что BR-4.2 задаёт диапазон рейтинга|
|`restaurant`|`work_end`, `work_start`|`work_end` > `work_start`|BR-4.4|`CHECK (work_end > work_start)` на `restaurant` — потому что BR-4.4 требует, чтобы время закрытия было позже времени открытия|
|`courier`|`coefficient`|0.1 <= `coefficient` <= 0.5|BR-6.4|`CHECK (coefficient BETWEEN 0.1 AND 0.5)` на `courier.coefficient` — потому что BR-6.4 задаёт диапазон коэффициент |
|`courier`|`status`, `dismissal_date`|если `status` = 'уволен', то `dismissal_date` не должен быть `NULL`|BR-6.3|`CHECK (status = 'уволен' AND dismissal_date IS NOT NULL)` на `courier` — потому что BR-6.3 требует, чтобы уволенный курьер имел дату увольнения|
|`courier`|`dismissal_date`, `hire_date`|`dismissal_date` IS NULL или `dismissal_date` >= `hire_date`|BR-6.3|`CHECK (dismissal_date IS NULL OR dismissal_date >= hire_date)` запрещает увольнение до даты найма|
|`courier_pay`|`amount`|`amount` >= 0|BR-10.4|`CHECK (amount >= 0)` на `courier_pay.amount` — потому что BR-10.4 требует, чтобы сумма зарплаты была неотрицательной|
|`courier_pay`|`coefficient_used`|0.1 <= `coefficient_used` <= 0.5|BR-6.4|`CHECK (coefficient_used BETWEEN 0.1 AND 0.5)` на `courier_pay.coefficient_used` — потому что BR-6.4 задаёт диапазон коэффициента|
|`product`|`rating`|0 <= `rating` <= 5|BR-5.4|`CHECK (rating BETWEEN 0 AND 5)` на `product.rating` — потому что BR-5.4 задаёт диапазон рейтинга блюда|
|`product`|`price`|`price` >= 0|BR-5.3|`CHECK (price >= 0)` на `product.price` — потому что BR-5.3 требует, чтобы цена блюда была неотрицательной|
|`order`|`order_amount`|`order_amount` >= 0|BR-5.3|`CHECK (order_amount >= 0)` на `"order".order_amount` — потому что BR-5.3 требует, чтобы цена блюд была неотрицательной, а значит их сумма цен тоже должна быть неотрицательной|
|`order`|`total_amount`|`total_amount` >= 1000|BR-1.8, BR-7.11|`CHECK (total_amount >= 1000)` на `order.total_amount` — потому что BR-1.8 и BR-7.11 устанавливают минимальную сумму заказа 1000 рублей|
|`order`|`delivery_timestamp`|`delivery_timestamp` IS NULL или `delivery_timestamp` >= `order_timestamp`|BR-7.13|`CHECK` на `order` — потому что BR-7.13 запрещает время окончания доставки раньше времени создания заказа|
|`order`|`status`, `delivery_timestamp`|если `status` = 'доставлен', то `delivery_timestamp` не `NULL`|BR-7.12|`CHECK` на `"order"` — потому что BR-7.12 требует фиксировать время окончания доставки при статусе 'доставлен'|
|`order_structure`|`quantity`|`quantity` > 0|BR-7.15|`CHECK (quantity > 0)` на `order_structure.quantity` — потому что BR-7.15 требует, чтобы количество было положительным числом|
|`review`|`rating`|1 <= `rating` <= 5|BR-9.4|`CHECK (rating BETWEEN 1 AND 5)` на `review.rating` — потому что BR-9.4 задаёт диапазон рейтинга отзыва|

---

## UNIQUE-ограничения

| Таблица | Столбцы | BR | Обоснование |
|---|---|---|---|
|`client`|`login`|BR-2.2|`UNIQUE (login)` на `client` — потому что BR-2.2 требует уникальный логин|
|`client`|`phone_number`|BR-2.2|`UNIQUE (phone_number)` на `client` — потому что BR-2.2 требует уникальный номер телефона|
|`restaurant`|`address_id`|BR-3.3|`UNIQUE (address_id)` на `restaurant` — потому что BR-3.3 запрещает двум ресторанам делить один адрес|
|`payment`|`transaction_id`|BR-8.3|`UNIQUE (transaction_id)` на `payment` — потому что BR-8.3 требует уникальность внешнего идентификатора финансовой транзакции|
|`payment`|`order_id` WHERE `status = 'успех'`|BR-8.1|Частичный уникальный индекс `UNIQUE (order_id) WHERE status = 'успех'` гарантирует не более одной успешной попытки оплаты на заказ|
|`order_structure`|`order_id`, `product_id`|BR-7.16|`PRIMARY KEY (order_id, product_id)` на `order_structure` — потому что BR-7.16 запрещает повторять одно и то же блюдо в заказе|
|`product`|`product_id`, `restaurant_id`|BR-7.3|`UNIQUE (product_id, restaurant_id)` нужно для составного FK, проверяющего ресторан блюда|
|`order`|`order_id`, `restaurant_id`|BR-7.3|`UNIQUE (order_id, restaurant_id)` нужно для составного FK из таблицы `order_structure`, который будет гарантировать, что ресторан пренадлежит заказу|
|`order`|`order_id`, `client_id`|BR-9.2|`UNIQUE (order_id, client_id)` нужно для составного FK из таблицы `review`, который будет гарантировать, что заказ на который хочет сделать отзыв клиент пренадлежит ему|
|`review`|`order_id`, `entity_type`, `entity_id`|BR-9.5|`UNIQUE (order_id, entity_type, entity_id)` гарантирует не более одного отзыва на каждый объект в рамках заказа|


Если UNIQUE частичный (с `WHERE`) — укажи условие в столбце «Столбцы» или отдельной строкой.

---

## FK-ограничения

| Таблица | Столбцы | → Таблица | BR | Обоснование |
|---|---|---|---|---|
|`client_address`|`client_id`|`client`|BR-2.4|`FK (client_id) → client(client_id)` на `client_address` — потому что BR-2.4 указывает, что у клиента может быть один или более адресов|
|`client_address`|`address_id`|`address`|BR-3.4|`FK (address_id) → address(address_id)` на `client_address` — потому что BR-3.4 указывает, что адрес может быть использован в качестве адреса клиента и в таком качестве он может быть использован несколькими клиентами|
|`restaurant`|`address_id`|`address`|BR-3.3|`FK (address_id) → address(address_id)` на `restaurant` — потому что BR-3.3 требует, чтобы у каждого ресторана был адрес|
|`courier_pay`|`courier_id`|`courier`|BR-10.1|`FK (courier_id) → courier(courier_id)` на `courier_pay` — потому что BR-10.1 указывает, что каждый ежемесячный платеж принадлежат одному конкретному курьеру|
|`product`|`product_category_id`|`product_category`|BR-5.1|`FK (product_category_id) → product_category(product_category_id)` на `product` — потому что BR-5.1 требует, чтобы каждое блюдо принадлежало ровно одной категории|
|`product`|`restaurant_id`|`restaurant`|BR-5.1|`FK (restaurant_id) → restaurant(restaurant_id)` на `product` — потому что BR-5.1 требует, чтобы каждое блюдо принадлежало ровно одному ресторану|
|`order`|`courier_id`|`courier`|BR-7.5|`FK (courier_id) → courier(courier_id)` на `order` — потому что BR-7.5 требует, чтобы доставку выполнял курьер|
|`order`|`client_id`|`client`|BR-7.1|`FK (client_id) → client(client_id)` на `order` — потому что BR-7.1 требует, чтобы у заказа был клиент|
|`order`|`address_id`|`address`|BR-7.4|`FK (address_id) → address(address_id)` на `order` — потому что BR-7.4 требует, у заказа был адрес|
|`order`|`client_id`, `address_id`|`client_address`|BR-7.4|`FK (client_id, address_id) → client_address(client_id, address_id)` на `order` — потому что BR-7.4 требует, чтобы адрес доставки был адресом клиента, оформляющего заказ|
|`order`|`restaurant_id`|`restaurant`|BR-7.2|`FK (restaurant_id) → restaurant(restaurant_id)` на `order` — потому что BR-7.2 требует привязать заказ к одному ресторану|
|`payment`|`order_id`|`order`|BR-8.1|`FK (order_id) → order(order_id)` на `payment` — потому что BR-8.1 разрешает несколько попыток оплаты одного заказа|
|`order_structure`|`order_id`, `restaurant_id`|`order`|BR-7.3|`FK (order_id, restaurant_id) → order(order_id, restaurant_id)` на `order_structure`, потому что BR-7.3 требует, чтобы позиция заказа относилась к существующему заказу и его ресторану|
|`order_structure`|`product_id`, `restaurant_id`|`product`|BR-7.3|`FK (product_id, restaurant_id) → product(product_id, restaurant_id)` на `order_structure`, потому что BR-7.3 требует, чтобы блюдо позиции принадлежало ресторану заказа|
|`review`|`order_id`|`order`|BR-9.2|`FK (order_id, client_id) → order(order_id)` на `review`, потому что BR-9.2 требует чтобы отзыв был связан с заказом|
|`review`|`client_id`|`client`|BR-9.2|`FK (order_id, client_id) → client(client_id)` на `review`, потому что BR-9.2 требует чтобы отзыв был связан с клиентом|
|`review`|`order_id`, `client_id`|`order`|BR-9.2|`FK (order_id, client_id) → order(order_id, client_id)` на `review`, потому что BR-9.2 требует чтобы клиент который делает отзыв соответствовал клиенту, который сделал заказ|

Если FK составной — выпиши все столбцы.

---

## NOT NULL (только бизнес-обязательные)

Сюда — **только** те `NOT NULL`, которые нельзя объяснить очевидностью.

**Не дублируй:**
- PK (всегда NOT NULL по определению);
- FK на NOT NULL поле (очевидно, если родитель NOT NULL);
- поля из BR с явным «обязательно» — только если хочешь подчеркнуть, что это не случайность.

| Таблица | Столбец | BR | Обоснование |
|---|---|---|---|
|---|---|---|---|
|---|---|---|---|

---

## NULL (осознанно разрешено)

| Таблица | Столбец | BR | Почему NULL |
|---|---|---|---|
|`address`|`apartment_office`|BR-3.2|`NULL` на `apartment_office` — потому что BR-3.2 указывает, что Квартира/офис — необязательна|
|`restaurant`|`rating`|BR-9.7|`NULL` на `rating` — потому что BR-9.7 указывает, что если отзывов нет — рейтинг сущности = `NULL`|
|`product`|`rating`|BR-9.7|`NULL` на `product` — потому что BR-9.7 указывает, что если отзывов нет — рейтинг сущности = `NULL`|
|`courier`|`dismissal_date`|BR-6.3|`NULL` на `dismissal_date` — потому что BR-6.3 не требует дату увольнения у работающего курьера|
|`product`|`photo_url`|BR-5.6|`NULL` на `photo_url` — потому что BR-5.6 разрешает отсутствие фотографии блюда|
|`order`|`delivery_timestamp`|BR-7.12|`NULL` на `delivery_timestamp` — потому что BR-7.12 разрешает не заполнять время окончания доставки до статуса 'доставлен'|
|`order`|`pay_status`|BR-8.7|`NULL` на `pay_status` — потому что BR-8.7 требует наличие попыток платежа, для агрегированного статуса, если попыток еще не было, статус не может быть установлен и будет равен `NULL`|
|`order`|`description`|BR-7|`NULL` на `description` — комментарий - это дополнительная информация, которая не всегда нужна и оставлять её или нет решает сам пользователь|
|`review`|`photo_url`|BR-9.3|`NULL` на `photo_url` — потому что BR-9.3 разрешает отсутствие фотографии у отзыва|

---

## DEFAULT и GENERATED

| Таблица | Столбец | Что | Обоснование |
|---|---|---|---|
|`courier`|`status`|`DEFAULT 'свободен'`|Гарантирует, что у курьера будет валиднй начальный статус согласно BR-6.2|
|`order`|`order_timestamp`|`DEFAULT localtimestamp`|Гарантирует, что по требованию BR-7.1 у заказа будет валидное время создания|
|`order`|`status`|`DEFAULT 'создан'`|Гарантирует, что у заказа будет валидный начальный статус согласно BR-7.7|
|`order`|`pay_status`|`DEFAULT 'ожидает'`|Гарантирует, что у заказа будет валидный начальный статус оплаты заказа согласно BR-8.7|
|`order`|`commission`|`GENERATED ALWAYS AS (round(order_amount * 0.10, 2)) STORED`|Комиссия автоматически рассчитывается как 10% от стоимости блюд согласно BR-1.4 и BR-7.10|
|`order`|`total_amount`|`GENERATED ALWAYS AS (round(order_amount * 1.10, 2)) STORED`|Общая сумма автоматически рассчитывается как стоимость блюд плюс комиссия согласно BR-7.10|
|`review`|`review_timestamp`|`DEFAULT localtimestamp`|Гарантирует, что по требованию BR-9.3 у отзыва будет валидное время создания|

Если `commission` и/или `total_amount` — `GENERATED ALWAYS AS` — обоснуй здесь. Если обычные поля с `CHECK` — тоже обоснуй выбор.

---

## Триггеры
```
BR-8.4. Сумма попытки оплаты равна общей сумме заказа.
Бизнес правило реализовано за счет триггерной функции check_payment_amount(), которая не позволит сумме платежа отличаться от общей суммы заказа

BR-7.16. Одно и то же блюдо не может встречаться в заказе дважды. Вместо этого увеличивается количество.
Бизнес правило реализовано за счет триггерной функции increase_product_quantity(),
которая увеличит колличество, если позиция уже встречалась в заказе.

BR-9.2. Отзыв всегда связан с конкретным заказом клиента. Клиент может оставить отзыв только на то, что он заказал.
Бизнес правило реализовано за счет триггерной функции
validate_review_target()
которая проверяет, чтобы сущность на которую делается
отзыв принадлежала заказу клиента.
```

---

## Нормализация (3НФ)

Короткое обоснование, что все таблицы в 3НФ:

```
[Своими словами: все неключевые атрибуты зависят от полного PK (2НФ);
нет транзитивных зависимостей (3НФ).

Таблицы client, address, restaurant, courier, 
product_category, product, payment, order_structure и review находятся в 3НФ,
поскольку все неключевые атрибуты зависят только от простого первичного ключа и не зависят друг от друга.

Таблица client_address находится в 3НФ так как оба атрибута являются частью составного первичного ключа и неключевых атрибутов нет.

Таблица courier_pay находится в 3НФ так как неключевые атрибуты amount
и coefficient_used зависят от всего составного первичного ключа (year, month, courier_id) и других зависимостей у них нет.

Таблица order формально не находится в 3НФ из-за вычисляемых полей order.commission и order.total_amount, которые имеют транзитивные зависимости.

Особые случаи:

- order.commission = 10% от order_amount — вычисляемое. Что сделал и почему.
Сделал вычислямое поле generated always as (round(order_amount * 0.10, 2)) stored потому что,
что это ускорит чтение данных, так как при каждом изменении стоимости заказа,
поле commision будет автоматически пересчитываться, при этом запись данных будет происходить дольше.

- order.total_amount = order_amount + commission — вычисляемое. Что сделал и почему.
Сделал вычислямое поле total_amount numeric(10,2) generated always as (round(order_amount * 1.10, 2)) stored потому что,
что это ускорит чтение данных, так как при каждом изменении стоимости заказа,
поле total_amount будет автоматически пересчитываться, при этом запись данных будет происходить дольше.

- product.rating и restaurant.rating — агрегаты, поддерживаются триггером rating_change. Это осознанная денормализация для скорости чтения — обоснуй.

Хранение агрегированного рейтинга непосредственно в таблицах product и restaurant направленно на повышение производительности чтения.
Это позволяет получать рейтинг без выполнения дополнительных агрегатных запросов (AVG) к таблице отзывов при каждом обращении.

- review.entity_id + entity_type — полиморфизм. Не нарушает 3НФ, но требует обоснования (см. ловушку 4).]
```
