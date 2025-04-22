package integral_domain

import "core:testing"
import "core:log"
import "core:strings"
import "../../prop_based"
import "../ring"
import "../base"

// called to run prop based tests to see if a integral domain implementation is memory safe
test_memory_safety_axioms :: proc(t: ^testing.T, generator : prop_based.Generator($T), id : IntegralDomain(T))
{
    ring.test_memory_safety_axioms(t, generator, id.commutative_ring.ring)

    cancel_is_safe_1 :: proc(id : IntegralDomain(T), a : T, b : T) -> bool
    {
        if id.eq(a, id.add_identity) || id.eq(b, id.add_identity)
        {
            return true
        }

        ab : T
        defer id.delete(ab)
        id.mul(&ab, a, b)

        ans1 : T
        defer id.delete(ans1)
        id.set(&ans1, ab)
        id.cancel(&ans1, ans1, b)

        ans2 : T
        defer id.delete(ans2)
        id.cancel(&ans2, ab, b)

        return id.eq(ans1, ans2)
    }

    prop_based.check(
        t,
        id, generator, generator, cancel_is_safe_1
    )

    cancel_is_safe_2 :: proc(id : IntegralDomain(T), a : T) -> bool
    {
        if id.eq(a, id.add_identity)
        {
            return true
        }

        ans1 : T
        defer id.delete(ans1)
        id.set(&ans1, a)
        id.cancel(&ans1, ans1, ans1)

        ans2 : T
        defer id.delete(ans2)
        id.cancel(&ans2, a, a)

        return id.eq(ans1, ans2)
    }

    prop_based.check(
        t,
        id, generator, cancel_is_safe_2
    )
}

// called to run prop based tests to see if a ring implementation violates the integral domain axioms
test_integral_domain_axioms :: proc(t: ^testing.T, generator : prop_based.Generator($T), id : IntegralDomain(T))
{
    ring.test_commutative_ring_axioms(t, generator, id.commutative_ring)

    cancel_preserves_equality_prop :: proc(id : IntegralDomain(T), a : T, b : T, c : T) -> bool
    {
        if id.eq(a, id.add_identity) || id.eq(b, id.add_identity) || id.eq(c, id.add_identity)
        {
            return true
        }

        ab : T
        defer id.delete(ab)
        ac : T
        defer id.delete(ac)
        bc : T
        defer id.delete(bc)
        abc : T
        defer id.delete(abc)

        id.mul(&ab, a, b)
        id.mul(&ac, a, c)
        id.mul(&bc, b, c)
        id.mul(&abc, ab, c)

        base.log_base_object(id.commutative_ring.ring.base, "abc =", abc)

        cancel_a : T
        defer id.delete(cancel_a)
        cancel_b : T
        defer id.delete(cancel_b)
        cancel_c : T
        defer id.delete(cancel_c)

        id.cancel(&cancel_a, abc, a)
        base.log_base_object(id.commutative_ring.ring.base, "abc / a", cancel_a)

        id.cancel(&cancel_b, abc, b)
        base.log_base_object(id.commutative_ring.ring.base, "abc / b", cancel_b)

        id.cancel(&cancel_c, abc, c)
        base.log_base_object(id.commutative_ring.ring.base, "abc / c", cancel_c)

        return id.eq(ab, cancel_c) && id.eq(ac, cancel_b) && id.eq(bc, cancel_a)
    }

    prop_based.check(
        t,
        id, generator, generator, generator, cancel_preserves_equality_prop
    )
}
