module token_objects_holder::token_objects_holder {
    use std::error;
    use std::signer;
    use std::vector;
    use aptos_framework::object::{Self, Object};

    const E_TOKEN_ALREADY_EXISTS: u64 = 1;
    const E_TOKEN_NOT_EXISTS: u64 = 2;
    const E_HOLDER_NOT_EXISTS: u64 = 3;
    const E_NOT_OWNER: u64 = 4;
    const E_STILL_OWNER: u64 = 5;

    struct TokenObjectsHolder<phantom T: key> has store {
        tokens: vector<address>
    }

    public fun new<T: key>(): TokenObjectsHolder<T> {
        TokenObjectsHolder{
            tokens: vector::empty<address>()
        }
    }

    public fun num_holds<T: key>(holder: &TokenObjectsHolder<T>): u64 {
        vector::length(&holder.tokens)
    }

    public fun holds<T: key>(holder: &TokenObjectsHolder<T> , object: &Object<T>): bool {
        vector::contains(&holder.tokens, &object::object_address(object))
    }

    public fun add_to_holder<T: key>(holder: &mut TokenObjectsHolder<T>, object: Object<T>) {
        let obj_addr = object::object_address(&object);
        if (vector::length(&holder.tokens) != 0) {
            assert!(
                !vector::contains(&holder.tokens, &obj_addr),
                error::already_exists(E_TOKEN_ALREADY_EXISTS)
            );
        };
        vector::push_back(&mut holder.tokens, obj_addr);
    }

    public fun remove_from_holder<T: key>(holder: &mut TokenObjectsHolder<T>, object: Object<T>) {
        if (vector::length(&holder.tokens) == 0) {
            return
        };
        let obj_addr = object::object_address(&object);
        let (ok, idx) = vector::index_of(&holder.tokens, &obj_addr);
        assert!(
            ok,
            error::not_found(E_TOKEN_NOT_EXISTS)
        );
        vector::swap_remove(&mut holder.tokens, idx);
    }

    public fun update<T: key>(account: &signer, holder: &mut TokenObjectsHolder<T>) {
        if (vector::length(&holder.tokens) == 0) {
            return
        };

        let addr = signer::address_of(account);
        let new_vec = vector::empty<address>();
        let iter = vector::length(&holder.tokens);
        let i = 0;
        while (i < iter) {
            let obj_addr = vector::borrow(&holder.tokens, i);
            let obj = object::address_to_object<T>(*obj_addr);
            if (object::is_owner<T>(obj, addr)) {
                vector::push_back(&mut new_vec, *obj_addr);
            };
            i = i + 1;
        };
        holder.tokens = new_vec;
    }

    #[test_only]
    struct TestToken has key {
    }

    #[test(account = @123)] 
    fun test_holder(account: &signer) {
        let cctor = object::create_named_object(account, b"testobj");
        let obj_signer = object::generate_signer(&cctor);
        move_to(&obj_signer, TestToken{});
        let obj = object::object_from_constructor_ref(&cctor);
        let holder = new<TestToken>();
        assert!(
            num_holds<TestToken>(&holder) == 0,
            0
        );
        add_to_holder<TestToken>(&mut holder, obj);
        assert!(
            num_holds<TestToken>(&holder) == 1 && holds(&holder, &obj),
            1
        );
        remove_from_holder<TestToken>(&mut holder, obj);
        assert!(
            num_holds<TestToken>(&holder) == 0 && !holds(&holder, &obj),
            2
        );
        TokenObjectsHolder<TestToken>{tokens: _} = holder;
    }

    #[test(account = @123)] 
    #[expected_failure(
        abort_code = 0x80001,
        location = Self
    )]
    fun test_add_twice(account: &signer) {
        let cctor = object::create_named_object(account, b"testobj");
        let obj_signer = object::generate_signer(&cctor);
        move_to(&obj_signer, TestToken{});
        let obj = object::object_from_constructor_ref(&cctor);
        let holder = new<TestToken>();
        add_to_holder<TestToken>(&mut holder, obj);
        add_to_holder<TestToken>(&mut holder, obj);
        TokenObjectsHolder<TestToken>{tokens: _} = holder;
    }

    #[test(account = @123)] 
    #[expected_failure(
        abort_code = 0x60002,
        location = Self
    )]
    fun test_remove_twice(account: &signer) {
        let cctor = object::create_named_object(account, b"staticobj");
        let obj_signer = object::generate_signer(&cctor);
        move_to(&obj_signer, TestToken{});
        let obj = object::object_from_constructor_ref(&cctor);
        let holder = new<TestToken>();
        add_to_holder<TestToken>(&mut holder, obj);
        let cctor = object::create_named_object(account, b"testobj");
        let obj_signer = object::generate_signer(&cctor);
        move_to(&obj_signer, TestToken{});
        let obj = object::object_from_constructor_ref(&cctor);
        add_to_holder<TestToken>(&mut holder, obj);
        remove_from_holder<TestToken>(&mut holder, obj);
        remove_from_holder<TestToken>(&mut holder, obj);
        TokenObjectsHolder<TestToken>{tokens: _} = holder;
    }

    #[test(account = @123)]
    fun test_update(account: &signer) {
        let cctor = object::create_named_object(account, b"testobj");
        let obj_signer = object::generate_signer(&cctor);
        move_to(&obj_signer, TestToken{});
        let obj = object::object_from_constructor_ref(&cctor);
        let holder = new<TestToken>();
        add_to_holder<TestToken>(&mut holder, obj);

        object::transfer(account, obj, @234);
        assert!(
            num_holds<TestToken>(&holder) == 1,
            0
        );
        assert!(
            object::owner(obj) == @234,
            1
        );
        update<TestToken>(account, &mut holder);
        assert!(
            num_holds<TestToken>(&holder) == 0,
            0
        );
        TokenObjectsHolder<TestToken>{tokens: _} = holder;
    }
}
