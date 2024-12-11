#[cfg(test)]
mod unrug_tests {
    use afk_launchpad::interfaces::factory::{IFactory, IFactoryDispatcher, IFactoryDispatcherTrait};
    use afk_launchpad::launchpad::unrug::{
        IUnrugLiquidityDispatcher, IUnrugLiquidityDispatcherTrait,
        // Event as LaunchpadEvent
    };
    use afk_launchpad::tokens::erc20::{IERC20, IERC20Dispatcher, IERC20DispatcherTrait};
    use afk_launchpad::tokens::memecoin::{IMemecoin, IMemecoinDispatcher, IMemecoinDispatcherTrait};
    use afk_launchpad::types::launchpad_types::{
        CreateToken, TokenQuoteBuyCoin, BondingType, CreateLaunch, SetJediswapNFTRouterV2,
        SetJediswapV2Factory, SupportedExchanges, EkuboLP, EkuboPoolParameters, TokenLaunch,
        EkuboLaunchParameters, LaunchParameters, SharesTokenUser
    };

    use core::num::traits::Zero;
    use core::traits::Into;
    use ekubo::interfaces::core::{ICore, ICoreDispatcher, ICoreDispatcherTrait};
    use ekubo::interfaces::positions::{IPositionsDispatcher, IPositionsDispatcherTrait};
    use ekubo::interfaces::token_registry::{
        ITokenRegistryDispatcher, ITokenRegistryDispatcherTrait,
    };

    use ekubo::types::i129::i129;
    use ekubo::types::keys::PoolKey;
    use openzeppelin::utils::serde::SerializedAppend;
    use snforge_std::{
        declare, ContractClass, ContractClassTrait, spy_events, start_cheat_caller_address,
        start_cheat_caller_address_global, stop_cheat_caller_address,
        stop_cheat_caller_address_global, start_cheat_block_timestamp, DeclareResultTrait,
        EventSpyAssertionsTrait
    };
    use starknet::syscalls::call_contract_syscall;

    use starknet::{ContractAddress, ClassHash, class_hash::class_hash_const};

    // fn DEFAULT_INITIAL_SUPPLY() -> u256 {
    //     // 21_000_000 * pow_256(10, 18)
    //     100_000_000
    //     // * pow_256(10, 18)
    // }
    // const THRESHOLD_LIQUIDITY(): u256 = 10 * pow_256(10, 18);

    fn DEFAULT_INITIAL_SUPPLY() -> u256 {
        100_000_000_u256* pow_256(10, 18)
    }

    


    // fn DEFAULT_INITIAL_SUPPLY() -> u256 {
    //     // 21_000_000 * pow_256(10, 18)
    //     100_000_u256
    //     // * pow_256(10, 18)
    // }

    // const INITIAL_KEY_PRICE:u256=1/100;
    const INITIAL_SUPPLY_DEFAULT: u256 = 100_000_000;
    const INITIAL_KEY_PRICE: u256 = 1;
    const STEP_LINEAR_INCREASE: u256 = 1;
    // const THRESHOLD_LIQUIDITY: u256 = 10;
    const THRESHOLD_MARKET_CAP: u256 = 500;
    const MIN_FEE_PROTOCOL: u256 = 10; //0.1%
    const MAX_FEE_PROTOCOL: u256 = 1000; //10%
    const MID_FEE_PROTOCOL: u256 = 100; //1%
    const MIN_FEE_CREATOR: u256 = 100; //1%
    const MID_FEE_CREATOR: u256 = 1000; //10%
    const MAX_FEE_CREATOR: u256 = 5000; //50%
    // const INITIAL_KEY_PRICE: u256 = 1 / 10_000;
    // const THRESHOLD_LIQUIDITY: u256 = 10;
    // const THRESHOLD_LIQUIDITY: u256 = 10_000;

    const RATIO_SUPPLY_LAUNCH: u256 = 5;
    const LIQUIDITY_SUPPLY: u256 = INITIAL_SUPPLY_DEFAULT / RATIO_SUPPLY_LAUNCH;
    const BUYABLE: u256 = INITIAL_SUPPLY_DEFAULT / RATIO_SUPPLY_LAUNCH;

    const LIQUIDITY_RATIO: u256 = 5;
    // const THRESHOLD_LIQUIDITY: u256 = 10 * pow_256(10, 18);

    fn THRESHOLD_LIQUIDITY() -> u256 {
        10_u256 * pow_256(10, 18)
    }
    fn FACTORY_ADDRESS() -> ContractAddress {
        0x01a46467a9246f45c8c340f1f155266a26a71c07bd55d36e8d1c7d0d438a2dbc.try_into().unwrap()
    }

    fn EKUBO_EXCHANGE_ADDRESS() -> ContractAddress {
        0x00000005dd3d2f4429af886cd1a3b08289dbcea99a294197e9eb43b0e0325b4b.try_into().unwrap()
    }

    // fn EKUBO_EXCHANGE_ADDRESS() -> ContractAddress {
    //     0x02bd1cdd5f7f17726ae221845afd9580278eebc732bc136fe59d5d94365effd5.try_into().unwrap()
    // }

    fn EKUBO_CORE() -> ContractAddress {
        0x00000005dd3d2f4429af886cd1a3b08289dbcea99a294197e9eb43b0e0325b4b.try_into().unwrap()
    }

    fn EKUBO_POSITIONS() -> ContractAddress {
        0x02e0af29598b407c8716b17f6d2795eca1b471413fa03fb145a5e33722184067.try_into().unwrap()
    }

    fn EKUBO_REGISTRY() -> ContractAddress {
        0x0013e25867b6eef62703735aa4cfa7754e72f4e94a56c9d3d9ad8ebe86cee4aa.try_into().unwrap()
    }


    // Mainnets

    fn JEDISWAP_FACTORY() -> ContractAddress {
        0x01aa950c9b974294787de8df8880ecf668840a6ab8fa8290bf2952212b375148.try_into().unwrap()
    }

    fn JEDISWAP_NFT_V2() -> ContractAddress {
        0x0469b656239972a2501f2f1cd71bf4e844d64b7cae6773aa84c702327c476e5b.try_into().unwrap()
    }

    // SEPOLIA

    // fn JEDISWAP_FACTORY() -> ContractAddress {
    //     0x050d3df81b920d3e608c4f7aeb67945a830413f618a1cf486bdcce66a395109c.try_into().unwrap()
    // }

    // fn JEDISWAP_NFT_V2() -> ContractAddress {
    //     0x024fd9721eea36cf8cebc226fd9414057bbf895b47739822f849f622029f9399.try_into().unwrap()
    // }

    fn SALT() -> felt252 {
        'salty'.try_into().unwrap()
    }

    // Constants
    fn OWNER() -> ContractAddress {
        // 'owner'.try_into().unwrap()
        123.try_into().unwrap()
    }

    fn RECIPIENT() -> ContractAddress {
        'recipient'.try_into().unwrap()
    }

    fn SPENDER() -> ContractAddress {
        'spender'.try_into().unwrap()
    }

    fn ALICE() -> ContractAddress {
        'alice'.try_into().unwrap()
    }

    fn BOB() -> ContractAddress {
        'bob'.try_into().unwrap()
    }

    fn NAME() -> felt252 {
        'name'.try_into().unwrap()
    }

    fn SYMBOL() -> felt252 {
        'symbol'.try_into().unwrap()
    }

    // Math
    fn pow_256(self: u256, mut exponent: u8) -> u256 {
        if self.is_zero() {
            return 0;
        }
        let mut result = 1;
        let mut base = self;

        loop {
            if exponent & 1 == 1 {
                result = result * base;
            }

            exponent = exponent / 2;
            if exponent == 0 {
                break result;
            }

            base = base * base;
        }
    }

    // Declare and create all contracts
    // Return sender_address, Erc20 quote and Launchpad contract
    fn request_fixture() -> (ContractAddress, IERC20Dispatcher, IUnrugLiquidityDispatcher) {
        // println!("request_fixture");
        let erc20_class = declare_erc20();
        let meme_class = declare_memecoin();
        let launch_class = declare_unrug_liquidity();
        request_fixture_custom_classes(*erc20_class, *meme_class, *launch_class)
    }

    fn request_fixture_custom_classes(
        erc20_class: ContractClass, meme_class: ContractClass, launch_class: ContractClass
    ) -> (ContractAddress, IERC20Dispatcher, IUnrugLiquidityDispatcher) {
        let sender_address: ContractAddress = 123.try_into().unwrap();
        let erc20 = deploy_erc20(erc20_class, 'USDC token', 'USDC', 1_000_000, sender_address);
        let token_address = erc20.contract_address.clone();
        let launchpad = deploy_launchpad(
            launch_class,
            sender_address,
            token_address.clone(),
            INITIAL_KEY_PRICE,
            STEP_LINEAR_INCREASE,
            meme_class.class_hash,
            THRESHOLD_LIQUIDITY(),
            THRESHOLD_MARKET_CAP,
            FACTORY_ADDRESS(),
            EKUBO_REGISTRY(),
            EKUBO_CORE(),
            EKUBO_POSITIONS(),
            EKUBO_EXCHANGE_ADDRESS()
            // ITokenRegistryDispatcher { contract_address: EKUBO_REGISTRY() },
        // ICoreDispatcher { contract_address: EKUBO_CORE() },
        // IPositionsDispatcher { contract_address: EKUBO_POSITIONS() },
        );
        // let launchpad = deploy_launchpad(
        //     launch_class,
        //     sender_address,
        //     token_address.clone(),
        //     INITIAL_KEY_PRICE * pow_256(10,18),
        //     // INITIAL_KEY_PRICE,
        //     // STEP_LINEAR_INCREASE,
        //     STEP_LINEAR_INCREASE * pow_256(10,18),
        //     erc20_class.class_hash,
        //     THRESHOLD_LIQUIDITY() * pow_256(10,18),
        //     // THRESHOLD_LIQUIDITY(),
        //     THRESHOLD_MARKET_CAP * pow_256(10,18),
        //     // THRESHOLD_MARKET_CAP
        // );

        start_cheat_caller_address(launchpad.contract_address, OWNER());
        launchpad.set_address_jediswap_factory_v2(JEDISWAP_FACTORY());
        launchpad.set_address_jediswap_nft_router_v2(JEDISWAP_NFT_V2());
        (sender_address, erc20, launchpad)
    }

    fn deploy_launchpad(
        class: ContractClass,
        admin: ContractAddress,
        token_address: ContractAddress,
        initial_key_price: u256,
        step_increase_linear: u256,
        coin_class_hash: ClassHash,
        threshold_liquidity: u256,
        threshold_marketcap: u256,
        factory_address: ContractAddress,
        ekubo_registry: ContractAddress,
        core: ContractAddress,
        positions: ContractAddress,
        ekubo_exchange_address: ContractAddress,
        // ekubo_registry: ITokenRegistryDispatcher,
    // core: ICoreDispatcher,
    // positions: IPositionsDispatcher,
    ) -> IUnrugLiquidityDispatcher {
        // println!("deploy marketplace");
        let mut calldata = array![admin.into()];
        calldata.append_serde(initial_key_price);
        calldata.append_serde(token_address);
        calldata.append_serde(step_increase_linear);
        calldata.append_serde(coin_class_hash);
        calldata.append_serde(threshold_liquidity);
        calldata.append_serde(threshold_marketcap);
        calldata.append_serde(factory_address);
        calldata.append_serde(ekubo_registry);
        calldata.append_serde(core);
        calldata.append_serde(positions);
        calldata.append_serde(ekubo_exchange_address);
        let (contract_address, _) = class.deploy(@calldata).unwrap();
        IUnrugLiquidityDispatcher { contract_address }
    }

    fn declare_unrug_liquidity() -> @ContractClass {
        declare("UnrugLiquidity").unwrap().contract_class()
    }

    fn declare_erc20() -> @ContractClass {
        declare("ERC20").unwrap().contract_class()
    }

    fn declare_memecoin() -> @ContractClass {
        declare("Memecoin").unwrap().contract_class()
    }

    fn deploy_erc20(
        class: ContractClass,
        name: felt252,
        symbol: felt252,
        initial_supply: u256,
        recipient: ContractAddress
    ) -> IERC20Dispatcher {
        let mut calldata = array![];

        name.serialize(ref calldata);
        symbol.serialize(ref calldata);
        (2 * initial_supply).serialize(ref calldata);
        recipient.serialize(ref calldata);
        18_u8.serialize(ref calldata);

        let (contract_address, _) = class.deploy(@calldata).unwrap();

        IERC20Dispatcher { contract_address }
    }

    #[test]
    #[fork("Mainnet")]
    fn test_add_liquidity_ekubo() {
        let (sender, erc20, launchpad) = request_fixture();
        start_cheat_caller_address(launchpad.contract_address, OWNER());
        let token_address = launchpad
            .create_token(
                symbol: SYMBOL(),
                name: NAME(),
                initial_supply: DEFAULT_INITIAL_SUPPLY(),
                contract_address_salt: SALT()
            );
        println!("token_address ekubo launch: {:?}", token_address);
        println!(
            "Balance of launchpad: {:?}",
            IERC20Dispatcher { contract_address: token_address }
                .balance_of(launchpad.contract_address)
        );
        // let launch = launchpad.get_coin_launch(token_address);
        let starting_price = i129 { sign: true, mag: 100_u128 };
        let memecoin = IERC20Dispatcher { contract_address: token_address };

        let total_supply: u256 = memecoin.total_supply();
        let total_token_holded: u256 = total_supply / LIQUIDITY_RATIO;

        // let total_token_holded: u256 = 1_000;
        let lp_meme_supply = total_supply - total_token_holded;
        // let lp_meme_supply = memecoin.total_supply();
        println!("lp_meme_supply {:?}", lp_meme_supply);
        start_cheat_caller_address(memecoin.contract_address, OWNER());
        // memecoin.transfer(launchpad.contract_address, DEFAULT_INITIAL_SUPPLY());
        // memecoin.transfer(launchpad.contract_address, lp_meme_supply);
        memecoin.approve(launchpad.contract_address, lp_meme_supply);
        // memecoin.approve(EKUBO_EXCHANGE_ADDRESS(), lp_meme_supply);
        // let quote_token = IERC20Dispatcher { contract_address: erc20.contract_address };
        // stop_cheat_caller_address(memecoin.contract_address);
        memecoin.approve(EKUBO_EXCHANGE_ADDRESS(), lp_meme_supply);

        let params: EkuboLaunchParameters = EkuboLaunchParameters {
            // owner: launchpad.contract_address,
            owner: OWNER(),
            token_address: token_address,
            quote_address: erc20.contract_address,
            lp_supply: lp_meme_supply,
            // lp_supply: launch.liquidity_raised,
            pool_params: EkuboPoolParameters {
                fee: 0xc49ba5e353f7d00000000000000000,
                tick_spacing: 5000,
                starting_price,
                bound: 88719042,
            }
        };
        // erc20.transfer(launchpad.contract_address, lp_supply);
        start_cheat_caller_address(launchpad.contract_address, OWNER());
        println!("add liquidity ekubo");
        launchpad.launch_on_ekubo(token_address, params);
        // stop_cheat_caller_address(launchpad.contract_address);
    }

    #[test]
    #[fork("Mainnet")]
    fn test_create_and_add_liquidity_unrug_liq_lp() {
        let (b, quote_token, launchpad) = request_fixture();
        let starting_price = i129 { sign: true, mag: 4600158 }; // 0.01ETH/MEME
        let quote_to_deposit = 100;

        let total_supply = DEFAULT_INITIAL_SUPPLY();
        // start_cheat_caller_address(launchpad.contract_address, OWNER());
        let token_address = launchpad
            .create_token(
                symbol: SYMBOL(),
                name: NAME(),
                initial_supply: DEFAULT_INITIAL_SUPPLY(),
                contract_address_salt: SALT() + 1
            );
        println!("token_address unrug lp withouth launch curve: {:?}", token_address.clone());

        // start_cheat_caller_address(token_address, launchpad.contract_address);

        let memecoin = IERC20Dispatcher { contract_address: token_address };
        start_cheat_caller_address(memecoin.contract_address, OWNER());

        let amount_meme_supply_liq = DEFAULT_INITIAL_SUPPLY() / LIQUIDITY_RATIO;

        let lp_meme_supply = amount_meme_supply_liq.clone();

        // memecoin.transfer(launchpad.contract_address, amount_meme_supply_liq);
        let mut balance_meme_launch = memecoin.balance_of(launchpad.contract_address);
        println!("balance meme {:?}", balance_meme_launch);

        let mut balance_meme_launch_owner = memecoin.balance_of(OWNER());
        println!("balance meme owner {:?}", balance_meme_launch_owner);

        // memecoin.transfer(launchpad.contract_address, DEFAULT_INITIAL_SUPPLY());
        balance_meme_launch = memecoin.balance_of(launchpad.contract_address);
        println!("balance meme {:?}", balance_meme_launch);

        println!("transfer coin threshold unrug lp with launch liq");

        let erc20 = IERC20Dispatcher { contract_address: quote_token.contract_address };

        //

        erc20.transfer(launchpad.contract_address, quote_to_deposit);

        // memecoin.approve(launchpad.contract_address, total_supply);
        // memecoin.transfer(launchpad.contract_address, total_supply);

        // stop_cheat_caller_address(token_address);
        // let launch = launchpad.get_coin_launch(token_address);
        // let lp_meme_supply = launch.initial_available_supply - launch.available_supply;

        // let total_token_holded: u256 = 1_000 * pow_256(10, 18);
        // let total_token_holded: u256 = launch.total_supply - launch.total_token_holded;
        // let total_token_holded: u256 = 1_000;

        let launch_params = LaunchParameters {
            memecoin_address: token_address,
            transfer_restriction_delay: 100,
            max_percentage_buy_launch: 200, // 2%
            quote_address: quote_token.contract_address,
            initial_holders: array![].span(),
            initial_holders_amounts: array![].span(),
            // initial_holders: array![launchpad.contract_address].span(),
        // initial_holders_amounts: array![total_token_holded].span(),
        };

        let ekubo_pool_params = EkuboPoolParameters {
            fee: 0xc49ba5e353f7d00000000000000000,
            tick_spacing: 5000,
            starting_price,
            bound: 88719042
        };
        start_cheat_caller_address(launchpad.contract_address, OWNER());

        // run_buy_by_amount(
        //     launchpad, quote_token, memecoin, THRESHOLD_LIQUIDITY(), token_address, OWNER(),
        // );
        // let balance_quote_launch = quote_token.balance_of(launchpad.contract_address);
        // println!("balance balance_quote_launch {:?}", balance_quote_launch);
        println!("add liquidity unrug lp with launch threshold");
        let (id, position) = launchpad
            .add_liquidity_unrug_lp(
                token_address,
                quote_token.contract_address,
                lp_meme_supply,
                launch_params,
                EkuboPoolParameters {
                    fee: 0xc49ba5e353f7d00000000000000000,
                    tick_spacing: 5982,
                    starting_price,
                    bound: 88719042
                }
            );
        // println!("id: {:?}", id);

        // let pool_key = PoolKey {
    //     token0: position.pool_key.token0,
    //     token1: position.pool_key.token1,
    //     fee: position.pool_key.fee.try_into().unwrap(),
    //     tick_spacing: position.pool_key.tick_spacing.try_into().unwrap(),
    //     extension: position.pool_key.extension
    // };

        // let core = ICoreDispatcher { contract_address: EKUBO_CORE() };
    // let liquidity = core.get_pool_liquidity(pool_key);
    // let price = core.get_pool_price(pool_key);
    // let reserve_memecoin = IERC20Dispatcher { contract_address: token_address }
    //     .balance_of(core.contract_address);
    // let reserve_quote = IERC20Dispatcher { contract_address: quote_token.contract_address }
    //     .balance_of(core.contract_address);
    // println!("Liquidity: {}", liquidity);

    }


    #[test]
    #[fork("Mainnet")]
    fn test_create_and_add_liquidity_unrug() {
        let (b, quote_token, launchpad) = request_fixture();
        let starting_price = i129 { sign: true, mag: 4600158 }; // 0.01ETH/MEME
        let quote_to_deposit = 215_000;
        let factory = IFactoryDispatcher { contract_address: FACTORY_ADDRESS() };

        let total_supply = DEFAULT_INITIAL_SUPPLY();
        // start_cheat_caller_address(launchpad.contract_address, OWNER());
        let token_address = launchpad
            .create_token(
                symbol: SYMBOL(),
                name: NAME(),
                initial_supply: DEFAULT_INITIAL_SUPPLY(),
                contract_address_salt: SALT() + 1
            );
        println!("token_address unrug: {:?}", token_address);

        start_cheat_caller_address(token_address, launchpad.contract_address);

        let memecoin = IERC20Dispatcher { contract_address: token_address };
        let mut balance_meme_launch = memecoin.balance_of(launchpad.contract_address);
        println!("balance meme {:?}", balance_meme_launch);

        let mut balance_meme_launch_owner = memecoin.balance_of(OWNER());
        println!("balance meme owner {:?}", balance_meme_launch_owner);

        let mut balance_meme_launch_factory = memecoin.balance_of(FACTORY_ADDRESS());
        println!("balance factory {:?}", balance_meme_launch_factory);

        // memecoin.transfer(launchpad.contract_address, DEFAULT_INITIAL_SUPPLY());
        balance_meme_launch = memecoin.balance_of(launchpad.contract_address);

        let total_supply: u256 = memecoin.total_supply();
        let total_token_holded: u256 = total_supply / LIQUIDITY_RATIO;
        // let total_token_holded: u256 = 1_000;
        let lp_meme_supply = total_supply - total_token_holded;
        println!("balance meme {:?}", balance_meme_launch);
        start_cheat_caller_address(memecoin.contract_address, OWNER());
        memecoin.approve(launchpad.contract_address, lp_meme_supply);
        // memecoin.transfer(launchpad.contract_address, lp_meme_supply);
        let launch_params = LaunchParameters {
            memecoin_address: token_address,
            transfer_restriction_delay: 100,
            max_percentage_buy_launch: 200, // 2%
            quote_address: quote_token.contract_address,
            initial_holders: array![].span(),
            initial_holders_amounts: array![].span(),
            // initial_holders: array![launchpad.contract_address].span(),
        // initial_holders_amounts: array![total_token_holded].span(),
        };

        let ekubo_pool_params = EkuboPoolParameters {
            fee: 0xc49ba5e353f7d00000000000000000,
            tick_spacing: 5000,
            starting_price,
            bound: 88719042
        };
        let quote_address = quote_token.contract_address;
        let quote_deposit = 100_u256;
        start_cheat_caller_address(launchpad.contract_address, OWNER());
        let balance_quote_launch = quote_token.balance_of(launchpad.contract_address);
        println!("balance balance_quote_launch {:?}", balance_quote_launch);
        println!("add liquidity unrug");
        let (id, position) = launchpad
            .add_liquidity_unrug(
                token_address,
                quote_address,
                lp_meme_supply,
                quote_deposit,
                launch_params,
                EkuboPoolParameters {
                    fee: 0xc49ba5e353f7d00000000000000000,
                    tick_spacing: 5982,
                    starting_price,
                    bound: 88719042
                }
            );
        println!("id: {:?}", id);
        // let pool_key = PoolKey {
    //     token0: position.pool_key.token0,
    //     token1: position.pool_key.token1,
    //     fee: position.pool_key.fee.try_into().unwrap(),
    //     tick_spacing: position.pool_key.tick_spacing.try_into().unwrap(),
    //     extension: position.pool_key.extension
    // };

        // let core = ICoreDispatcher { contract_address: EKUBO_CORE() };
    // let liquidity = core.get_pool_liquidity(pool_key);
    // let price = core.get_pool_price(pool_key);
    // let reserve_memecoin = IERC20Dispatcher { contract_address: token_address }
    //     .balance_of(core.contract_address);
    // let reserve_quote = IERC20Dispatcher { contract_address: quote_token.contract_address }
    //     .balance_of(core.contract_address);
    // println!("Liquidity: {}", liquidity);

    }
}