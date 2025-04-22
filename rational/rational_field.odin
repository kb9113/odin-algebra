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
This file contains the implementation of the field algebraic structure for rationals
*/

// makes an field structure for a rational given the numerator/denominator commutative ring structure.
make_rational_field :: proc($T : typeid, coeffiencet_structure : $ST) -> field.Field(Rational(T, ST))
    where intrinsics.type_is_subtype_of(ST, ring.CommutativeRing(T))
{
    l_div :: proc(ans : ^Rational(T, ST), l : Rational(T, ST), r : Rational(T, ST))
    {
        div(ans, l, r)
    }

    l_mul_inverse :: proc(ans : ^Rational(T, ST), l : Rational(T, ST))
    {
        mul_inverse(ans, l)
    }

    return field.Field(Rational(T, ST)){
        make_rational_euclidean_ring(T, coeffiencet_structure),
        l_div,
        l_mul_inverse
    },
}

delete_rational_field :: proc(f : field.Field(Rational($T, $ST)))
{
    delete_rational_euclidean_ring(f.euclidean_ring)
}

mul_inverse :: proc(ans : ^Rational($T, $ST), l : Rational(T, ST))
{
    using l.algebraic_structure
    ans.algebraic_structure = l.algebraic_structure

    tmp_var : T
    defer delete(tmp_var)
    set(&tmp_var, l.numerator)
    set(&ans.numerator, l.denominator)
    set(&ans.denominator, tmp_var)

    simplify(ans)
}

div :: proc{
    div_ring,
    div_numeric,
}

div_ring :: proc(ans : ^Rational($T, $ST), l : Rational(T, ST), r : Rational(T, ST))
    where intrinsics.type_is_subtype_of(ST, ring.CommutativeRing(T))
{
    using l.algebraic_structure
    ans.algebraic_structure = l.algebraic_structure

    tmp_var : T
    defer delete(tmp_var)
    mul(&tmp_var, l.numerator, r.denominator)
    mul(&ans.denominator, l.denominator, r.numerator)
    set(&ans.numerator, tmp_var)

    simplify(ans)
}

div_numeric :: proc(ans : ^Rational($T, $ST), l : Rational(T, ST), r : Rational(T, ST))
    where ST == field.NumericField(T) || ST == euclidean_ring.NumericEuclideanRing(T)
{
    ans.algebraic_structure = l.algebraic_structure

    tmp_var = l.numerator * r.denominator
    ans.denominator = l.denominator * r.numerator
    ans.numerator = tmp_var

    simplify(ans)
}
