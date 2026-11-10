-- ginzburg_food.client

alter table ginzburg_food.client
	add constraint client_pkey primary key (client_id),

	add constraint client_login_key unique (login),

	add constraint client_phone_number_key unique (phone_number);

-- ginzburg_food.address

alter table ginzburg_food.address
	add constraint address_pkey primary key (address_id);

-- ginzburg_food.client_address

alter table ginzburg_food.client_address
	add constraint client_address_pkey primary key (client_id, address_id),

	add constraint client_address_client_id_fkey 
		foreign key (client_id) 
		references ginzburg_food.client(client_id)
		on delete cascade,

	add constraint client_address_address_id_fkey 
		foreign key (address_id) 
		references ginzburg_food.address(address_id);

-- ginzburg_food.restaurant

alter table ginzburg_food.restaurant
	add constraint restaurant_pkey primary key (restaurant_id),

	add constraint restaurant_address_id_fkey 
		foreign key (address_id) 
		references ginzburg_food.address(address_id),

	add constraint restaurant_address_id_key unique (address_id),

	add constraint restaurant_rating_check
		check (rating between 0 and 5),

	add constraint restaurant_work_time_check
    check (work_end > work_start);

-- ginzburg_food.courier

alter table ginzburg_food.courier
	add constraint courier_pkey primary key (courier_id),

	add constraint courier_coefficient_check
		check (coefficient between 0.1 and 0.5),

	add constraint courier_dismissal_date_check
    check (
        status != 'уволен'
        or dismissal_date  is not null
    ),

	add constraint courier_dismissal_after_hire_check
		check (
			dismissal_date  is null
			or dismissal_date  >= hire_date
    );

-- ginzburg_food.courier_pay

alter table ginzburg_food.courier_pay
	add constraint courier_pay_pkey primary key (year, month, courier_id),

	add constraint courier_pay_courier_id_fkey
		foreign key (courier_id)
		references ginzburg_food.courier(courier_id),

	add constraint courier_pay_amount_check
		check (amount >= 0),

	add constraint courier_pay_coefficient_used_check
		check (coefficient_used between 0.1 and 0.5);

-- ginzburg_food.product_category

alter table ginzburg_food.product_category
	add constraint product_category_pkey 
	primary key (product_category_id);

-- ginzburg_food.product

alter table ginzburg_food.product
	add constraint product_pkey primary key (product_id),

	add constraint product_product_category_id_fkey
		foreign key (product_category_id)
		references ginzburg_food.product_category(product_category_id),

	add constraint product_restaurant_id_fkey
		foreign key (restaurant_id)
		references ginzburg_food.restaurant(restaurant_id),

	add constraint product_id_restaurant_id_key unique (product_id, restaurant_id),
	
	add constraint product_rating_check
		check (rating between 0 and 5),

	add constraint product_price_check
		check (price >= 0);

-- ginzburg_food.order

alter table ginzburg_food."order"
	add constraint order_pkey primary key (order_id),

	add constraint order_courier_id_fkey
		foreign key (courier_id)
		references ginzburg_food.courier(courier_id),

	add constraint order_client_address_fkey
		foreign key (client_id, address_id)
		references ginzburg_food.client_address(client_id, address_id),

	add constraint order_restaurant_id_fkey
		foreign key (restaurant_id)
		references ginzburg_food.restaurant(restaurant_id),

	add constraint order_id_restaurant_id_key 
		unique (order_id, restaurant_id),

	add constraint order_id_client_id_key
    unique (order_id, client_id),

	add constraint order_amount_check
		check (order_amount >= 0),

	add constraint order_minimum_total_check
		check (total_amount >= 1000),

	add constraint order_delivery_timestamp_check
		check (
			delivery_timestamp is null
			or delivery_timestamp >= order_timestamp
		),

	add constraint order_delivered_timestamp_check
		check (
			status != 'доставлен'
			or delivery_timestamp is not null
		);

-- ginzburg_food.payment

alter table ginzburg_food.payment
	add constraint payment_pkey primary key (payment_id),

	add constraint payment_order_id_fkey
		foreign key (order_id)
		references ginzburg_food."order"(order_id),

	add constraint payment_transaction_id_key unique (transaction_id);

create unique index payment_one_success_idx
	on ginzburg_food.payment (order_id)
	where status = 'успех';

-- ginzburg_food.order_structure

alter table ginzburg_food.order_structure
	add constraint order_structure_pkey primary key (order_id, product_id),

	add constraint order_structure_order_fkey
		foreign key (order_id, restaurant_id)
		references ginzburg_food."order"(order_id, restaurant_id),

	add constraint order_structure_product_fkey
		foreign key (product_id, restaurant_id)
		references ginzburg_food.product(product_id, restaurant_id),

	add constraint order_structure_quantity_check
		check (quantity > 0);

-- ginzburg_food.review

alter table ginzburg_food.review
    add constraint review_pkey primary key (review_id),

    add constraint review_order_entity_key
        unique (order_id, entity_type, entity_id),

    add constraint review_order_id_fkey
        foreign key (order_id, client_id)
        references ginzburg_food."order"(order_id, client_id),

    add constraint review_rating_check
        check (rating between 1 and 5);