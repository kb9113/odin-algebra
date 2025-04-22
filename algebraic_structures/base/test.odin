package base

import "core:testing"
import "core:log"
import "../../prop_based"

test_memory_safety_axioms :: proc(t: ^testing.T, generator : prop_based.Generator($T), base : Base(T))
{
    set_is_safe :: proc(base : Base(T), a : T) -> bool
    {
        ans1 : T
        defer base.delete(ans1)
        base.set(&ans1, a)
        base.set(&ans1, ans1)

        ans2 : T
        defer base.delete(ans2)
        base.set(&ans2, a)

        return base.eq(ans1, ans2)
    }

    prop_based.check(
        t,
        base, generator, set_is_safe
    )
}

// called to run prop based tests to see if a ring implementation violates the base axioms
test_base_axioms :: proc(t: ^testing.T, generator : prop_based.Generator($T), base : Base(T))
{
    eq_reflexive_prop :: proc(base : Base(T), a : T) -> bool
    {
        return base.eq(a, a)
    }

    prop_based.check(
        t,
        base, generator, eq_reflexive_prop
    )

    eq_symetric_prop :: proc(base : Base(T), a : T, b : T) -> bool
    {
        if base.eq(a, b) { return base.eq(b, a) }
        else { return !base.eq(b, a) }
    }

    prop_based.check(
        t,
        base, generator, generator, eq_symetric_prop
    )

    // note this equivilence properties can be hard to check
    // since you need to generate alot of values to find 3 that happen to be equal
    eq_transitive_prop :: proc(base : Base(T), a : T, b : T, c : T) -> bool
    {
        if base.eq(a, b) && base.eq(b, c) { return base.eq(a, c) }
        else { return true }
    }

    prop_based.check(
        t,
        base, generator, generator, generator, eq_transitive_prop
    )

    eq_after_set_prop :: proc(base : Base(T), a : T, b : T) -> bool
    {
        tmp : T
        defer base.delete(tmp)
        base.set(&tmp, a)
        base.set(&tmp, b)
        return base.eq(tmp, b)
    }

    prop_based.check(
        t,
        base, generator, generator, eq_after_set_prop
    )
}
