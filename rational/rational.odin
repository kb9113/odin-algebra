// Implementation of the rational field over some underling ring.
package rational
import "../algebraic_structures/euclidean_ring"
import "../algebraic_structures/field"
import "../algebraic_structures/ring"
import "core:log"
import "core:mem"
import "core:strings"
import "core:fmt"
import "base:intrinsics"

/*
This structure represents a rational field over some underling ring.

Inputs:
- $T: the type of the numerator/denominator
- $ST: the type of the algebraic structure used to operate on the numerator/denominator

Example:
	Rational(i64, ring.Ring(i64))
*/
Rational :: struct($T : typeid, $ST : typeid)
{
    numerator : T,
    denominator : T,
    algebraic_structure : ST
}

// used to make a rational from a numerator and denominator
// does not clone the numerator and denominator
make_rational :: proc(
    numerator : $T, denominator : T,
    algebraic_structure : $ST
) -> Rational(T, ST)
{
    ans := Rational(T, ST){
        numerator,
        denominator,
        algebraic_structure
    }
    simplify(&ans)
    return ans
}

// if the underling structure is a euclidean ring simplifies the fraction by computing the gcd and
// dividing both numerator and denominator.
simplify :: proc(r : ^Rational($T, $ST))
{
    when intrinsics.type_is_subtype_of(ST, euclidean_ring.EuclideanRing(T))
    {
        using r.algebraic_structure
        gcd := euclidean_ring.gcd(r.numerator, r.denominator, r.algebraic_structure)

        cancel(&r.numerator, r.numerator, gcd)
        cancel(&r.denominator, r.denominator, gcd)
        delete(gcd)
    }
    else when intrinsics.type_is_subtype_of(ST, ring.Ring(T))
    {
        if r.algebraic_structure.eq(r.algebraic_structure.add_identity, r.numerator)
        {
            r.algebraic_structure.set(&r.denominator, r.algebraic_structure.mul_identity)
        }
    }
    else when ST == euclidean_ring.NumericEuclideanRing(T)
    {
        gcd := euclidean_ring.gcd(r.numerator, r.denominator, r.algebraic_structure)
        r.numerator = r.numerator / gcd
        r.denominator = r.denominator / gcd
    }
}
