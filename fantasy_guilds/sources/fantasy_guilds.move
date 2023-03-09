module fantasy_guilds::fantasy_guilds {
    use std::string::String;
    use std::option::Option;
    use aptos_framework::object::{Self, Object};

    #[resource_group_member(group = object::ObjectGroup)]
    struct Guild has key {
        name: String,
        members: vector<Object<Actor>>
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct Actor has key {
        name: String,
        level: u64,
        pysical: u64,
        magical: u64,

        job: Option<Object<Slot<Job>>>,
        skill: vector<Object<Skill>>,

        weapon: Option<Object<Slot<Weapon>>>,
        protector: Option<Object<Slot<Protector>>>,
        items: vector<Object<Slot<Item>>>
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct Slot<T: store> {
        slot: T
    }

    struct Job has store {
        name: String
    }

    struct Skill has store {
        name: String
    }

    struct Weapon has store {
        name: String,
        value: u64
    }

    struct Protector has store {
        name: String,
        value: u64
    }

    struct Item has store {
        name: String,
        value: u64
    }
}