package polynomial
import "core:math"
import "core:math/cmplx"
import "core:slice"
import "base:intrinsics"
import "core:log"
import "core:mem"
import "core:strings"
import "../algebraic_structures/ring"
import "../algebraic_structures/field"
import "../algebraic_structures/euclidean_ring"
import "../algebraic_structures/integral_domain"

/*
This file contains the implementation of the euclidean ring algebraic structure for polynomials
*/

// makes an euclidean ring structure for a polynomial given the coefficents field structure
// note: to perform euclidean divison on a polynomial a multiplicative inverse must exist for the coefficents
// since divison must be performed on the coefficents
make_polynomial_euclidean_ring :: proc($T : typeid, coefficent_structure : $ST) ->
    euclidean_ring.EuclideanRing(Polynomial(T, ST))
    where intrinsics.type_is_subtype_of(ST, field.Field(T))
{
    l_div :: proc(quot : ^Polynomial(T, ST), rem : ^Polynomial(T, ST), l : Polynomial(T, ST), r : Polynomial(T, ST))
    {
        div(quot, rem, l, r)
    }

    l_norm :: proc(p : Polynomial(T, ST)) -> u64
    {
        if degree(p) == -1 { return 0 }
        else { return u64(degree(p)) }
    }

    return euclidean_ring.EuclideanRing(Polynomial(T, ST)){
        make_polynomial_integral_domain(T, coefficent_structure),
        l_div,
        l_norm
    }
}

delete_polynomial_euclidean_ring :: proc(v : euclidean_ring.EuclideanRing(Polynomial($T, $ST)))
{
    delete_polynomial_integral_domain(v.integral_domain)
}

// performs euclidean divison on a polynomial such that l = quot * r + rem
div :: proc{
    div_field,
    div_numeric,
}

div_field :: proc(
    quot : ^Polynomial($T, $ST), rem : ^Polynomial(T, ST),
    l : Polynomial(T, ST), r : Polynomial(T, ST)
)
    where intrinsics.type_is_subtype_of(ST, field.Field(T))
{
    assert(is_valid(quot^))
    assert(is_valid(rem^))
    assert(is_valid(l))
    assert(is_valid(r))

    deg_l := degree(l)
    deg_r := degree(r)

    if deg_l < deg_r
    {
        // l = 0 * r + l
        resize_or_init_polynomial(quot, l.algebraic_structure, -1)
        set(rem, l)
        return
    }

    curr_remainder : Polynomial(T, ST)
    set(&curr_remainder, l)
    curr_quotent := make_uninitialized(T, l.algebraic_structure, deg_l - deg_r)

    for i in 0..<(deg_l - deg_r + 1)
    {
        // determine the next coeficent in the quotent
        l.algebraic_structure.div(
            &curr_quotent.coefficents[deg_l - deg_r - i],
            curr_remainder.coefficents[deg_l - i],
            r.coefficents[deg_r]
        )

        // now we update the reaminder string
        // compute the non leading coeficents we use curr_remainder.coefficents[deg_l - i]
        // as a temporary register
        // we don't need it any more since after the divison we know it should be 0
        for j in 1..=deg_r
        {
            l.algebraic_structure.mul(
                &curr_remainder.coefficents[deg_l - i],
                curr_quotent.coefficents[deg_l - deg_r - i],
                r.coefficents[deg_r - j]
            )
            l.algebraic_structure.sub(
                &curr_remainder.coefficents[deg_l - j - i],
                curr_remainder.coefficents[deg_l - j - i],
                curr_remainder.coefficents[deg_l - i]
            )
        }
        // set the coeficent we just finished dividing to 0
        l.algebraic_structure.set(
            &curr_remainder.coefficents[deg_l - i],
            l.algebraic_structure.add_identity
        )
    }
    shrink_to_valid(&curr_quotent)
    shrink_to_valid(&curr_remainder)
    set(quot, curr_quotent)
    set(rem, curr_remainder)
    delete_polynomial(curr_quotent)
    delete_polynomial(curr_remainder)
}

div_numeric :: proc(
    quot : ^Polynomial($T, $ST), rem : ^Polynomial(T, ST),
    l : Polynomial(T, ST), r : Polynomial(T, ST)
)
    where ST == field.NumericField(T)
{
    assert(is_valid(quot^))
    assert(is_valid(rem^))
    assert(is_valid(l))
    assert(is_valid(r))

    deg_l := degree(l)
    deg_r := degree(r)

    if deg_l < deg_r
    {
        // l = 0 * r + l
        resize_or_init_polynomial(quot, l.algebraic_structure, -1)
        set(rem, l)
        return
    }

    curr_remainder : Polynomial(T, ST)
    set(&curr_remainder, l)
    curr_quotent := make_uninitialized(T, l.algebraic_structure, deg_l - deg_r)

    for i in 0..<(deg_l - deg_r + 1)
    {
        // determine the next coeficent in the quotent
        curr_quotent.coefficents[deg_l - deg_r - i] =
            curr_remainder.coefficents[deg_l - i] / r.coefficents[deg_r]

        curr_remainder.coefficents[deg_l - i] = 0
        for j in 1..=deg_r
        {
            curr_remainder.coefficents[deg_l - j - i] -=
                curr_quotent.coefficents[deg_l - deg_r - i] * r.coefficents[deg_r - j]
        }
    }

    shrink_to_valid(&curr_quotent)
    shrink_to_valid(&curr_remainder)
    set(quot, curr_quotent)
    set(rem, curr_remainder)
    delete_polynomial(curr_quotent)
    delete_polynomial(curr_remainder)
}

// a special kind of divison for when it can be assumed that all division operations on the coefiencet integral domain are perfect
cancel_div :: proc{
    cancel_div_field,
    cancel_div_numeric,
}

cancel_div_field :: proc(
    quot : ^Polynomial($T, $ST), rem : ^Polynomial(T, ST),
    l : Polynomial(T, ST), r : Polynomial(T, ST),
    allocator : mem.Allocator
)
    where intrinsics.type_is_subtype_of(ST, integral_domain.IntegralDomain(T))
{
    assert(is_valid(quot^))
    assert(is_valid(rem^))
    assert(is_valid(l))
    assert(is_valid(r))

    deg_l := degree(l)
    deg_r := degree(r)

    if deg_l < deg_r
    {
        // l = 0 * r + l
        resize_or_init_polynomial(quot, l.algebraic_structure, -1)
        set(rem, l)
        return
    }

    curr_remainder : Polynomial(T, ST)
    set(&curr_remainder, l)
    curr_quotent := make_uninitialized(T, l.algebraic_structure, deg_l - deg_r)

    for i in 0..<(deg_l - deg_r + 1)
    {
        // determine the next coeficent in the quotent
        l.algebraic_structure.cancel(
            &curr_quotent.coefficents[deg_l - deg_r - i],
            curr_remainder.coefficents[deg_l - i],
            r.coefficents[deg_r]
        )

        // now we update the reaminder string
        // compute the non leading coeficents we use curr_remainder.coefficents[deg_l - i]
        // as a temporary register
        // we don't need it any more since after the divison we know it should be 0
        for j in 1..=deg_r
        {
            l.algebraic_structure.mul(
                &curr_remainder.coefficents[deg_l - i],
                curr_quotent.coefficents[deg_l - deg_r - i],
                r.coefficents[deg_r - j]
            )
            l.algebraic_structure.sub(
                &curr_remainder.coefficents[deg_l - j - i],
                curr_remainder.coefficents[deg_l - j - i],
                curr_remainder.coefficents[deg_l - i]
            )
        }
        // set the coeficent we just finished dividing to 0
        l.algebraic_structure.set(
            &curr_remainder.coefficents[deg_l - i],
            l.algebraic_structure.add_identity
        )
    }
    shrink_to_valid(&curr_quotent)
    shrink_to_valid(&curr_remainder)
    set(quot, curr_quotent)
    set(rem, curr_remainder)
    delete_polynomial(curr_quotent)
    delete_polynomial(curr_remainder)
}

cancel_div_numeric :: proc(
    quot : ^Polynomial($T, $ST), rem : ^Polynomial(T, ST),
    l : Polynomial(T, ST), r : Polynomial(T, ST),
    allocator : mem.Allocator
)
    where ST == euclidean_ring.NumericEuclideanRing(T)
{
    assert(is_valid(quot^))
    assert(is_valid(rem^))
    assert(is_valid(l))
    assert(is_valid(r))

    deg_l := degree(l)
    deg_r := degree(r)

    if deg_l < deg_r
    {
        // l = 0 * r + l
        resize_or_init_polynomial(quot, l.algebraic_structure, -1, allocator)
        set(rem, l, allocator)
        return
    }

    curr_remainder : Polynomial(T, ST)
    set(&curr_remainder, l)
    curr_quotent := make_uninitialized(T, l.algebraic_structure, deg_l - deg_r)

    for i in 0..<(deg_l - deg_r + 1)
    {
        // determine the next coeficent in the quotent
        curr_quotent.coefficents[deg_l - deg_r - i] =
            curr_remainder.coefficents[deg_l - i] / r.coefficents[deg_r]

        curr_remainder.coefficents[deg_l - i] = 0
        for j in 1..=deg_r
        {
            curr_remainder.coefficents[deg_l - j - i] -=
                curr_quotent.coefficents[deg_l - deg_r - i] * r.coefficents[deg_r - j]
        }
    }

    shrink_to_valid(&curr_quotent)
    shrink_to_valid(&curr_remainder)
    set(quot, curr_quotent, allocator)
    set(rem, curr_remainder, allocator)
    delete_polynomial(curr_quotent)
    delete_polynomial(curr_remainder)
}
