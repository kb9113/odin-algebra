package rational
import "../algebraic_structures/euclidean_ring"
import "../algebraic_structures/field"
import "../algebraic_structures/base"
import "../algebraic_structures/ring"
import "../algebraic_structures/integral_domain"
import "core:log"
import "core:mem"
import "core:strings"
import "core:fmt"
import "base:intrinsics"
/*
This file contains the implementation of the euclidean ring algebraic structure for rationals
*/

// makes an euclidean ring structure for a rational given the numerator/denominator commutative ring structure.
make_rational_euclidean_ring :: proc($T : typeid, coeffiencet_structure : $ST) -> euclidean_ring.EuclideanRing(Rational(T, ST))
    where intrinsics.type_is_subtype_of(ST, ring.CommutativeRing(T))
{
    l_euclidean_div :: proc(quot : ^Rational(T, ST), rem : ^Rational(T, ST), l : Rational(T, ST), r : Rational(T, ST))
    {
        div(quot, l, r)
        rem.algebraic_structure = l.algebraic_structure
        l.algebraic_structure.set(&rem.numerator, l.algebraic_structure.add_identity)
        l.algebraic_structure.set(&rem.denominator, l.algebraic_structure.mul_identity)
    }

    l_norm :: proc(l : Rational(T, ST)) -> u64
    {
        using l.algebraic_structure
        if eq(l.numerator, l.algebraic_structure.add_identity)
        {
            return 0
        }
        else
        {
            return 1
        }
    }

    return euclidean_ring.EuclideanRing(Rational(T, ST)){
        make_rational_integral_domain(T, coeffiencet_structure),
        l_euclidean_div,
        l_norm
    },
}

delete_rational_euclidean_ring :: proc(er : euclidean_ring.EuclideanRing(Rational($T, $ST)))
{
    delete_rational_integral_domain(er.integral_domain)
}
