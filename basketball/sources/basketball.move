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

        pg_skill:  Option<Object<Skill<PointGuard>>>,
        sg_skill: Option<Object<Skill<ShootingGuard>>>,
        sf_skill: Option<Object<Skill<SmallForwward>>>,
        pf_skill: Option<Object<Skill<PowerForward>>>,
        c_skill: Option<Object<Skill<Center>>>
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct Skill<phantom P> has key {
        value: u64
    }

    struct PointGuard {}
    struct ShootingGuard {}
    struct SmallForwward {}
    struct PowerForward {}
    struct Center {} 
}