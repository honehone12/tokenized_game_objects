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
    const E_NO_SUCH_OBJECT: u64 = 4;
    const E_OWNER_ONLY: u64 = 5;
    const E_ALREADY_OWNER :u64 = 6;
    const E_ALREADY_FILLED: u64 = 7;
    const E_EMPTY: u64 = 8;

    const MAX_NAME: u64 = 64;
    const MAX_DESC: u64 = 128;
    const MAX_URI: u64 = 128;
    const MAX_STATUS_VALUE: u64 = 9999;

    #[resource_group(scope = address)]
    struct ConfigGroup{}

    #[resource_group_member(group = ConfigGroup)]
    struct CardConfig has key {
        mutability_config: MutabilityConfig,
        collection_address: address
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct CharacterCard has key {
        character: Option<Object<Parts<Character>>>,
        attack: Option<Object<Parts<Attack>>>,
        defense: Option<Object<Parts<Defense>>>,
        cost: Option<Object<Parts<Cost>>>,
        attribute: Option<Object<Parts<Attribute>>>,
        special_ability: Option<Object<Parts<SpecialAbility>>>,

        transfer_config: TransferRef
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct Parts<P: store> has key {
        parts: P,

        transfer_config: TransferRef
    }

    #[resource_group_member(group = ConfigGroup)]
    struct Config<phantom P: store> has key {
        mutability_config: MutabilityConfig,
        collection_address: address
    }

    struct Character has store {
        name: String,    
    }

    struct Attack has store {
        value: u64,
    }

    struct Defense has store {
        value: u64,
    }

    struct Cost has store {
        value: u64,
    }

    struct Attribute has store {
        name: String,
    }

    struct SpecialAbility has store {
        name: String,
    }

    struct CardHolder has key {
        card_holder: TokenObjectsHolder<CharacterCard>,
        character_holder: TokenObjectsHolder<Parts<Character>>,
        attack_holder: TokenObjectsHolder<Parts<Attack>>,
        defense_holder: TokenObjectsHolder<Parts<Defense>>,
        cost_holder: TokenObjectsHolder<Parts<Cost>>,
        attribute_holder: TokenObjectsHolder<Parts<Attribute>>,
        special_ability_holder: TokenObjectsHolder<Parts<SpecialAbility>>
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

    inline fun assert_object_exists<T: key>(obj: &Object<T>) {
        assert!(
            exists<T>(object::object_address(obj)),
            error::not_found(E_NO_SUCH_OBJECT)
        );
    }

    inline fun assert_object_owner<T: key>(obj: &Object<T>, addr: address) {
        assert!(
            object::is_owner(*obj, addr), 
            error::permission_denied(E_OWNER_ONLY)
        );
    }

    inline fun assert_slot_is_empty<T: key>(slot: &Option<Object<T>>) {
        assert!(
            option::is_none(slot),
            error::already_exists(E_ALREADY_FILLED)
        );
    }

    inline fun assert_slot_is_filled<T: key>(slot: &Option<Object<T>>) {
        assert!(
            option::is_some(slot),
            error::invalid_argument(E_EMPTY)
        );
    }

    inline fun add_card_to_holder(new_owner: address, card: &Object<CharacterCard>)
    acquires CardHolder {
        let holder = borrow_global_mut<CardHolder>(new_owner);
        assert!(
            !token_objects_holder::holds(&holder.card_holder, card),
            error::permission_denied(E_ALREADY_OWNER)
        );
        token_objects_holder::add_to_holder(&mut holder.card_holder, card);
    }

    inline fun remove_card_from_holder(previous_owner: address, card: &Object<CharacterCard>)
    acquires CardHolder {
        let holder = borrow_global_mut<CardHolder>(previous_owner);
        assert!(
            token_objects_holder::holds(&holder.card_holder, card),
            error::permission_denied(E_OWNER_ONLY)
        );
        token_objects_holder::remove_from_holder(&mut holder.card_holder, card);
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
        let constructor = collection::create_fixed_collection(
            caller,
            utf8(b"base-card-collection-for-character-card"),
            1_000_000,
            collection::create_mutability_config(false, false),
            utf8(b"character-card-card-collection"),
            option::none(),
            utf8(b"----://character-card/base-card-collection"),
        );
        let obj = object::object_from_constructor_ref<Collection>(&constructor);
        move_to(
            caller,
            CardConfig{
                mutability_config: token::create_mutability_config(false, false, false),
                collection_address: object::object_address(&obj)
            }    
        );
    }

    fun init_character(caller: &signer) {
        let constructor = collection::create_fixed_collection(
            caller,
            utf8(b"character-collection-for-character-card"),
            1_000_000,
            collection::create_mutability_config(false, false),
            utf8(b"character-card-character-collection"),
            option::none(),
            utf8(b"----://character-card/character-collection"),
        );
        let obj = object::object_from_constructor_ref<Collection>(&constructor);
        move_to(
            caller,
            Config<Character>{
                mutability_config: token::create_mutability_config(false, false, false),
                collection_address: object::object_address(&obj)
            }
        )
    }

    fun init_attack(caller: &signer) {
        let constructor = collection::create_fixed_collection(
            caller,
            utf8(b"attack-collection-for-character-card"),
            1_000_000,
            collection::create_mutability_config(false, false),
            utf8(b"character-card-attack-collection"),
            option::none(),
            utf8(b"----://character-card/attack-collection"),
        );
        let obj = object::object_from_constructor_ref<Collection>(&constructor);
        move_to(
            caller,
            Config<Attack>{
                mutability_config: token::create_mutability_config(false, false, false),
                collection_address: object::object_address(&obj)
            }
        )
    }

    fun init_defense(caller: &signer) {
        let constructor = collection::create_fixed_collection(
            caller,
            utf8(b"defense-collection-for-character-card"),
            1_000_000,
            collection::create_mutability_config(false, false),
            utf8(b"character-card-defense-collection"),
            option::none(),
            utf8(b"----://character-card/defense-collection"),
        );
        let obj = object::object_from_constructor_ref<Collection>(&constructor);
        move_to(
            caller,
            Config<Defense>{
                mutability_config: token::create_mutability_config(false, false, false),
                collection_address: object::object_address(&obj)
            }
        )
    }

    fun init_cost(caller: &signer) {
        let constructor = collection::create_fixed_collection(
            caller,
            utf8(b"cost-collection-for-character-card"),
            1_000_000,
            collection::create_mutability_config(false, false),
            utf8(b"character-card-cost-collection"),
            option::none(),
            utf8(b"----://character-card/cost-collection"),
        );
        let obj = object::object_from_constructor_ref<Collection>(&constructor);
        move_to(
            caller,
            Config<Cost>{
                mutability_config: token::create_mutability_config(false, false, false),
                collection_address: object::object_address(&obj)
            }
        )
    }

    fun init_attribute(caller: &signer) {
        let constructor = collection::create_fixed_collection(
            caller,
            utf8(b"attribute-collection-for-character-card"),
            1_000_000,
            collection::create_mutability_config(false, false),
            utf8(b"character-card-Attribute-collection"),
            option::none(),
            utf8(b"----://character-card/attribute-collection"),
        );
        let obj = object::object_from_constructor_ref<Collection>(&constructor);
        move_to(
            caller,
            Config<Attribute>{
                mutability_config: token::create_mutability_config(false, false, false),
                collection_address: object::object_address(&obj)
            }
        )
    }

    fun init_special_ability(caller: &signer) {
        let constructor = collection::create_fixed_collection(
            caller,
            utf8(b"special-ability-collection-for-character-card"),
            1_000_000,
            collection::create_mutability_config(false, false),
            utf8(b"character-card-special-ability-collection"),
            option::none(),
            utf8(b"----://character-card/special-ability-collection"),
        );
        let obj = object::object_from_constructor_ref<Collection>(&constructor);
        move_to(
            caller,
            Config<SpecialAbility>{
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
            collection::name(object::address_to_object<Collection>(config.collection_address)),
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
        token_objects_holder::add_to_holder(&mut holder.card_holder, &obj);
        obj
    }

    fun create_parts<P: store>(
        caller: &signer,
        name: &String,
        description: &String,
        uri: &String,
        parts: P
    ): Object<Parts<P>>
    acquires Config {
        assert_admin(caller);
        assert_minting_strings(description, name, uri);
        let config = borrow_global<Config<P>>(@character_cards);
        let constructor = token::create_token(
            caller,
            collection::name(object::address_to_object<Collection>(config.collection_address)),
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
            Parts<P>{
                parts,
                transfer_config
            }
        );
        object::address_to_object(signer::address_of(&obj_signer))
    }

    fun create_character(
        caller: &signer,
        character_name: &String,
        description: &String,
        token_name: &String,
        uri: &String
    ): Object<Parts<Character>>
    acquires Config, CardHolder {
        assert_name(character_name);
        let obj = create_parts(
            caller,
            token_name,
            description,
            uri,
            Character{
                name: *character_name
            }
        );
        register(caller);
        let holder = borrow_global_mut<CardHolder>(signer::address_of(caller));
        token_objects_holder::add_to_holder(&mut holder.character_holder, &obj);
        obj
    }

    fun create_attack(
        caller: &signer,
        status_value: u64,
        description: &String,
        name: &String,
        uri: &String
    ): Object<Parts<Attack>>
    acquires Config, CardHolder {
        assert_status_value(status_value);
        let obj = create_parts(
            caller,
            name,
            description,
            uri,
            Attack{
                value: status_value
            }
        );
        register(caller);
        let holder = borrow_global_mut<CardHolder>(signer::address_of(caller));
        token_objects_holder::add_to_holder(&mut holder.attack_holder, &obj);
        obj
    }

    fun create_defense(
        caller: &signer,
        status_value: u64,
        description: &String,
        name: &String,
        uri: &String
    ): Object<Parts<Defense>>
    acquires Config, CardHolder {
        assert_status_value(status_value);
        let obj = create_parts(
            caller,
            name,
            description,
            uri,
            Defense{
                value: status_value
            }
        );
        register(caller);
        let holder = borrow_global_mut<CardHolder>(signer::address_of(caller));
        token_objects_holder::add_to_holder(&mut holder.defense_holder, &obj);
        obj
    }

    fun create_cost(
        caller: &signer,
        status_value: u64,
        description: &String,
        name: &String,
        uri: &String
    ): Object<Parts<Cost>>
    acquires Config, CardHolder {
        assert_status_value(status_value);
        let obj = create_parts(
            caller,
            name,
            description,
            uri,
            Cost{
                value: status_value
            }
        );
        register(caller);
        let holder = borrow_global_mut<CardHolder>(signer::address_of(caller));
        token_objects_holder::add_to_holder(&mut holder.cost_holder, &obj);
        obj
    }

    fun create_attribute(
        caller: &signer,
        attribute_name: &String,
        description: &String,
        token_name: &String,
        uri: &String
    ): Object<Parts<Attribute>>
    acquires Config, CardHolder {
        assert_name(attribute_name);
        let obj = create_parts(
            caller,
            token_name,
            description,
            uri,
            Attribute{
                name: *attribute_name
            }
        );
        register(caller);
        let holder = borrow_global_mut<CardHolder>(signer::address_of(caller));
        token_objects_holder::add_to_holder(&mut holder.attribute_holder, &obj);
        obj
    }

    fun create_special_ability(
        caller: &signer,
        special_ability_name: &String,
        description: &String,
        token_name: &String,
        uri: &String
    ): Object<Parts<SpecialAbility>>
    acquires Config, CardHolder {
        assert_name(special_ability_name);
        let obj = create_parts(
            caller,
            token_name,
            description,
            uri,
            SpecialAbility{
                name: *special_ability_name
            }
        );
        register(caller);
        let holder = borrow_global_mut<CardHolder>(signer::address_of(caller));
        token_objects_holder::add_to_holder(&mut holder.special_ability_holder, &obj);
        obj
    }

    fun managed_transfer_card(
        caller: &signer, 
        card_obj: Object<CharacterCard>,
        to: address
    )
    acquires CardHolder, CharacterCard {
        let caller_addr = signer::address_of(caller);
        assert_object_exists(&card_obj);
        assert_object_owner(&card_obj, caller_addr);
        let card = borrow_global<CharacterCard>(object::object_address(&card_obj));
        object::enable_ungated_transfer(&card.transfer_config);
        object::transfer(caller, card_obj, to);
        remove_card_from_holder(caller_addr, &card_obj);
        add_card_to_holder(to, &card_obj);
        object::disable_ungated_transfer(&card.transfer_config);
    }

    fun install_character(
        owner: &signer,
        card_obj: &Object<CharacterCard>,
        character_obj: &Object<Parts<Character>>
    )
    acquires CardHolder, CharacterCard, Parts {
        assert_object_exists(card_obj);
        assert_object_exists(character_obj);
        let owner_addr = signer::address_of(owner);
        assert_object_owner(card_obj, owner_addr);
        assert_object_owner(character_obj, owner_addr);
        let card = borrow_global_mut<CharacterCard>(object::object_address(card_obj));
        assert_slot_is_empty(&card.character);
        let chara = borrow_global<Parts<Character>>(object::object_address(character_obj));
        object::enable_ungated_transfer(&chara.transfer_config);
        option::fill(&mut card.character, *character_obj);
        object::transfer_to_object(owner, *character_obj, *card_obj);
        let holder = borrow_global_mut<CardHolder>(owner_addr);
        token_objects_holder::remove_from_holder(&mut holder.character_holder, character_obj);
    }

    fun uninstall_character(
        owner: &signer,
        card_obj: &Object<CharacterCard>
    )
    acquires CardHolder, CharacterCard, Parts {
        assert_object_exists(card_obj);
        let owner_addr = signer::address_of(owner);
        assert_object_owner(card_obj, owner_addr);
        let card = borrow_global_mut<CharacterCard>(object::object_address(card_obj));
        assert_slot_is_filled(&card.character);
        let stored_chara = option::extract(&mut card.character);
        assert_object_exists(&stored_chara);
        assert_object_owner(&stored_chara, object::object_address(card_obj));
        object::enable_ungated_transfer(&card.transfer_config);
        object::transfer(owner, stored_chara, owner_addr);
        let chara = borrow_global<Parts<Character>>(object::object_address(&stored_chara));
        object::disable_ungated_transfer(&chara.transfer_config);
        object::disable_ungated_transfer(&card.transfer_config);
        let holder = borrow_global_mut<CardHolder>(owner_addr);
        token_objects_holder::add_to_holder(&mut holder.character_holder, &stored_chara);
    }

    fun install_attack(
        owner: &signer,
        card_obj: &Object<CharacterCard>,
        attack_obj: &Object<Parts<Attack>>
    )
    acquires CardHolder, CharacterCard, Parts {
        assert_object_exists(card_obj);
        assert_object_exists(attack_obj);
        let owner_addr = signer::address_of(owner);
        assert_object_owner(card_obj, owner_addr);
        assert_object_owner(attack_obj, owner_addr);
        let card = borrow_global_mut<CharacterCard>(object::object_address(card_obj));
        assert_slot_is_empty(&card.attack);
        let attack = borrow_global<Parts<Attack>>(object::object_address(attack_obj));
        object::enable_ungated_transfer(&attack.transfer_config);
        option::fill(&mut card.attack, *attack_obj);
        object::transfer_to_object(owner, *attack_obj, *card_obj);
        let holder = borrow_global_mut<CardHolder>(owner_addr);
        token_objects_holder::remove_from_holder(&mut holder.attack_holder, attack_obj);
    }

    fun uninstall_attack(
        owner: &signer,
        card_obj: &Object<CharacterCard>
    )
    acquires CardHolder, CharacterCard, Parts {
        assert_object_exists(card_obj);
        let owner_addr = signer::address_of(owner);
        assert_object_owner(card_obj, owner_addr);
        let card = borrow_global_mut<CharacterCard>(object::object_address(card_obj));
        assert_slot_is_filled(&card.attack);
        let stored_attack = option::extract(&mut card.attack);
        assert_object_exists(&stored_attack);
        assert_object_owner(&stored_attack, object::object_address(card_obj));
        object::enable_ungated_transfer(&card.transfer_config);
        object::transfer(owner, stored_attack, owner_addr);
        let attack = borrow_global<Parts<Attack>>(object::object_address(&stored_attack));
        object::disable_ungated_transfer(&attack.transfer_config);
        object::disable_ungated_transfer(&card.transfer_config);
        let holder = borrow_global_mut<CardHolder>(owner_addr);
        token_objects_holder::add_to_holder(&mut holder.attack_holder, &stored_attack);
    }

    fun install_defense(
        owner: &signer,
        card_obj: &Object<CharacterCard>,
        defense_obj: &Object<Parts<Defense>>
    )
    acquires CardHolder, CharacterCard, Parts {
        assert_object_exists(card_obj);
        assert_object_exists(defense_obj);
        let owner_addr = signer::address_of(owner);
        assert_object_owner(card_obj, owner_addr);
        assert_object_owner(defense_obj, owner_addr);
        let card = borrow_global_mut<CharacterCard>(object::object_address(card_obj));
        assert_slot_is_empty(&card.defense);
        let defense = borrow_global<Parts<Defense>>(object::object_address(defense_obj));
        object::enable_ungated_transfer(&defense.transfer_config);
        option::fill(&mut card.defense, *defense_obj);
        object::transfer_to_object(owner, *defense_obj, *card_obj);
        let holder = borrow_global_mut<CardHolder>(owner_addr);
        token_objects_holder::remove_from_holder(&mut holder.defense_holder, defense_obj);
    }

    fun uninstall_defense(
        owner: &signer,
        card_obj: &Object<CharacterCard>
    )
    acquires CardHolder, CharacterCard, Parts {
        assert_object_exists(card_obj);
        let owner_addr = signer::address_of(owner);
        assert_object_owner(card_obj, owner_addr);
        let card = borrow_global_mut<CharacterCard>(object::object_address(card_obj));
        assert_slot_is_filled(&card.defense);
        let stored_defense = option::extract(&mut card.defense);
        assert_object_exists(&stored_defense);
        assert_object_owner(&stored_defense, object::object_address(card_obj));
        object::enable_ungated_transfer(&card.transfer_config);
        object::transfer(owner, stored_defense, owner_addr);
        let defense = borrow_global<Parts<Defense>>(object::object_address(&stored_defense));
        object::disable_ungated_transfer(&defense.transfer_config);
        object::disable_ungated_transfer(&card.transfer_config);
        let holder = borrow_global_mut<CardHolder>(owner_addr);
        token_objects_holder::add_to_holder(&mut holder.defense_holder, &stored_defense);
    }

    fun install_cost(
        owner: &signer,
        card_obj: &Object<CharacterCard>,
        cost_obj: &Object<Parts<Cost>>
    )
    acquires CardHolder, CharacterCard, Parts {
        assert_object_exists(card_obj);
        assert_object_exists(cost_obj);
        let owner_addr = signer::address_of(owner);
        assert_object_owner(card_obj, owner_addr);
        assert_object_owner(cost_obj, owner_addr);
        let card = borrow_global_mut<CharacterCard>(object::object_address(card_obj));
        assert_slot_is_empty(&card.cost);
        let cost = borrow_global<Parts<Cost>>(object::object_address(cost_obj));
        object::enable_ungated_transfer(&cost.transfer_config);
        option::fill(&mut card.cost, *cost_obj);
        object::transfer_to_object(owner, *cost_obj, *card_obj);
        let holder = borrow_global_mut<CardHolder>(owner_addr);
        token_objects_holder::remove_from_holder(&mut holder.cost_holder, cost_obj);
    }

    fun uninstall_cost(
        owner: &signer,
        card_obj: &Object<CharacterCard>
    )
    acquires CardHolder, CharacterCard, Parts {
        assert_object_exists(card_obj);
        let owner_addr = signer::address_of(owner);
        assert_object_owner(card_obj, owner_addr);
        let card = borrow_global_mut<CharacterCard>(object::object_address(card_obj));
        assert_slot_is_filled(&card.cost);
        let stored_cost = option::extract(&mut card.cost);
        assert_object_exists(&stored_cost);
        assert_object_owner(&stored_cost, object::object_address(card_obj));
        object::enable_ungated_transfer(&card.transfer_config);
        object::transfer(owner, stored_cost, owner_addr);
        let cost = borrow_global<Parts<Cost>>(object::object_address(&stored_cost));
        object::disable_ungated_transfer(&cost.transfer_config);
        object::disable_ungated_transfer(&card.transfer_config);
        let holder = borrow_global_mut<CardHolder>(owner_addr);
        token_objects_holder::add_to_holder(&mut holder.cost_holder, &stored_cost);
    }

    fun install_attribute(
        owner: &signer,
        card_obj: &Object<CharacterCard>,
        attribute_obj: &Object<Parts<Attribute>>
    )
    acquires CardHolder, CharacterCard, Parts {
        assert_object_exists(card_obj);
        assert_object_exists(attribute_obj);
        let owner_addr = signer::address_of(owner);
        assert_object_owner(card_obj, owner_addr);
        assert_object_owner(attribute_obj, owner_addr);
        let card = borrow_global_mut<CharacterCard>(object::object_address(card_obj));
        assert_slot_is_empty(&card.attribute);
        let attribute = borrow_global<Parts<Attribute>>(object::object_address(attribute_obj));
        object::enable_ungated_transfer(&attribute.transfer_config);
        option::fill(&mut card.attribute, *attribute_obj);
        object::transfer_to_object(owner, *attribute_obj, *card_obj);
        let holder = borrow_global_mut<CardHolder>(owner_addr);
        token_objects_holder::remove_from_holder(&mut holder.attribute_holder, attribute_obj);
    }

    fun uninstall_attribute(
        owner: &signer,
        card_obj: &Object<CharacterCard>
    )
    acquires CardHolder, CharacterCard, Parts {
        assert_object_exists(card_obj);
        let owner_addr = signer::address_of(owner);
        assert_object_owner(card_obj, owner_addr);
        let card = borrow_global_mut<CharacterCard>(object::object_address(card_obj));
        assert_slot_is_filled(&card.attribute);
        let stored_attribute = option::extract(&mut card.attribute);
        assert_object_exists(&stored_attribute);
        assert_object_owner(&stored_attribute, object::object_address(card_obj));
        object::enable_ungated_transfer(&card.transfer_config);
        object::transfer(owner, stored_attribute, owner_addr);
        let attribute = borrow_global<Parts<Attribute>>(object::object_address(&stored_attribute));
        object::disable_ungated_transfer(&attribute.transfer_config);
        object::disable_ungated_transfer(&card.transfer_config);
        let holder = borrow_global_mut<CardHolder>(owner_addr);
        token_objects_holder::add_to_holder(&mut holder.attribute_holder, &stored_attribute);
    }

    fun install_special_ability(
        owner: &signer,
        card_obj: &Object<CharacterCard>,
        ability_obj: &Object<Parts<SpecialAbility>>
    )
    acquires CardHolder, CharacterCard, Parts {
        assert_object_exists(card_obj);
        assert_object_exists(ability_obj);
        let owner_addr = signer::address_of(owner);
        assert_object_owner(card_obj, owner_addr);
        assert_object_owner(ability_obj, owner_addr);
        let card = borrow_global_mut<CharacterCard>(object::object_address(card_obj));
        assert_slot_is_empty(&card.special_ability);
        let ability = borrow_global<Parts<SpecialAbility>>(object::object_address(ability_obj));
        object::enable_ungated_transfer(&ability.transfer_config);
        option::fill(&mut card.special_ability, *ability_obj);
        object::transfer_to_object(owner, *ability_obj, *card_obj);
        let holder = borrow_global_mut<CardHolder>(owner_addr);
        token_objects_holder::remove_from_holder(&mut holder.special_ability_holder, ability_obj);
    }

    fun uninstall_special_ability(
        owner: &signer,
        card_obj: &Object<CharacterCard>
    )
    acquires CardHolder, CharacterCard, Parts {
        assert_object_exists(card_obj);
        let owner_addr = signer::address_of(owner);
        assert_object_owner(card_obj, owner_addr);
        let card = borrow_global_mut<CharacterCard>(object::object_address(card_obj));
        assert_slot_is_filled(&card.special_ability);
        let stored_ability = option::extract(&mut card.special_ability);
        assert_object_exists(&stored_ability);
        assert_object_owner(&stored_ability, object::object_address(card_obj));
        object::enable_ungated_transfer(&card.transfer_config);
        object::transfer(owner, stored_ability, owner_addr);
        let ability = borrow_global<Parts<SpecialAbility>>(object::object_address(&stored_ability));
        object::disable_ungated_transfer(&ability.transfer_config);
        object::disable_ungated_transfer(&card.transfer_config);
        let holder = borrow_global_mut<CardHolder>(owner_addr);
        token_objects_holder::add_to_holder(&mut holder.special_ability_holder, &stored_ability);
    } 

    #[test(admin = @0xcafe, other = @0xbeef)]
    fun test_happy_path(admin: &signer, other: &signer)
    acquires CardConfig, Config, CardHolder, CharacterCard, Parts {
        init_module(admin);
        let ca = create_card(admin, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        assert!(exists<CardHolder>(@0xcafe), 0);
        assert!(object::is_owner(ca, @0xcafe), 1);
        let ch = create_character(admin, &utf8(b"character"), &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        assert!(object::is_owner(ch, @0xcafe), 2);
        let ak = create_attack(admin, 100, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        assert!(object::is_owner(ak, @0xcafe), 3);        
        let de = create_defense(admin, 100, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        assert!(object::is_owner(de, @0xcafe), 4);
        let co = create_cost(admin, 100, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        assert!(object::is_owner(co, @0xcafe), 5);
        let at = create_attribute(admin, &utf8(b"attribute"), &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        assert!(object::is_owner(at, @0xcafe), 6);
        let sp = create_special_ability(admin, &utf8(b"skill"), &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        assert!(object::is_owner(sp, @0xcafe), 7);
        {
            let holder = borrow_global<CardHolder>(@0xcafe);
            assert!(token_objects_holder::holds(&holder.card_holder, &ca), 8);
            assert!(token_objects_holder::num_holds(&holder.card_holder) == 1, 9);
            assert!(token_objects_holder::holds(&holder.character_holder, &ch), 10);
            assert!(token_objects_holder::num_holds(&holder.character_holder) == 1, 11);
            assert!(token_objects_holder::holds(&holder.attack_holder, &ak), 12);
            assert!(token_objects_holder::num_holds(&holder.attack_holder) == 1, 13);
            assert!(token_objects_holder::holds(&holder.defense_holder, &de), 14);
            assert!(token_objects_holder::num_holds(&holder.defense_holder) == 1, 15);
            assert!(token_objects_holder::holds(&holder.cost_holder, &co), 16);
            assert!(token_objects_holder::num_holds(&holder.cost_holder) == 1, 17);
            assert!(token_objects_holder::holds(&holder.attribute_holder, &at), 18);
            assert!(token_objects_holder::num_holds(&holder.attribute_holder) == 1, 19);
            assert!(token_objects_holder::holds(&holder.special_ability_holder, &sp), 20);
            assert!(token_objects_holder::num_holds(&holder.special_ability_holder) == 1, 21);
        };
        {
            register(other);
            managed_transfer_card(admin, ca, @0xbeef);
        };
        {
            assert!(object::is_owner(ca, @0xbeef), 22);
            assert!(!object::is_owner(ca, @0xcafe), 23);
            let other_holder = borrow_global<CardHolder>(@0xbeef);
            assert!(token_objects_holder::holds(&other_holder.card_holder, &ca), 24);
            assert!(token_objects_holder::num_holds(&other_holder.card_holder) == 1, 25);  
        };
        {
            let holder = borrow_global<CardHolder>(@0xcafe);
            assert!(!token_objects_holder::holds(&holder.card_holder, &ca), 26);
            assert!(token_objects_holder::num_holds(&holder.card_holder) == 0, 27);
        };
        {
            managed_transfer_card(other, ca, @0xcafe);
        };
        {
            install_character(admin, &ca, &ch);
            install_attack(admin, &ca, &ak);
            install_defense(admin, &ca, &de);
            install_cost(admin, &ca, &co);
            install_attribute(admin, &ca, &at);
            install_special_ability(admin, &ca, &sp);
            let holder = borrow_global<CardHolder>(@0xcafe);
            assert!(object::is_owner(ch, object::object_address(&ca)), 28);
            assert!(!token_objects_holder::holds(&holder.character_holder, &ch), 29);
            assert!(object::is_owner(ak, object::object_address(&ca)), 30);
            assert!(!token_objects_holder::holds(&holder.attack_holder, &ak), 31);
            assert!(object::is_owner(de, object::object_address(&ca)), 32);
            assert!(!token_objects_holder::holds(&holder.defense_holder, &de), 33);
            assert!(object::is_owner(co, object::object_address(&ca)), 34);
            assert!(!token_objects_holder::holds(&holder.cost_holder, &co), 35);
            assert!(object::is_owner(at, object::object_address(&ca)), 36);
            assert!(!token_objects_holder::holds(&holder.attribute_holder, &at), 37);
            assert!(object::is_owner(sp, object::object_address(&ca)), 38);
            assert!(!token_objects_holder::holds(&holder.special_ability_holder, &sp), 39);
        };
        {
            managed_transfer_card(admin, ca, @0xbeef);
        };
        {
            uninstall_character(other, &ca);
            uninstall_attack(other, &ca);
            uninstall_defense(other, &ca);
            uninstall_cost(other, &ca);
            uninstall_attribute(other, &ca);
            uninstall_special_ability(other, &ca);
            let holder = borrow_global<CardHolder>(@0xbeef);
            assert!(object::is_owner(ch, @0xbeef), 40);
            assert!(token_objects_holder::holds(&holder.character_holder, &ch), 41);
            assert!(object::is_owner(ak, @0xbeef), 42);
            assert!(token_objects_holder::holds(&holder.attack_holder, &ak), 43);
            assert!(object::is_owner(de, @0xbeef), 44);
            assert!(token_objects_holder::holds(&holder.defense_holder, &de), 45);
            assert!(object::is_owner(co, @0xbeef), 46);
            assert!(token_objects_holder::holds(&holder.cost_holder, &co), 47);
            assert!(object::is_owner(at, @0xbeef), 48);
            assert!(token_objects_holder::holds(&holder.attribute_holder, &at), 49);
            assert!(object::is_owner(sp, @0xbeef), 50);
            assert!(token_objects_holder::holds(&holder.special_ability_holder, &sp), 51);
        }
    }

    #[test(admin = @0xcafe, other = @0xbeef)]
    #[expected_failure(abort_code = 327683, location = aptos_framework::object)]
    fun test_transfer_fail_card(admin: &signer) 
    acquires CardConfig, CardHolder {
        init_module(admin);
        let obj = create_card(admin, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        object::transfer(admin, obj, @0xbeef);
    }

    #[test(admin = @0xcafe, other = @0xbeef)]
    #[expected_failure(abort_code = 327685, location = character_cards::character_cards)]
    fun test_transfer_fail_transfer_twice(admin: &signer, other: &signer) 
    acquires CardConfig, CardHolder, CharacterCard {
        init_module(admin);
        let obj = create_card(admin, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        register(other);
        managed_transfer_card(admin, obj, @0xbeef);
        managed_transfer_card(admin, obj, @0xbeef);
    }

    #[test(admin = @0xcafe, other = @0xbeef)]
    #[expected_failure(abort_code = 327685, location = character_cards::character_cards)]
    fun test_transfer_fail_no_owner(admin: &signer, other: &signer) 
    acquires CardConfig, CardHolder, CharacterCard {
        init_module(admin);
        let obj = create_card(admin, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        register(other);
        managed_transfer_card(other, obj, @0xbeef);
    }

    #[test(admin = @0xcafe, other = @0xbeef)]
    #[expected_failure(abort_code = 327683, location = aptos_framework::object)]
    fun test_unmanaged_transfer_fail_chara(admin: &signer) 
    acquires Config, CardHolder {
        init_module(admin);
        let obj = create_character(admin, &utf8(b"name"), &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        object::transfer(admin, obj, @0xbeef);
    }

    #[test(admin = @0xcafe, other = @0xbeef)]
    #[expected_failure(abort_code = 327685, location = character_cards::character_cards)]
    fun test_fail_chara_install_twice(admin: &signer) 
    acquires CardConfig, Config, CardHolder, CharacterCard, Parts {
        init_module(admin);
        let ca = create_card(admin, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        let obj = create_character(admin, &utf8(b"name"), &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        install_character(admin, &ca, &obj);
        install_character(admin, &ca, &obj);
    }

    #[test(admin = @0xcafe, other = @0xbeef)]
    #[expected_failure(abort_code = 327685, location = character_cards::character_cards)]
    fun test_fail_chara_install_no_owener(admin: &signer, other: &signer) 
    acquires CardConfig, Config, CardHolder, CharacterCard, Parts {
        init_module(admin);
        let ca = create_card(admin, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        let obj = create_character(admin, &utf8(b"name"), &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        install_character(other, &ca, &obj);
    }

    #[test(admin = @0xcafe, other = @0xbeef)]
    #[expected_failure(abort_code = 65544, location = character_cards::character_cards)]
    fun test_fail_chara_uninstall_empty(admin: &signer) 
    acquires CardConfig, CardHolder, CharacterCard, Parts {
        init_module(admin);
        let ca = create_card(admin, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        uninstall_character(admin, &ca);
    }

    #[test(admin = @0xcafe, other = @0xbeef)]
    #[expected_failure(abort_code = 327685, location = character_cards::character_cards)]
    fun test_fail_chara_uninstall_no_owner(admin: &signer, other: &signer) 
    acquires CardConfig, CardHolder, CharacterCard, Parts {
        init_module(admin);
        let ca = create_card(admin, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        uninstall_character(other, &ca);
    }

    #[test(admin = @0xcafe, other = @0xbeef)]
    #[expected_failure(abort_code = 327683, location = aptos_framework::object)]
    fun test_unmanaged_transfer_fail_attack(admin: &signer) 
    acquires Config, CardHolder {
        init_module(admin);
        let obj = create_attack(admin, 100, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        object::transfer(admin, obj, @0xbeef);
    }

    #[test(admin = @0xcafe, other = @0xbeef)]
    #[expected_failure(abort_code = 327685, location = character_cards::character_cards)]
    fun test_fail_attack_install_twice(admin: &signer) 
    acquires CardConfig, Config, CardHolder, CharacterCard, Parts {
        init_module(admin);
        let ca = create_card(admin, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        let obj = create_attack(admin, 100, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        install_attack(admin, &ca, &obj);
        install_attack(admin, &ca, &obj);
    }

    #[test(admin = @0xcafe, other = @0xbeef)]
    #[expected_failure(abort_code = 327685, location = character_cards::character_cards)]
    fun test_fail_attack_install_no_owner(admin: &signer, other: &signer) 
    acquires CardConfig, Config, CardHolder, CharacterCard, Parts {
        init_module(admin);
        let ca = create_card(admin, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        let obj = create_attack(admin, 100, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        install_attack(other, &ca, &obj);
    }

    #[test(admin = @0xcafe, other = @0xbeef)]
    #[expected_failure(abort_code = 65544, location = character_cards::character_cards)]
    fun test_fail_attack_uninstall_empty(admin: &signer) 
    acquires CardConfig, CardHolder, CharacterCard, Parts {
        init_module(admin);
        let ca = create_card(admin, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        uninstall_attack(admin, &ca);
    }

    #[test(admin = @0xcafe, other = @0xbeef)]
    #[expected_failure(abort_code = 327685, location = character_cards::character_cards)]
    fun test_fail_attack_uninstall_no_owner(admin: &signer, other: &signer) 
    acquires CardConfig, CardHolder, CharacterCard, Parts {
        init_module(admin);
        let ca = create_card(admin, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        uninstall_attack(other, &ca);
    }

    #[test(admin = @0xcafe, other = @0xbeef)]
    #[expected_failure(abort_code = 327683, location = aptos_framework::object)]
    fun test_unmanaged_transfer_fail_defense(admin: &signer) 
    acquires Config, CardHolder {
        init_module(admin);
        let obj = create_defense(admin, 100, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        object::transfer(admin, obj, @0xbeef);
    }

    #[test(admin = @0xcafe, other = @0xbeef)]
    #[expected_failure(abort_code = 327685, location = character_cards::character_cards)]
    fun test_fail_defense_install_twice(admin: &signer) 
    acquires CardConfig, Config, CardHolder, CharacterCard, Parts {
        init_module(admin);
        let ca = create_card(admin, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        let obj = create_defense(admin, 100, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        install_defense(admin, &ca, &obj);
        install_defense(admin, &ca, &obj);
    }

    #[test(admin = @0xcafe, other = @0xbeef)]
    #[expected_failure(abort_code = 327685, location = character_cards::character_cards)]
    fun test_fail_defense_install_no_owner(admin: &signer, other: &signer) 
    acquires CardConfig, Config, CardHolder, CharacterCard, Parts {
        init_module(admin);
        let ca = create_card(admin, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        let obj = create_defense(admin, 100, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        install_defense(other, &ca, &obj);
    }

    #[test(admin = @0xcafe, other = @0xbeef)]
    #[expected_failure(abort_code = 65544, location = character_cards::character_cards)]
    fun test_fail_defense_uninstall_empty(admin: &signer) 
    acquires CardConfig, CardHolder, CharacterCard, Parts {
        init_module(admin);
        let ca = create_card(admin, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        uninstall_defense(admin, &ca);
    }

    #[test(admin = @0xcafe, other = @0xbeef)]
    #[expected_failure(abort_code = 327685, location = character_cards::character_cards)]
    fun test_fail_defense_uninstall_no_owner(admin: &signer, other: &signer) 
    acquires CardConfig, CardHolder, CharacterCard, Parts {
        init_module(admin);
        let ca = create_card(admin, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        uninstall_defense(other, &ca);
    }

    #[test(admin = @0xcafe, other = @0xbeef)]
    #[expected_failure(abort_code = 327683, location = aptos_framework::object)]
    fun test_unmanaged_transfer_fail_cost(admin: &signer) 
    acquires Config, CardHolder {
        init_module(admin);
        let obj = create_cost(admin, 100, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        object::transfer(admin, obj, @0xbeef);
    }

    #[test(admin = @0xcafe, other = @0xbeef)]
    #[expected_failure(abort_code = 327685, location = character_cards::character_cards)]
    fun test_fail_cost_install_twice(admin: &signer) 
    acquires CardConfig, Config, CardHolder, CharacterCard, Parts {
        init_module(admin);
        let ca = create_card(admin, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        let obj = create_cost(admin, 100, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        install_cost(admin, &ca, &obj);
        install_cost(admin, &ca, &obj);
    }

    #[test(admin = @0xcafe, other = @0xbeef)]
    #[expected_failure(abort_code = 327685, location = character_cards::character_cards)]
    fun test_fail_cost_install_no_owner(admin: &signer, other: &signer) 
    acquires CardConfig, Config, CardHolder, CharacterCard, Parts {
        init_module(admin);
        let ca = create_card(admin, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        let obj = create_cost(admin, 100, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        install_cost(other, &ca, &obj);
    }

    #[test(admin = @0xcafe, other = @0xbeef)]
    #[expected_failure(abort_code = 65544, location = character_cards::character_cards)]
    fun test_fail_cost_uninstall_empty(admin: &signer) 
    acquires CardConfig, CardHolder, CharacterCard, Parts {
        init_module(admin);
        let ca = create_card(admin, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        uninstall_cost(admin, &ca);
    }

    #[test(admin = @0xcafe, other = @0xbeef)]
    #[expected_failure(abort_code = 327685, location = character_cards::character_cards)]
    fun test_fail_cost_uninstall_no_owner(admin: &signer, other: &signer) 
    acquires CardConfig, CardHolder, CharacterCard, Parts {
        init_module(admin);
        let ca = create_card(admin, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        uninstall_cost(other, &ca);
    }

    #[test(admin = @0xcafe, other = @0xbeef)]
    #[expected_failure(abort_code = 327683, location = aptos_framework::object)]
    fun test_unmanaged_transfer_fail_attr(admin: &signer) 
    acquires Config, CardHolder {
        init_module(admin);
        let obj = create_attribute(admin, &utf8(b"name"), &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        object::transfer(admin, obj, @0xbeef);
    }

    #[test(admin = @0xcafe, other = @0xbeef)]
    #[expected_failure(abort_code = 327685, location = character_cards::character_cards)]
    fun test_fail_attr_install_twice(admin: &signer) 
    acquires CardConfig, Config, CardHolder, CharacterCard, Parts {
        init_module(admin);
        let ca = create_card(admin, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        let obj = create_attribute(admin, &utf8(b"name"), &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        install_attribute(admin, &ca, &obj);
        install_attribute(admin, &ca, &obj);
    }

    #[test(admin = @0xcafe, other = @0xbeef)]
    #[expected_failure(abort_code = 327685, location = character_cards::character_cards)]
    fun test_fail_attr_install_no_owner(admin: &signer, other: &signer) 
    acquires CardConfig, Config, CardHolder, CharacterCard, Parts {
        init_module(admin);
        let ca = create_card(admin, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        let obj = create_attribute(admin, &utf8(b"name"), &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        install_attribute(other, &ca, &obj);
    }

    #[test(admin = @0xcafe, other = @0xbeef)]
    #[expected_failure(abort_code = 65544, location = character_cards::character_cards)]
    fun test_fail_attr_uninstall_empty(admin: &signer) 
    acquires CardConfig, CardHolder, CharacterCard, Parts {
        init_module(admin);
        let ca = create_card(admin, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        uninstall_attribute(admin, &ca);
    }

    #[test(admin = @0xcafe, other = @0xbeef)]
    #[expected_failure(abort_code = 327685, location = character_cards::character_cards)]
    fun test_fail_attr_uninstall_no_owner(admin: &signer, other: &signer) 
    acquires CardConfig, CardHolder, CharacterCard, Parts {
        init_module(admin);
        let ca = create_card(admin, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        uninstall_attribute(other, &ca);
    }

    #[test(admin = @0xcafe, other = @0xbeef)]
    #[expected_failure(abort_code = 327683, location = aptos_framework::object)]
    fun test_unmanaged_transfer_fail_sp(admin: &signer) 
    acquires Config, CardHolder {
        init_module(admin);
        let obj = create_special_ability(admin, &utf8(b"name"), &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        object::transfer(admin, obj, @0xbeef);
    }

    #[test(admin = @0xcafe, other = @0xbeef)]
    #[expected_failure(abort_code = 327685, location = character_cards::character_cards)]
    fun test_fail_sp_install_twice(admin: &signer) 
    acquires CardConfig, Config, CardHolder, CharacterCard, Parts {
        init_module(admin);
        let ca = create_card(admin, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        let obj = create_special_ability(admin, &utf8(b"name"), &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        install_special_ability(admin, &ca, &obj);
        install_special_ability(admin, &ca, &obj);
    }

    #[test(admin = @0xcafe, other = @0xbeef)]
    #[expected_failure(abort_code = 327685, location = character_cards::character_cards)]
    fun test_fail_sp_install_no_owner(admin: &signer, other: &signer) 
    acquires CardConfig, Config, CardHolder, CharacterCard, Parts {
        init_module(admin);
        let ca = create_card(admin, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        let obj = create_special_ability(admin, &utf8(b"name"), &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        install_special_ability(other, &ca, &obj);
    }

    #[test(admin = @0xcafe, other = @0xbeef)]
    #[expected_failure(abort_code = 65544, location = character_cards::character_cards)]
    fun test_fail_sp_uninstall_empty(admin: &signer) 
    acquires CardConfig, CardHolder, CharacterCard, Parts {
        init_module(admin);
        let ca = create_card(admin, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        uninstall_special_ability(admin, &ca);
    }

    #[test(admin = @0xcafe, other = @0xbeef)]
    #[expected_failure(abort_code = 327685, location = character_cards::character_cards)]
    fun test_fail_sp_uninstal_no_owner(admin: &signer, other: &signer) 
    acquires CardConfig, CardHolder, CharacterCard, Parts {
        init_module(admin);
        let ca = create_card(admin, &utf8(b"desc"), &utf8(b"name"), &utf8(b"uri"));
        uninstall_special_ability(other, &ca);
    }   
}