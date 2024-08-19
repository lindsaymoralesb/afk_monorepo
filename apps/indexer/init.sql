CREATE SEQUENCE token_launch_id_seq;

create table token_launch(
    network text,
    block_hash text,
    block_number bigint,
    block_timestamp timestamp,
    transaction_hash text,
    memecoin_address text,
    quote_token text,
    exchange_name text,
    created_at timestamp default current_timestamp,
    total_supply text,
    current_supply text,
    liquidity_raised text,
    price text,
    _cursor bigint
);

create table token_deploy(
    network text,
    block_hash text,
    block_number bigint,
    block_timestamp timestamp,
    transaction_hash text,
    memecoin_address text,
    owner_address text,
    name text,
    symbol text,
    initial_supply text,
    total_supply text,
    created_at timestamp default current_timestamp,
    _cursor bigint
);


create table buy_token(
    network text,
    block_hash text,
    block_number bigint,
    block_timestamp timestamp,
    transaction_hash text,
    memecoin_address text,
    owner_address text,
    last_price text,
    quote_amount text,
    coin_received text,
    initial_supply text,
    created_at timestamp default current_timestamp,
    total_supply text,
    current_supply text,
    liquidity_raised text,
    price text,
    amount text,
    _cursor bigint
);

create table unrugmeme_transfers(
    network text,
    block_hash text,
    block_number bigint,
    block_timestamp timestamp,
    transaction_hash text,
    transfer_id text unique primary key,
    from_address text,
    to_address text,
    memecoin_address text,
    amount text,
    created_at timestamp default current_timestamp,
    _cursor bigint
);

create table unrugmeme_deploy(
    network text,
    block_hash text,
    block_number bigint,
    block_timestamp timestamp,
    transaction_hash text,
    memecoin_address text unique primary key,
    owner_address text,
    name text,
    symbol text,
    initial_supply text,
    created_at timestamp default current_timestamp,
    _cursor bigint
);

create table unrugmeme_launch(
    network text,
    block_hash text,
    block_number bigint,
    block_timestamp timestamp,
    transaction_hash text,
    memecoin_address text unique primary key,
    quote_token text,
    exchange_name text,
    created_at timestamp default current_timestamp,
    _cursor bigint
);