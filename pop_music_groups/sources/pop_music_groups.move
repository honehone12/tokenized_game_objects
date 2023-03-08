module pop_music_groups::pop_music_groups {
    use std::string::String;
    use std::option::{Option};
    use aptos_framework::object::{Self, Object};

    // looks actually tokenized fan movie
    // this kind of user-choosed-content(easier than user-created-content)
    // might be a key 
    #[resource_group_member(group = object::ObjectGroup)]
    struct Show has key {
        members: vector<Object<PopStar>>,
        performance: Option<Object<Dance>>
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct PopStar has key {
        name: String
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct Dance has key {
        name: String, //ID
        music: Option<Object<Music>>,
        required_members: u64
    }

    #[resource_group_member(group = object::ObjectGroup)]
    struct Music has key {
        name: String, // ID
        version: String
    }
}