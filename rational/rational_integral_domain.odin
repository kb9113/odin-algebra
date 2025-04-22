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
This file contains the implementation of the integral domain algebraic structure for rationals
*/

// makes an integral domain structure for a rational given the numerator/denominator commutative ring structure.
make_rational_integral_domain :: proc($T : typeid, coeffiencet_structure : $ST) -> integral_domain.IntegralDomain(Rational(T, ST))
    where intrinsics.type_is_subtype_of(ST, ring.CommutativeRing(T))
{
    l_cancel :: proc(ans : ^Rational(T, ST), l : Rational(T, ST), r : Rational(T, ST))
    {
        div(ans, l, r)
    }

    return integral_domain.IntegralDomain(Rational(T, ST)){
        make_rational_commutative_ring(T, coeffiencet_structure),
        l_cancel
    },
}

delete_rational_integral_domain :: proc(id : integral_domain.IntegralDomain(Rational($T, $ST)))
{
    delete_rational_commutative_ring(id.commutative_ring)
}
