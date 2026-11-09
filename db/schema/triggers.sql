-- ginzburg_food.payment

create function ginzburg_food.check_payment_amount()
returns trigger
language plpgsql
as $$
declare
    v_total_amount numeric(10,2);
begin
    select o.total_amount
    into v_total_amount
    from ginzburg_food."order" o
    where o.order_id = new.order_id;

    if v_total_amount is distinct from new.amount then
        raise exception 'Payment amount must equal order total amount';
    end if;

    return new;
end;
$$;

create trigger payment_amount_check
before insert or update of order_id, amount
on ginzburg_food.payment
for each row
execute function ginzburg_food.check_payment_amount();

-- ginzburg_food.order_structure

create function ginzburg_food.increase_product_quantity()
returns trigger
language plpgsql
as $$
begin
    if new.quantity <= 0 then
        raise exception 'Order structure quantity must be greater than zero';
    end if;

    update ginzburg_food.order_structure
    set quantity = quantity + new.quantity
    where order_id = new.order_id
      and product_id = new.product_id;

    if found then
        return null;
    end if;

    return new;
end;
$$;

create trigger order_structure_merge
before insert
on ginzburg_food.order_structure
for each row
execute function ginzburg_food.increase_product_quantity();

-- ginzburg_food.review

create function ginzburg_food.validate_review_target()
returns trigger
language plpgsql
as $$
begin
    if new.entity_type = 'блюдо'
       and not exists (
           select 1
           from ginzburg_food.order_structure os
           where os.order_id = new.order_id
             and os.product_id = new.entity_id
       ) then
        raise exception 'Reviewed product must belong to the order';
    elsif new.entity_type = 'ресторан'
          and not exists (
              select 1
              from ginzburg_food."order" o
              where o.order_id = new.order_id
                and o.restaurant_id = new.entity_id
          ) then
        raise exception 'Reviewed restaurant must belong to the order';
    elsif new.entity_type = 'заказ'
          and new.entity_id != new.order_id then
        raise exception 'Reviewed order must match order_id';
    end if;

    return new;
end;
$$;

create trigger review_target_validation
before insert or update of entity_type, entity_id, order_id
on ginzburg_food.review
for each row
execute function ginzburg_food.validate_review_target();
