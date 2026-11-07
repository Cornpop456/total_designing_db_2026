-- ginzburg_food.client

alter table only ginzburg_food.client
	add constraint client_pkey primary key (client_id);

alter table only ginzburg_food.client
	add constraint client_login_key unique (login);

alter table only ginzburg_food.client
	add constraint client_phone_number_key unique (phone_number);

-- ginzburg_food.address

alter table only ginzburg_food.address
	add constraint address_pkey primary key (address_id);

-- ginzburg_food.client_address

alter table only ginzburg_food.client_address
	add constraint client_address_pkey primary key (client_id, address_id);

alter table only ginzburg_food.client_address
	add constraint client_address_client_id_fkey 
	foreign key (client_id) 
	references ginzburg_food.client(client_id)
	on delete cascade;

alter table only ginzburg_food.client_address
	add constraint client_address_address_id_fkey 
	foreign key (address_id) 
	references ginzburg_food.address(address_id);

-- ginzburg_food.restaurant

alter table only ginzburg_food.restaurant
	add constraint restaurant_pkey primary key (restaurant_id);

alter table only ginzburg_food.restaurant
	add constraint restaurant_address_id_fkey 
	foreign key (address_id) 
	references ginzburg_food.address(address_id);

alter table only ginzburg_food.restaurant
    add constraint restaurant_address_id_key unique (address_id);

alter table only ginzburg_food.restaurant
	add constraint restaurant_rating_check
	check (rating between 0 and 5);

alter table only ginzburg_food.restaurant
    add constraint restaurant_work_time_check
    check (work_end > work_start);

-- ginzburg_food.courier

alter table only ginzburg_food.courier
	add constraint courier_pkey primary key (courier_id);

alter table only ginzburg_food.courier
	add constraint courier_coefficient_check
	check (coefficient between 0.1 and 0.5);

alter table only ginzburg_food.courier
	add constraint courier_dissmissal_date_check
	check (
	(status = 'уволен' and dissmissal_date is not null)
	);

-- ginzburg_food.courier_pay

alter table only ginzburg_food.courier_pay
	add constraint courier_pay_pkey primary key (year, month, courier_id);

alter table only ginzburg_food.courier_pay
	add constraint courier_pay_courier_id_fkey
	foreign key (courier_id)
	references ginzburg_food.courier(courier_id)
	on delete cascade;

alter table only ginzburg_food.courier_pay
	add constraint courier_pay_amount_check
	check (amount >= 0);

alter table only ginzburg_food.courier_pay
	add constraint courier_pay_coefficient_used_check
	check (coefficient_used between 0.1 and 0.5);

-- ginzburg_food.product_category

alter table only ginzburg_food.product_category
	add constraint product_category_pkey 
	primary key (product_category_id);

-- ginzburg_food.product

alter table only ginzburg_food.product
	add constraint product_pkey primary key (product_id);

alter table only ginzburg_food.product
	add constraint product_product_category_id_fkey
	foreign key (product_category_id)
	references ginzburg_food.product_category(product_category_id);

alter table only ginzburg_food.product
	add constraint product_restaurant_id_fkey
	foreign key (restaurant_id)
	references ginzburg_food.restaurant(restaurant_id);

alter table only ginzburg_food.product
	add constraint product_rating_check
	check (rating between 0 and 5);

alter table only ginzburg_food.product
	add constraint product_price_check
	check (price >= 0);

alter table only ginzburg_food.product
		add constraint product_product_category_id_restaurant_id_key
		unique (product_category_id, restaurant_id);