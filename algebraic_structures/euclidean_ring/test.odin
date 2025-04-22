package euclidean_ring

import "core:testing"
import "core:log"
import "../../prop_based"
import "../integral_domain"

// called to run prop based tests to see if a ring implementation violates the euclidean ring axioms
test_euclidean_ring_axioms :: proc(t: ^testing.T, generator : prop_based.Generator($T), er : EuclideanRing(T))
{
    integral_domain.test_integral_domain_axioms(t, generator, er.integral_domain)

    eucliden_function_axiom :: proc(er : EuclideanRing(T), a : T, b : T) -> bool
    {
        if er.eq(b, er.add_identity)
        {
            return true
        }

        q : T
        defer er.delete(q)
        r : T
        defer er.delete(r)

        er.euclidean_div(&q, &r, a, b)

        bq : T
        defer er.delete(bq)
        bq_plus_r : T
        defer er.delete(bq_plus_r)
        er.mul(&bq, b, q)
        er.add(&bq_plus_r, bq, r)

        return er.eq(a, bq_plus_r) && (er.eq(r, er.add_identity) || er.norm(r) < er.norm(b))
    }

    prop_based.check(
        t,
        er, generator, generator, eucliden_function_axiom
    )
}
