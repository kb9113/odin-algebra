package ring

import "core:testing"
import "core:log"
import "core:strings"
import "../../prop_based"
import "../base"

// called to run prop based tests to see if a ring implementation is memory safe
test_memory_safety_axioms :: proc(t: ^testing.T, generator : prop_based.Generator($T), ring : Ring(T))
{
    base.test_memory_safety_axioms(t, generator, ring.base)

    add_is_safe_1 :: proc(r : Ring(T), a : T, b : T) -> bool
    {
        ans1 : T
        defer r.delete(ans1)
        r.set(&ans1, a)
        r.add(&ans1, ans1, b)

        ans2 : T
        defer r.delete(ans2)
        r.add(&ans2, a, b)

        return r.eq(ans1, ans2)
    }

    prop_based.check(
        t,
        ring, generator, generator, add_is_safe_1
    )

    add_is_safe_2 :: proc(r : Ring(T), a : T) -> bool
    {
        ans1 : T
        defer r.delete(ans1)
        r.set(&ans1, a)
        r.add(&ans1, ans1, ans1)

        ans2 : T
        defer r.delete(ans2)
        r.add(&ans2, a, a)

        return r.eq(ans1, ans2)
    }

    prop_based.check(
        t,
        ring, generator, add_is_safe_2
    )

    sub_is_safe_1 :: proc(r : Ring(T), a : T, b : T) -> bool
    {
        ans1 : T
        defer r.delete(ans1)
        r.set(&ans1, a)
        r.sub(&ans1, ans1, b)

        ans2 : T
        defer r.delete(ans2)
        r.sub(&ans2, a, b)

        return r.eq(ans1, ans2)
    }

    prop_based.check(
        t,
        ring, generator, generator, sub_is_safe_1
    )

    sub_is_safe_2 :: proc(r : Ring(T), a : T) -> bool
    {
        ans1 : T
        defer r.delete(ans1)
        r.set(&ans1, a)
        r.sub(&ans1, ans1, ans1)

        ans2 : T
        defer r.delete(ans2)
        r.sub(&ans2, a, a)

        return r.eq(ans1, ans2)
    }

    prop_based.check(
        t,
        ring, generator, sub_is_safe_2
    )

    mul_is_safe_1 :: proc(r : Ring(T), a : T, b : T) -> bool
    {
        ans1 : T
        defer r.delete(ans1)
        r.set(&ans1, a)
        r.mul(&ans1, ans1, b)

        ans2 : T
        defer r.delete(ans2)
        r.mul(&ans2, a, b)

        return r.eq(ans1, ans2)
    }

    prop_based.check(
        t,
        ring, generator, generator, mul_is_safe_1
    )

    mul_is_safe_2 :: proc(r : Ring(T), a : T) -> bool
    {
        ans1 : T
        defer r.delete(ans1)
        r.set(&ans1, a)
        r.mul(&ans1, ans1, ans1)

        ans2 : T
        defer r.delete(ans2)
        r.mul(&ans2, a, a)

        return r.eq(ans1, ans2)
    }

    prop_based.check(
        t,
        ring, generator, mul_is_safe_2
    )

    neg_is_safe :: proc(r : Ring(T), a : T) -> bool
    {
        ans1 : T
        defer r.delete(ans1)
        r.set(&ans1, a)
        r.neg(&ans1, ans1)

        ans2 : T
        defer r.delete(ans2)
        r.neg(&ans2, a)

        return r.eq(ans1, ans2)
    }

    prop_based.check(
        t,
        ring, generator, neg_is_safe
    )
}

// called to run prop based tests to see if a ring implementation violates the commutative ring axioms
test_commutative_ring_axioms :: proc(t: ^testing.T, generator : prop_based.Generator($T), ring : CommutativeRing(T))
{
    test_ring_axioms(t, generator, ring.ring)

    mul_commutative_prop :: proc(r : CommutativeRing(T), a : T, b : T) -> bool
    {
        ab : T
        defer r.delete(ab)
        r.mul(&ab, a, b)

        ba : T
        defer r.delete(ba)
        r.mul(&ba, b, a)

        return r.eq(ab, ba)
    }

    prop_based.check(
        t,
        ring, generator, generator, mul_commutative_prop
    )
}

// called to run prop based tests to see if a ring implementation violates the ring axioms
test_ring_axioms :: proc(t: ^testing.T, generator : prop_based.Generator($T), ring : Ring(T))
{
    base.test_base_axioms(t, generator, ring.base)

    add_associative_prop :: proc(r : Ring(T), a : T, b : T, c : T) -> bool
    {
        ab1 : T
        defer r.delete(ab1)
        abc1 : T
        defer r.delete(abc1)
        r.add(&ab1, a, b)
        r.add(&abc1, ab1, c)

        bc2 : T
        defer r.delete(bc2)
        abc2 : T
        defer r.delete(abc2)
        r.add(&bc2, b, c)
        r.add(&abc2, a, bc2)

        base.log_base_object(r.base, "(a + b) + c =", abc1)
        base.log_base_object(r.base, "a + (b + c) =", abc2)

        return r.eq(abc1, abc2)
    }

    prop_based.check(
        t,
        ring, generator, generator, generator, add_associative_prop
    )

    add_commutative_prop :: proc(r : Ring(T), a : T, b : T) -> bool
    {
        ab : T
        defer r.delete(ab)
        r.add(&ab, a, b)

        ba : T
        defer r.delete(ba)
        r.add(&ba, b, a)

        return r.eq(ab, ba)
    }

    prop_based.check(
        t,
        ring, generator, generator, add_commutative_prop
    )

    add_ident_prop :: proc(r : Ring(T), a : T) -> bool
    {
        ans : T
        defer r.delete(ans)
        r.add(&ans, a, r.add_identity)

        return r.eq(ans, a)
    }

    prop_based.check(
        t,
        ring, generator, add_ident_prop
    )

    add_neg_prop :: proc(r : Ring(T), a : T) -> bool
    {
        neg_a : T
        defer r.delete(neg_a)
        ans : T
        defer r.delete(ans)
        r.neg(&neg_a, a)
        r.add(&ans, a, neg_a)

        return r.eq(ans, r.add_identity)
    }

    prop_based.check(
        t,
        ring, generator, add_neg_prop
    )

    mul_associative_prop :: proc(r : Ring(T), a : T, b : T, c : T) -> bool
    {
        ab1 : T
        defer r.delete(ab1)
        abc1 : T
        defer r.delete(abc1)
        r.mul(&ab1, a, b)
        r.mul(&abc1, ab1, c)

        bc2 : T
        defer r.delete(bc2)
        abc2 : T
        defer r.delete(abc2)
        r.mul(&bc2, b, c)
        r.mul(&abc2, a, bc2)

        return r.eq(abc1, abc2)
    }

    prop_based.check(
        t,
        ring, generator, generator, generator, mul_associative_prop
    )

    mul_ident_prop :: proc(r : Ring(T), a : T) -> bool
    {
        ans : T
        defer r.delete(ans)
        r.mul(&ans, a, r.mul_identity)

        return r.eq(ans, a)
    }

    prop_based.check(
        t,
        ring, generator, mul_ident_prop
    )

    mul_left_distributive :: proc(r : Ring(T), a : T, b : T, c : T) -> bool
    {
        ab : T
        defer r.delete(ab)
        r.mul(&ab, a, b)

        ac : T
        defer r.delete(ac)
        r.mul(&ac, a, c)

        ab_plus_ac : T
        defer r.delete(ab_plus_ac)
        r.add(&ab_plus_ac, ab, ac)

        b_plus_c : T
        defer r.delete(b_plus_c)
        r.add(&b_plus_c, b, c)

        a_b_plus_c : T
        defer r.delete(a_b_plus_c)
        r.mul(&a_b_plus_c, a, b_plus_c)

        return r.eq(a_b_plus_c, ab_plus_ac)
    }

    prop_based.check(
        t,
        ring, generator, generator, generator, mul_left_distributive
    )

    mul_right_distributive :: proc(r : Ring(T), a : T, b : T, c : T) -> bool
    {
        ba : T
        defer r.delete(ba)
        r.mul(&ba, b, a)

        ca : T
        defer r.delete(ca)
        r.mul(&ca, c, a)

        ba_plus_ca : T
        defer r.delete(ba_plus_ca)
        r.add(&ba_plus_ca, ba, ca)

        b_plus_c : T
        defer r.delete(b_plus_c)
        r.add(&b_plus_c, b, c)

        b_plus_c_a : T
        defer r.delete(b_plus_c_a)
        r.mul(&b_plus_c_a, b_plus_c, a)

        return r.eq(b_plus_c_a, ba_plus_ca)
    }

    prop_based.check(
        t,
        ring, generator, generator, generator, mul_right_distributive
    )

    // this is not an axiom but it is important sub is implemented correctly
    sub_is_neg :: proc(r : Ring(T), a : T, b : T) -> bool
    {
        ans1 : T
        defer r.delete(ans1)
        r.sub(&ans1, a, b)

        neg_b : T
        defer r.delete(neg_b)
        ans2 : T
        defer r.delete(ans2)
        r.neg(&neg_b, b)
        r.add(&ans2, a, neg_b)

        base.log_base_object(r.base, "a - b =", ans1)
        base.log_base_object(r.base, "a + (-b)", ans2)

        return r.eq(ans1, ans2)
    }

    prop_based.check(
        t,
        ring, generator, generator, sub_is_neg
    )
}
