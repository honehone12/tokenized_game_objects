module basketball::baketball {
    use std::string::String;
    use std::option::{Option};
    use aptos_framework::object::{Self, Object};

    #[resource_group_member(group = object::ObjectGroup)]
    struct Members {
        name: String,
        member_1: Option<Object<Player>>,
        member_2: Option<Object<Player>>,
        member_3: Option<Object<Player>>,
        member_4: Option<Object<Player>>,
        member_5: Option<Object<Player>>,
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct Player has key {
        name: String,
        height: u64,
        weight: u64,

        power: u64,
        speed: u64,
        jump: u64,
        accuracy: u64,
        tactics: u64,

        pg_skill:  Option<Object<PointGuardSkill>>,
        sg_skill: Option<Object<ShootingGuardSkill>>,
        sf_skill: Option<Object<SmallForwwardSkill>>,
        pf_skill: Option<Object<PowerForwardSkill>>,
        c_skill: Option<Object<CenterSkill>>
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct PointGuardSkill has key {
        value: u64
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct ShootingGuardSkill has key {
        value: u64
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct SmallForwwardSkill has key {
        value: u64
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct PowerForwardSkill has key {
        value: u64
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct CenterSkill has key {
        value: u64
    } 
}