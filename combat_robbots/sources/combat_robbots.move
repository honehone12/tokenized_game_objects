module combat_robbots::combat_robbots {
    use std::string::String;
    use std::option::Option;
    use aptos_framework::object::{Self, Object};

    #[resource_group_member(group = object::ObjectGroup)]
    struct Robbot has key {
        name: String,
        leg: Option<Object<Unit<LegUnit>>>,
        body: Option<Object<Unit<BodyUnit>>>,
        right_shoulder: Option<Object<Unit<ShoulderUnit<Right>>>>,
        right_arm: Option<Object<Unit<ArmUnit<Right>>>>,
        left_shoulder: Option<Object<Unit<ShoulderUnit<Left>>>>,
        left_arm: Option<Object<Unit<ArmUnit<Left>>>>,
        backpack: Option<Object<Unit<BackpackUnit>>>,
        head: Option<Object<Unit<HeadUnit>>>
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct Unit<U: store> has key {
        name: String,
        unit: U
    }

    struct LegUnit has store {
        armor: Option<Object<Armor<Leg>>>,
        booster: Option<Object<Booster<Leg>>>
    }

    struct BodyUnit has store {
        armor: Option<Object<Armor<Body>>>
    }

    struct ShoulderUnit<phantom RL> has store {
        armor: Option<Object<Armor<Shoulder<RL>>>>,
        weapon: Option<Object<Weapon<Shoulder<RL>>>>
    }

    struct ArmUnit<phantom RL> has store {
        armor: Option<Object<Armor<Arm<RL>>>>,
        weapon: Option<Object<Weapon<Arm<RL>>>>
    }

    struct BackpackUnit has store {
        booster: Option<Object<Booster<Backpack>>>
    }

    struct HeadUnit has store {
        scope: u64,
        armor: Option<Object<Armor<Head>>>
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct Armor<phantom P> has key {
        name: String,
        defense: u64,
        weight: u64
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct Weapon<phantom P> has key {
        name: String,
        strength: u64,
        cost: u64
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct Booster<phantom P> has key {
        name: String,
        power: u64,
        cost: u64
    }

    struct Leg {}
    struct Body {}
    struct Shoulder<phantom RL> {}
    struct Arm<phantom RL> {}
    struct Backpack {}
    struct Head {}

    struct Right {}
    struct Left {}
}