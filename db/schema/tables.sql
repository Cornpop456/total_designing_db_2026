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