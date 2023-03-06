module character_cards::character_cards {
    use std::signer;
    use std::error;
    use std::string::{Self, String, utf8};
    use std::option::{Self, Option};
    use aptos_framework::object::{Self, Object, TransferRef};
    use token_objects::token::{Self, MutabilityConfig};
    use token_objects::collection::{Self, Collection};
    use token_objects_holder::token_objects_holder::{Self, TokenObjectsHolder};

    const E_ADMIN_ONLY: u64 = 1;
    const E_TOO_LONG_INPUT: u64 = 2;
    const E_INVALID_STATUS_RANGE: u64 = 3; 

    const MAX_NAME: u64 = 64;
    const MAX_DESC: u64 = 128;
    const MAX_URI: u64 = 128;
    const MAX_STATUS_VALUE: u64 = 9999;

    #[resource_group(scope = address)]
    struct ConfigGroup{}

    #[resource_group_member(group = ConfigGroup)]
    struct CardConfig has key {
        collection_name: String,
        mutability_config: MutabilityConfig,
        collection_address: address
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct CharacterCard has key {
        character: Option<Object<Character>>,
        attack: Option<Object<Attack>>,
        defense: Option<Object<Defense>>,
        cost: Option<Object<Cost>>,
        attribute: Option<Object<Attribute>>,
        special_ability: Option<Object<SpecialAbility>>,

        transfer_config: TransferRef
    }

    #[resource_group_member(group = ConfigGroup)]
    struct CharacterConfig has key {
        collection_name: String,
        mutability_config: MutabilityConfig,
        collection_address: address
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct Character has key {
        name: String
    }

    #[resource_group_member(group = ConfigGroup)]
    struct AttackConfig has key {
        collection_name: String,
        mutability_config: MutabilityConfig,
        collection_address: address
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct Attack has key {
        value: u64
    }

    #[resource_group_member(group = ConfigGroup)]
    struct DefenseConfig has key {
        collection_name: String,
        mutability_config: MutabilityConfig,
        collection_address: address
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct Defense has key {
        value: u64
    }

    #[resource_group_member(group = ConfigGroup)]
    struct CostConfig has key {
        collection_name: String,
        mutability_config: MutabilityConfig,
        collection_address: address
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct Cost has key {
        value: u64
    }

    #[resource_group_member(group = ConfigGroup)]
    struct AttributeConfig has key {
        collection_name: String,
        mutability_config: MutabilityConfig,
        collection_address: address
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct Attribute has key {
        name: String
    }

    #[resource_group_member(group = ConfigGroup)]
    struct SpecialAbilityConfig has key {
        collection_name: String,
        mutability_config: MutabilityConfig,
        collection_address: address
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct SpecialAbility has key {
        name: String
    }

    struct CardHolder has key {
        card_holder: TokenObjectsHolder<CharacterCard>,
        character_holder: TokenObjectsHolder<Character>,
        attack_holder: TokenObjectsHolder<Attack>,
        defense_holder: TokenObjectsHolder<Defense>,
        cost_holder: TokenObjectsHolder<Cost>,
        attribute_holder: TokenObjectsHolder<Attribute>,
        special_ability_holder: TokenObjectsHolder<SpecialAbility>
    }

    inline fun assert_admin(caller: &signer) {
        assert!(
            signer::address_of(caller) == @character_cards,
            error::permission_denied(E_ADMIN_ONLY)
        );
    }

    inline fun assert_minting_strings(
        description: &String,
        name: &String,
        uri: &String
    ) {
        assert!(
            string::length(description) <= MAX_DESC &&
            string::length(name) <= MAX_NAME &&
            string::length(uri) <= MAX_URI,
            error::invalid_argument(E_TOO_LONG_INPUT)
        );
    }

    inline fun assert_name(name: &String) {
        assert!(
            string::length(name) <= MAX_NAME, 
            error::invalid_argument(E_TOO_LONG_INPUT)
        );
    }

    inline fun assert_status_value(value: u64) {
        assert!(
            value >= 0 && value <= MAX_STATUS_VALUE,
            error::invalid_argument(E_INVALID_STATUS_RANGE)
        );
    }

    fun init_module(caller: &signer) {
        init_card(caller);
        init_character(caller);
        init_attack(caller);
        init_defense(caller);
        init_cost(caller);
        init_attribute(caller);
        init_special_ability(caller);
    }

    fun init_card(caller: &signer) {
        let name = utf8(b"character-card-card-collection");
        let constructor = collection::create_fixed_collection(
            caller,
            utf8(b"base-card-collection-for-character-card"),
            1_000_000,
            collection::create_mutability_config(false, false),
            name,
            option::none(),
            utf8(b"----://character-card/base-card-collection"),
        );
        let obj = object::object_from_constructor_ref<Collection>(&constructor);
        move_to(
            caller,
            CardConfig{
                collection_name: name,
                mutability_config: token::create_mutability_config(false, false, false),
                collection_address: object::object_address(&obj)
            }    
        );
    }

    fun init_character(caller: &signer) {
        let name = utf8(b"character-card-character-collection");
        let constructor = collection::create_fixed_collection(
            caller,
            utf8(b"character-collection-for-character-card"),
            1_000_000,
            collection::create_mutability_config(false, false),
            name,
            option::none(),
            utf8(b"----://character-card/character-collection"),
        );
        let obj = object::object_from_constructor_ref<Collection>(&constructor);
        move_to(
            caller,
            CharacterConfig{
                collection_name: name,
                mutability_config: token::create_mutability_config(false, false, false),
                collection_address: object::object_address(&obj)
            }
        )
    }

    fun init_attack(caller: &signer) {
        let name = utf8(b"character-card-attack-collection");
        let constructor = collection::create_fixed_collection(
            caller,
            utf8(b"attack-collection-for-character-card"),
            1_000_000,
            collection::create_mutability_config(false, false),
            name,
            option::none(),
            utf8(b"----://character-card/attack-collection"),
        );
        let obj = object::object_from_constructor_ref<Collection>(&constructor);
        move_to(
            caller,
            AttackConfig{
                collection_name: name,
                mutability_config: token::create_mutability_config(false, false, false),
                collection_address: object::object_address(&obj)
            }
        )
    }

    fun init_defense(caller: &signer) {
        let name = utf8(b"character-card-defense-collection");
        let constructor = collection::create_fixed_collection(
            caller,
            utf8(b"defense-collection-for-character-card"),
            1_000_000,
            collection::create_mutability_config(false, false),
            name,
            option::none(),
            utf8(b"----://character-card/defense-collection"),
        );
        let obj = object::object_from_constructor_ref<Collection>(&constructor);
        move_to(
            caller,
            DefenseConfig{
                collection_name: name,
                mutability_config: token::create_mutability_config(false, false, false),
                collection_address: object::object_address(&obj)
            }
        )
    }

    fun init_cost(caller: &signer) {
        let name = utf8(b"character-card-cost-collection");
        let constructor = collection::create_fixed_collection(
            caller,
            utf8(b"cost-collection-for-character-card"),
            1_000_000,
            collection::create_mutability_config(false, false),
            name,
            option::none(),
            utf8(b"----://character-card/cost-collection"),
        );
        let obj = object::object_from_constructor_ref<Collection>(&constructor);
        move_to(
            caller,
            CostConfig{
                collection_name: name,
                mutability_config: token::create_mutability_config(false, false, false),
                collection_address: object::object_address(&obj)
            }
        )
    }

    fun init_attribute(caller: &signer) {
        let name = utf8(b"character-card-Attribute-collection");
        let constructor = collection::create_fixed_collection(
            caller,
            utf8(b"attribute-collection-for-character-card"),
            1_000_000,
            collection::create_mutability_config(false, false),
            name,
            option::none(),
            utf8(b"----://character-card/attribute-collection"),
        );
        let obj = object::object_from_constructor_ref<Collection>(&constructor);
        move_to(
            caller,
            AttributeConfig{
                collection_name: name,
                mutability_config: token::create_mutability_config(false, false, false),
                collection_address: object::object_address(&obj)
            }
        )
    }

    fun init_special_ability(caller: &signer) {
        let name = utf8(b"character-card-special-ability-collection");
        let constructor = collection::create_fixed_collection(
            caller,
            utf8(b"special-ability-collection-for-character-card"),
            1_000_000,
            collection::create_mutability_config(false, false),
            name,
            option::none(),
            utf8(b"----://character-card/special-ability-collection"),
        );
        let obj = object::object_from_constructor_ref<Collection>(&constructor);
        move_to(
            caller,
            SpecialAbilityConfig{
                collection_name: name,
                mutability_config: token::create_mutability_config(false, false, false),
                collection_address: object::object_address(&obj)
            }
        )
    }

    fun register(caller: &signer) {
        if (!exists<CardHolder>(signer::address_of(caller))) {
            move_to(
                caller,
                CardHolder{
                    card_holder: token_objects_holder::new(),
                    character_holder: token_objects_holder::new(),
                    attack_holder: token_objects_holder::new(),
                    defense_holder: token_objects_holder::new(),
                    cost_holder: token_objects_holder::new(),
                    attribute_holder: token_objects_holder::new(),
                    special_ability_holder: token_objects_holder::new()
                }
            )
        }
    }

    fun create_card(
        caller: &signer,
        description: &String,
        name: &String,
        uri: &String
    ): Object<CharacterCard>
    acquires CardConfig, CardHolder {
        assert_admin(caller);
        assert_minting_strings(description, name, uri);
        let config = borrow_global<CardConfig>(@character_cards);
        let constructor = token::create_token(
            caller,
            config.collection_name,
            *description,
            config.mutability_config,
            *name,
            option::none(),
            *uri
        );
        let obj_signer = object::generate_signer(&constructor);
        let transfer_config = object::generate_transfer_ref(&constructor);
        object::disable_ungated_transfer(&transfer_config);
        move_to(
            &obj_signer,
            CharacterCard{
                character: option::none(),
                attack: option::none(),
                defense: option::none(),
                cost: option::none(),
                attribute: option::none(),
                special_ability: option::none(),
                transfer_config
            }
        );
        register(caller);
        let obj = object::address_to_object(signer::address_of(&obj_signer));
        let holder = borrow_global_mut<CardHolder>(signer::address_of(caller));
        token_objects_holder::add_to_holder(&mut holder.card_holder, obj);
        obj
    }

    fun create_character(
        caller: &signer,
        character_name: &String,
        description: &String,
        token_name: &String,
        uri: &String
    ): Object<Character>
    acquires CharacterConfig, CardHolder {
        assert_admin(caller);
        assert_minting_strings(description, token_name, uri);
        assert_name(character_name);
        let config = borrow_global<CharacterConfig>(@character_cards);
        let constructor = token::create_token(
            caller,
            config.collection_name,
            *description,
            config.mutability_config,
            *token_name,
            option::none(),
            *uri
        );
        let obj_signer = object::generate_signer(&constructor);
        let transfer_config = object::generate_transfer_ref(&constructor);
        object::disable_ungated_transfer(&transfer_config);
        move_to(
            &obj_signer,
            Character{
                name: *character_name
            }
        );
        register(caller);
        let obj = object::address_to_object(signer::address_of(&obj_signer));
        let holder = borrow_global_mut<CardHolder>(signer::address_of(caller));
        token_objects_holder::add_to_holder(&mut holder.character_holder, obj);
        obj
    }

    fun create_attack(
        caller: &signer,
        status_value: u64,
        description: &String,
        name: &String,
        uri: &String
    ): Object<Attack>
    acquires AttackConfig, CardHolder {
        assert_admin(caller);
        assert_minting_strings(description, name, uri);
        assert_status_value(status_value);
        let config = borrow_global<AttackConfig>(@character_cards);
        let constructor = token::create_token(
            caller,
            config.collection_name,
            *description,
            config.mutability_config,
            *name,
            option::none(),
            *uri
        );
        let obj_signer = object::generate_signer(&constructor);
        let transfer_config = object::generate_transfer_ref(&constructor);
        object::disable_ungated_transfer(&transfer_config);
        move_to(
            &obj_signer,
            Attack{
                value: status_value
            }
        );
        register(caller);
        let obj = object::address_to_object(signer::address_of(&obj_signer));
        let holder = borrow_global_mut<CardHolder>(signer::address_of(caller));
        token_objects_holder::add_to_holder(&mut holder.attack_holder, obj);
        obj
    }

    fun create_defense(
        caller: &signer,
        status_value: u64,
        description: &String,
        name: &String,
        uri: &String
    ): Object<Defense>
    acquires DefenseConfig, CardHolder {
        assert_admin(caller);
        assert_minting_strings(description, name, uri);
        assert_status_value(status_value);
        let config = borrow_global<DefenseConfig>(@character_cards);
        let constructor = token::create_token(
            caller,
            config.collection_name,
            *description,
            config.mutability_config,
            *name,
            option::none(),
            *uri
        );
        let obj_signer = object::generate_signer(&constructor);
        let transfer_config = object::generate_transfer_ref(&constructor);
        object::disable_ungated_transfer(&transfer_config);
        move_to(
            &obj_signer,
            Defense{
                value: status_value
            }
        );
        register(caller);
        let obj = object::address_to_object(signer::address_of(&obj_signer));
        let holder = borrow_global_mut<CardHolder>(signer::address_of(caller));
        token_objects_holder::add_to_holder(&mut holder.defense_holder, obj);
        obj
    }

    fun create_cost(
        caller: &signer,
        status_value: u64,
        description: &String,
        name: &String,
        uri: &String
    ): Object<Cost>
    acquires CostConfig, CardHolder {
        assert_admin(caller);
        assert_minting_strings(description, name, uri);
        assert_status_value(status_value);
        let config = borrow_global<CostConfig>(@character_cards);
        let constructor = token::create_token(
            caller,
            config.collection_name,
            *description,
            config.mutability_config,
            *name,
            option::none(),
            *uri
        );
        let obj_signer = object::generate_signer(&constructor);
        let transfer_config = object::generate_transfer_ref(&constructor);
        object::disable_ungated_transfer(&transfer_config);
        move_to(
            &obj_signer,
            Cost{
                value: status_value
            }
        );
        register(caller);
        let obj = object::address_to_object(signer::address_of(&obj_signer));
        let holder = borrow_global_mut<CardHolder>(signer::address_of(caller));
        token_objects_holder::add_to_holder(&mut holder.cost_holder, obj);
        obj
    }

    fun create_attribute(
        caller: &signer,
        attribute_name: &String,
        description: &String,
        token_name: &String,
        uri: &String
    ): Object<Attribute>
    acquires AttributeConfig, CardHolder {
        assert_admin(caller);
        assert_minting_strings(description, token_name, uri);
        assert_name(attribute_name);
        let config = borrow_global<AttributeConfig>(@character_cards);
        let constructor = token::create_token(
            caller,
            config.collection_name,
            *description,
            config.mutability_config,
            *token_name,
            option::none(),
            *uri
        );
        let obj_signer = object::generate_signer(&constructor);
        let transfer_config = object::generate_transfer_ref(&constructor);
        object::disable_ungated_transfer(&transfer_config);
        move_to(
            &obj_signer,
            Attribute{
                name: *attribute_name
            }
        );
        register(caller);
        let obj = object::address_to_object(signer::address_of(&obj_signer));
        let holder = borrow_global_mut<CardHolder>(signer::address_of(caller));
        token_objects_holder::add_to_holder(&mut holder.attribute_holder, obj);
        obj
    }

    fun create_special_ability(
        caller: &signer,
        special_ability_name: &String,
        description: &String,
        token_name: &String,
        uri: &String
    ): Object<SpecialAbility>
    acquires SpecialAbilityConfig, CardHolder {
        assert_admin(caller);
        assert_minting_strings(description, token_name, uri);
        assert_name(special_ability_name);
        let config = borrow_global<SpecialAbilityConfig>(@character_cards);
        let constructor = token::create_token(
            caller,
            config.collection_name,
            *description,
            config.mutability_config,
            *token_name,
            option::none(),
            *uri
        );
        let obj_signer = object::generate_signer(&constructor);
        let transfer_config = object::generate_transfer_ref(&constructor);
        object::disable_ungated_transfer(&transfer_config);
        move_to(
            &obj_signer,
            SpecialAbility{
                name: *special_ability_name
            }
        );
        register(caller);
        let obj = object::address_to_object(signer::address_of(&obj_signer));
        let holder = borrow_global_mut<CardHolder>(signer::address_of(caller));
        token_objects_holder::add_to_holder(&mut holder.special_ability_holder, obj);
        obj
    }

    #[test(admin = @0xcafe)]
    fun test_happy_path(admin: &signer)
    acquires CardConfig, CharacterConfig, 
    AttackConfig, DefenseConfig, CostConfig,
    AttributeConfig, SpecialAbilityConfig, CardHolder {
        init_module(admin);
        create_card(admin, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        create_character(admin, &utf8(b"character"), &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        create_attack(admin, 100, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        create_defense(admin, 100, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        create_cost(admin, 100, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        create_attribute(admin, &utf8(b"attribute"), &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        create_special_ability(admin, &utf8(b"skill"), &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
    }    
}