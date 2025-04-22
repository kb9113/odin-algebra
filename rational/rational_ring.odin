package rational
import "../algebraic_structures/euclidean_ring"
import "../algebraic_structures/field"
import "../algebraic_structures/base"
import "../algebraic_structures/ring"
import "core:log"
import "core:mem"
import "core:strings"
import "core:fmt"
import "base:intrinsics"

/*
This file contains the implementation of the ring algebraic structure for rationals
*/

// makes an ring structure for a rational given the numerator/denominator ring structure.
make_rational_ring :: proc($T : typeid, coeffiencet_structure : $ST) -> ring.Ring(Rational(T, ST))
    where intrinsics.type_is_subtype_of(ST, ring.Ring(T))
{
    l_add :: proc(ans : ^Rational(T, ST), l : Rational(T, ST), r : Rational(T, ST))
    {
        add(ans, l, r)
    }

    l_sub :: proc(ans : ^Rational(T, ST), l : Rational(T, ST), r : Rational(T, ST))
    {
        sub(ans, l, r)
    }

    l_mul :: proc(ans : ^Rational(T, ST), l : Rational(T, ST), r : Rational(T, ST))
    {
        mul(ans, l, r)
    }

    l_neg :: proc(ans : ^Rational(T, ST), l : Rational(T, ST))
    {
        neg(ans, l)
    }

    return ring.Ring(Rational(T, ST)){
        make_rational_base(T, coeffiencet_structure),
        l_add,
        l_sub,
        l_mul,
        l_neg,
        add_ident(T, coeffiencet_structure),
        mul_ident(T, coeffiencet_structure)
    },
}

delete_rational_ring :: proc(r : ring.Ring(Rational($T, $ST)))
{
    delete_rational(r.add_identity)
    delete_rational(r.mul_identity)
}

make_rational_commutative_ring :: proc($T : typeid, coeffiencet_structure : $ST) -> ring.CommutativeRing(Rational(T, ST))
    where intrinsics.type_is_subtype_of(ST, euclidean_ring.EuclideanRing(T))
{
    return ring.CommutativeRing(Rational(T, ST)){
        make_rational_ring(T, coeffiencet_structure)
    },
}

delete_rational_commutative_ring :: proc(cr : ring.CommutativeRing(Rational($T, $ST)))
{
    delete_rational_ring(cr.ring)
}

add :: proc{
    add_ring,
    add_numeric,
}

add_ring :: proc(ans : ^Rational($T, $ST), l : Rational(T, ST), r : Rational(T, ST))
    where intrinsics.type_is_subtype_of(ST, ring.Ring(T))
{
    using l.algebraic_structure
    ans.algebraic_structure = l.algebraic_structure

    tmp_var : T

    // calc numerator
    mul(&tmp_var, l.numerator, r.denominator)
    mul(&ans.numerator, r.numerator, l.denominator)
    add(&ans.numerator, ans.numerator, tmp_var)

    // calc denominator
    mul(&ans.denominator, l.denominator, r.denominator)

    delete(tmp_var)

    simplify(ans)
}

add_numeric :: proc(ans : ^Rational($T, $ST), l : Rational(T, ST), r : Rational(T, ST))
    where ST == field.NumericField(T) || ST == euclidean_ring.NumericEuclideanRing(T)
{
    ans.algebraic_structure = l.algebraic_structure
    ans.numerator = l.numerator * r.denominator + r.numerator * l.denominator
    ans.denominator = l.denominator * r.denominator
    simplify(ans)
}

sub :: proc{
    sub_ring,
    sub_numeric,
}

sub_ring :: proc(ans : ^Rational($T, $ST), l : Rational(T, ST), r : Rational(T, ST))
    where intrinsics.type_is_subtype_of(ST, ring.Ring(T))
{
    using l.algebraic_structure
    ans.algebraic_structure = l.algebraic_structure

    tmp_var : T

    // calc numerator
    mul(&tmp_var, l.numerator, r.denominator)
    mul(&ans.numerator, r.numerator, l.denominator)
    sub(&ans.numerator, tmp_var, ans.numerator)

    // calc denominator
    mul(&ans.denominator, l.denominator, r.denominator)

    delete(tmp_var)

    simplify(ans)
}

sub_numeric :: proc(ans : ^Rational($T, $ST), l : Rational(T, ST), r : Rational(T, ST))
    where ST == field.NumericField(T) || ST == euclidean_ring.NumericEuclideanRing(T)
{
    ans.algebraic_structure = l.algebraic_structure
    ans.numerator = l.numerator * r.denominator - r.numerator * l.denominator
    ans.denominator = l.denominator * r.denominator
    simplify(ans)
}

mul :: proc{
    mul_ring,
    mul_numeric,
}

mul_ring :: proc(ans : ^Rational($T, $ST), l : Rational(T, ST), r : Rational(T, ST))
    where intrinsics.type_is_subtype_of(ST, ring.Ring(T))
{
    using l.algebraic_structure
    ans.algebraic_structure = l.algebraic_structure

    mul(&ans.numerator, l.numerator, r.numerator)
    mul(&ans.denominator, l.denominator, r.denominator)

    simplify(ans)
}

mul_numeric :: proc(ans : ^Rational($T, $ST), l : Rational(T, ST), r : Rational(T, ST))
    where ST == field.NumericField(T) || ST == euclidean_ring.NumericEuclideanRing(T)
{
    ans.algebraic_structure = l.algebraic_structure
    ans.numerator = l.numerator * r.numerator
    ans.denominator = l.denominator * r.denominator
    simplify(ans)
}

neg :: proc{
    neg_ring,
    neg_numeric,
}

neg_ring :: proc(ans : ^Rational($T, $ST), l : Rational(T, ST))
    where intrinsics.type_is_subtype_of(ST, ring.Ring(T))
{
    using l.algebraic_structure
    ans.algebraic_structure = l.algebraic_structure

    neg(&ans.numerator, l.numerator)
    set(&ans.denominator, l.denominator)

    simplify(ans)
}

neg_numeric :: proc(ans : ^Rational($T, $ST), l : Rational(T, ST))
    where ST == field.NumericField(T) || ST == euclidean_ring.NumericEuclideanRing(T)
{
    ans.algebraic_structure = l.algebraic_structure
    ans.numerator = -l.numerator
    ans.denominator = l.denominator
    simplify(ans)
}

add_ident :: proc{
    add_ident_ring,
    add_ident_numeric,
}

add_ident_ring :: proc($T : typeid, algebraic_structure : $ST) -> Rational(T, ST)
    where intrinsics.type_is_subtype_of(ST, ring.Ring(T))
{
    using algebraic_structure
    ans : Rational(T, ST)
    set(&ans.numerator, add_identity)
    set(&ans.denominator, mul_identity)
    ans.algebraic_structure = algebraic_structure

    return ans
}

add_ident_numeric :: proc($T : typeid, algebraic_structure : $ST) -> Rational(T, ST)
    where ST == field.NumericField(T) || ST == euclidean_ring.NumericEuclideanRing(T)
{
    ans : Rational(T, ST)
    ans.numerator = 0
    ans.denominator = 1
    ans.algebraic_structure = algebraic_structure

    return ans
}

mul_ident :: proc{
    mul_ident_ring,
    mul_ident_numeric,
}

mul_ident_ring :: proc($T : typeid, algebraic_structure : $ST) -> Rational(T, ST)
    where intrinsics.type_is_subtype_of(ST, ring.Ring(T))
{
    using algebraic_structure
    ans : Rational(T, ST)
    set(&ans.numerator, mul_identity)
    set(&ans.denominator, mul_identity)
    ans.algebraic_structure = algebraic_structure

    return ans
}

mul_ident_numeric :: proc($T : typeid, algebraic_structure : $ST) -> Rational(T, ST)
    where ST == field.NumericField(T) || ST == euclidean_ring.NumericEuclideanRing(T)
{
    ans : Rational(T, ST)
    ans.numerator = 1
    ans.denominator = 1
    ans.algebraic_structure = algebraic_structure

    return ans
}
