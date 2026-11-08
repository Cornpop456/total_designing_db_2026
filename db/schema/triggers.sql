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