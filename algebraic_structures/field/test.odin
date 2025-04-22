package field

import "core:testing"
import "core:log"
import "../../prop_based"
import "../euclidean_ring"
import "../base"

// called to run prop based tests to see if a ring implementation violates the field axioms
test_field_axioms :: proc(t: ^testing.T, generator : prop_based.Generator($T), f : Field(T))
{
    euclidean_ring.test_euclidean_ring_axioms(t, generator, f.euclidean_ring)

    mul_inverse_axiom :: proc(f : Field(T), a : T) -> bool
    {
        if f.eq(a, f.add_identity)
        {
            return true
        }

        inv_a : T
        defer f.delete(inv_a)
        ans : T
        defer f.delete(ans)
        f.mul_inverse(&inv_a, a)
        f.mul(&ans, a, inv_a)

        return f.eq(ans, f.mul_identity)
    }

    prop_based.check(
        t,
        f, generator, mul_inverse_axiom
    )

    sub_is_mul_inverse :: proc(f : Field(T), a : T, b : T) -> bool
    {
        if f.eq(b, f.add_identity)
        {
            return true
        }

        ans1 : T
        defer f.delete(ans1)
        f.div(&ans1, a, b)

        inv_b : T
        defer f.delete(inv_b)
        ans2 : T
        defer f.delete(ans2)
        f.mul_inverse(&inv_b, b)
        f.mul(&ans2, a, inv_b)

        base.log_base_object(f.base, "a / b =", ans1)
        base.log_base_object(f.base, "a * (1 / b)", ans2)

        return f.eq(ans1, ans2)
    }

    prop_based.check(
        t,
        f, generator, generator, sub_is_mul_inverse
    )
}
