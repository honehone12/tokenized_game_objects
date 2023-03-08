module rock_bands::rock_bands {
    use std::string::{String};
    use std::option::{Option};
    use aptos_framework::object::{Self, Object};
    
    #[resource_group_member(group = object::ObjectGroup)]
    struct Band has key {
        guitar: Option<Object<Musician<Guitar>>>,
        bass: Option<Object<Musician<Bass>>>,
        drums: Option<Object<Musician<Drums>>>,
        keyboard: Option<Object<Musician<Keyboard>>>
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct Musician<phantom I: key> has key {
        name: String,
        instrument: Option<Object<I>>,
        can_sing: bool
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct Guitar has key {
        name: String
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct Bass has key {
        name: String
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct Drums has key {
        name: String
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct Keyboard has key {
        name: String
    }
}