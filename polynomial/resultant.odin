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

// computes the resultant of 2 polynomials
resultant :: proc(p : Polynomial($T, $ST), q : Polynomial(T, ST)) -> T
{
    it : SubResultantPseudoRemainderIterator(T, ST)
    if degree(p) >= degree(q)
    {
        it = make_sub_resultant_pseudo_remainder_iterator(p, q)
    }
    else
    {
        it = make_sub_resultant_pseudo_remainder_iterator(q, p)
    }

    ans : T
    for
    {
        sr := next_sub_resultant(&it)

        if degree(sr) == 0
        {
            p.algebraic_structure.set(&ans, sr.coefficients[degree(sr)])
            break
        }
        if degree(sr) == -1
        {
            p.algebraic_structure.set(&ans, p.algebraic_structure.add_identity)
            break
        }
    }
    delete_sub_resultant_pseudo_remainder_iterator(it)
    return ans
}

// iterator data structure for generating the sub resultant sequence made with make_sub_resultant_pseudo_remainder_iterator
SubResultantPseudoRemainderIterator :: struct($T : typeid, $ST : typeid)
{
    r_0 : Polynomial(T, ST),
    r_1 : Polynomial(T, ST),
    d_0 : int,
    d_1 : int,
    b : T,
    w : T
}

// makes a sub resultant sequence itterator that can be itterated through with next_sub_resultant to obtain the sub resultant chain
make_sub_resultant_pseudo_remainder_iterator :: proc(p : Polynomial($T, $ST), q : Polynomial(T, ST)) ->
    SubResultantPseudoRemainderIterator(T, ST)
{
    ans := SubResultantPseudoRemainderIterator(T, ST){}
    set(&ans.r_0, p)
    set(&ans.r_1, q)
    p.algebraic_structure.set(&ans.b, p.algebraic_structure.add_identity)
    p.algebraic_structure.set(&ans.w, p.algebraic_structure.add_identity)
    ans.d_0 = 0
    ans.d_1 = 0

    return ans
}

delete_sub_resultant_pseudo_remainder_iterator :: proc(it : SubResultantPseudoRemainderIterator($T, $ST))
{
    it.r_0.algebraic_structure.delete(it.b)
    it.r_0.algebraic_structure.delete(it.w)
    delete_polynomial(it.r_0)
    delete_polynomial(it.r_1)
}

// given an iterator returns the next sub resultant in the chain moving the iterator forwards
// when there are no more sub resultants in the chain this returns 0
next_sub_resultant :: proc(it : ^SubResultantPseudoRemainderIterator($T, $ST)) -> Polynomial(T, ST)
{
    assert(degree(it.r_0) >= degree(it.r_1))
    assert(degree(it.r_1) != -1)
    it.d_0 = it.d_1
    it.d_1 = degree(it.r_0) - degree(it.r_1)
    if it.r_0.algebraic_structure.eq(it.b, it.r_0.algebraic_structure.add_identity)
    {
        it.r_0.algebraic_structure.set(&it.b, it.r_0.algebraic_structure.mul_identity)
        if (it.d_1 + 1) % 2 == 1
        {
            it.r_0.algebraic_structure.neg(&it.b, it.b)
        }
        it.r_0.algebraic_structure.neg(&it.w, it.r_0.algebraic_structure.mul_identity)
    }
    else
    {
        tmp_var : T

        // compute w_i
        it.r_0.algebraic_structure.set(&tmp_var, it.r_0.coefficients[degree(it.r_0)])
        it.r_0.algebraic_structure.neg(&tmp_var, tmp_var)
        ring.integer_pow(&tmp_var, tmp_var, uint(it.d_0), it.r_0.algebraic_structure)

        ring.integer_pow(&it.w, it.w, uint(it.d_0 - 1), it.r_0.algebraic_structure)
        it.r_0.algebraic_structure.cancel(&it.w, tmp_var, it.w)

        // compute b_i
        it.r_0.algebraic_structure.set(&tmp_var, it.w)
        ring.integer_pow(&tmp_var, tmp_var, uint(it.d_1), it.r_0.algebraic_structure)

        it.r_0.algebraic_structure.set(&it.b, it.r_0.coefficients[degree(it.r_0)])
        it.r_0.algebraic_structure.neg(&it.b, it.b)

        it.r_0.algebraic_structure.mul(&it.b, it.b, tmp_var)

        it.r_0.algebraic_structure.delete(tmp_var)
    }

    lambda : T
    it.r_0.algebraic_structure.set(&lambda, it.r_1.coefficients[degree(it.r_1)])
    ring.integer_pow(&lambda, lambda, uint(it.d_1 + 1), it.r_0.algebraic_structure)
    s_mul(&it.r_0, it.r_0, lambda)
    it.r_0.algebraic_structure.delete(lambda)

    quotent, rem : Polynomial(T, ST)
    cancel_div(
        &quotent,
        &rem,
        it.r_0,
        it.r_1,
        context.allocator
    )
    delete_polynomial(quotent)

    s_cancel(&rem, rem, it.b)

    delete_polynomial(it.r_0)
    it.r_0 = it.r_1
    it.r_1 = rem
    return rem
}
