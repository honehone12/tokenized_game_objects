module rock_bands::rock_bands {
    use std::string::{String};
    use std::option::{Option};
    use aptos_framework::object::{Self, Object};
    
    #[resource_group_member(group = object::ObjectGroup)]
    struct Band has key {
        guitar: Option<Object<Musician<Instrument<Guitar>>>>,
        bass: Option<Object<Musician<Instrument<Bass>>>>,
        drums: Option<Object<Musician<Instrument<Drums>>>>,
        keyboard: Option<Object<Musician<Instrument<Keyboard>>>>
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct Musician<phantom I> has key {
        name: String,
        instrument: Option<Object<Instrument<I>>>,
        can_sing: bool
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct Instrument<phantom I> has key {
        name: String
    }

    struct Guitar {}
    struct Bass {}
    struct Drums {}
    struct Keyboard {}
}