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
This file contains the implementation of the integral domain algebraic structure for polynomials
*/

// makes an integral domain structure for a polynomial given the coefficients integral domain structure
make_polynomial_integral_domain :: proc($T : typeid, coefficient_structure : $ST) ->
    integral_domain.IntegralDomain(Polynomial(T, ST)) where intrinsics.type_is_subtype_of(ST, integral_domain.IntegralDomain(T))
{
    l_cancel :: proc(ans : ^Polynomial(T, ST), l : Polynomial(T, ST), r : Polynomial(T, ST))
    {
        cancel(ans, l, r)
    }

    return integral_domain.IntegralDomain(Polynomial(T, ST)){
        make_polynomial_commutative_ring(T, coefficient_structure),
        l_cancel
    }
}

delete_polynomial_integral_domain :: proc(v : integral_domain.IntegralDomain(Polynomial($T, $ST)))
{
    delete_polynomial_commutative_ring(v.commutative_ring)
}

// sets ans equal to p canceled by q ie if p = a * q then cancel(p, q) == a
// this procedure panics if q does not divide p ie if p is not a multiple of q
cancel :: proc(ans : ^Polynomial($T, $ST), p : Polynomial(T, ST), q : Polynomial(T, ST))
{
    assert(is_valid(ans^))
    assert(is_valid(p))
    assert(is_valid(q))

    deg_ans := degree(ans^)
    deg_p := degree(p)
    deg_q := degree(q)

    assert(degree(q) != -1) // we cannot cancel by 0

    if degree(p) == -1
    {
        // in this case clearly ans = 0
        resize_or_init_polynomial(ans, p.algebraic_structure, -1)
        return
    }

    assert(deg_p >= deg_q)

    if rawptr(raw_data(p.coefficients)) == rawptr(raw_data(q.coefficients))
    {
        // if p == q clearly p / q == 1
        resize_or_init_polynomial(ans, p.algebraic_structure, 0)
        p.algebraic_structure.set(&ans.coefficients[0], p.algebraic_structure.mul_identity)
        return
    }

    divisor : Polynomial(T, ST)
    ans_eq_q := rawptr(raw_data(ans.coefficients)) == rawptr(raw_data(q.coefficients))
    if ans_eq_q
    {
        // in the case where ans and q are the same pointer we unfortunetly need to copy q
        set(&divisor, q)
    }
    else
    {
        divisor = q
    }

    curr_remainder : Polynomial(T, ST)
    set(&curr_remainder, p)

    resize_or_init_polynomial(ans, p.algebraic_structure, deg_p - deg_q)

    for i in 0..<(deg_p - deg_q + 1)
    {
        p.algebraic_structure.cancel(
            &ans.coefficients[deg_p - deg_q - i],
            curr_remainder.coefficients[deg_p - i],
            divisor.coefficients[deg_q]
        )

        for j in 1..=deg_q
        {
            p.algebraic_structure.mul(
                &curr_remainder.coefficients[deg_p - i],
                ans.coefficients[deg_p - deg_q - i],
                divisor.coefficients[deg_q - j]
            )
            p.algebraic_structure.sub(
                &curr_remainder.coefficients[deg_p - j - i],
                curr_remainder.coefficients[deg_p - j - i],
                curr_remainder.coefficients[deg_p - i]
            )
        }

        p.algebraic_structure.set(
            &curr_remainder.coefficients[deg_p - i],
            p.algebraic_structure.add_identity
        )
    }

    shrink_to_valid(ans)
    shrink_to_valid(&curr_remainder)
    assert(degree(curr_remainder) == -1) // cancelation should give no remainder
    delete_polynomial(curr_remainder)
    if ans_eq_q
    {
        delete_polynomial(divisor)
    }
}
