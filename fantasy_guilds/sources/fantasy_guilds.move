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

        job: Option<Object<Job>>,
        skill: vector<Object<Skill>>,

        weapon: Option<Object<Weapon>>,
        protector: Option<Object<Protector>>,
        items: vector<Object<Item>>
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct Job has key {
        name: String
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct Skill has key {
        name: String
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct Weapon has key {
        name: String
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct Protector has key {
        name: String
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct Item has key {
        name: String
    }
}