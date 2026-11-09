create table ginzburg_food.client (
	client_id uuid default exts.uuid_generate_v4(),
	login varchar(50) not null,
	password varchar(50) not null,
	phone_number char(11) not null
);

create table ginzburg_food.address (
	address_id uuid default exts.uuid_generate_v4(),
	street varchar(200) not null,
	house_number varchar(20) not null,
	apartment_office varchar(20)
);

create table ginzburg_food.client_address (
	client_id uuid not null,
	address_id uuid not null
);

create table ginzburg_food.restaurant (
	restaurant_id uuid default exts.uuid_generate_v4(),
	restaurant_name varchar(100) not null,
	address_id uuid not null,
	description text not null,
	work_start time not null,
	work_end time not null,
	company_details text not null,
	rating numeric(3,2),
	status ginzburg_food.restaurant_status not null
);

create table ginzburg_food.courier (
	courier_id uuid default exts.uuid_generate_v4(),
	fio varchar(150) not null,
	phone_number char(11) not null,
	status ginzburg_food.courier_status not null default 'свободен',
	hire_date date not null,
	dissmissal_date date,
	coefficient numeric(2,1) not null default 0.1
);

create table ginzburg_food.courier_pay (
	year int not null,
	month int not null,
	courier_id uuid not null,
	amount numeric(10,2) not null,
	coefficient_used numeric(2,1) not null
);

create table ginzburg_food.product_category (
	product_category_id uuid default exts.uuid_generate_v4(),
	product_category_name varchar(100) not null
);

create table ginzburg_food.product (
	product_id uuid default exts.uuid_generate_v4(),
	product_name varchar(100) not null,
	product_category_id uuid not null,
	price numeric(10,2) not null,
	restaurant_id uuid not null,
	photo_url text,
	rating numeric(3,2),
	status ginzburg_food.product_status not null,
	description text not null
);

create table ginzburg_food."order" (
	order_id uuid default exts.uuid_generate_v4(),
	courier_id uuid not null,
	client_id uuid not null,
	address_id uuid not null,
	restaurant_id uuid not null,
	order_timestamp timestamp not null default localtimestamp,
	delivery_timestamp timestamp,
	order_amount numeric(10,2) not null,
	commission numeric(10,2) generated always as (round(order_amount * 0.10, 2)) stored,
	total_amount numeric(10,2) generated always as (order_amount + round(order_amount * 0.10, 2)) stored,
	status ginzburg_food.order_status not null default 'создан',
	pay_status ginzburg_food.order_pay_status,
	description text not null
);

create table ginzburg_food.payment (
	payment_id uuid default exts.uuid_generate_v4(),
	order_id uuid not null,
	payment_type ginzburg_food.payment_type not null,
	amount numeric(10,2) not null,
	transaction_id varchar(255) not null,
	transaction_timestamp timestamp not null default localtimestamp,
	status ginzburg_food.payment_status not null
);

create table ginzburg_food.order_structure (
	order_id uuid not null,
	product_id uuid not null,
	restaurant_id uuid not null,
	quantity numeric(10,3) not null
);

create table ginzburg_food.review (
    review_id uuid default exts.uuid_generate_v4(),
		client_id uuid not null,
    review_timestamp timestamp not null default localtimestamp,
		entity_type ginzburg_food.review_entity_type not null,
		order_id uuid not null,
    description text not null,
    photo_url text,
    rating numeric(3,2) not null
);

create table ginzburg_food.review_product (
    review_id uuid not null,
    order_id uuid not null,
    product_id uuid not null
);

create table ginzburg_food.review_restaurant (
    review_id uuid not null,
    order_id uuid not null,
    restaurant_id uuid not null
);

create table ginzburg_food.review_order (
    review_id uuid not null,
    order_id uuid not null
);