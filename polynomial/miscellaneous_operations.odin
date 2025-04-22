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

// multiplies each coefficent in l by s and writes the answer to ans
s_mul :: proc(ans : ^Polynomial($T, $ST), l : Polynomial(T, ST), s : T)
{
    // we assume for now that s is not an element in the polynomial l
    using l.algebraic_structure

    deg_ans := degree(ans^)
    deg_l := degree(l)

    resize_or_init_polynomial(ans, l.algebraic_structure, deg_l)
    for i in (deg_ans + 1)..=deg_l
    {
        set(&ans.coefficents[i], add_identity)
    }
    for i in 0..=deg_l
    {
        mul(&ans.coefficents[i], l.coefficents[i], s)
    }
    shrink_to_valid(ans)
}

// cancels each coefficent in l by s and writes the answer to ans
s_cancel :: proc(ans : ^Polynomial($T, $ST), l : Polynomial(T, ST), s : T) where
    ST == integral_domain.IntegralDomain(T) || ST == euclidean_ring.EuclideanRing(T) || ST == field.Field(T)
{
    // we assume for now that s is not an element in the polynomial l
    using l.algebraic_structure
    deg_ans := degree(ans^)
    deg_l := degree(l)

    resize_or_init_polynomial(ans, l.algebraic_structure, deg_l)
    for i in (deg_ans + 1)..=deg_l
    {
        set(&ans.coefficents[i], add_identity)
    }
    for i in 0..=deg_l
    {
        cancel(&ans.coefficents[i], l.coefficents[i], s)
    }
    shrink_to_valid(ans)
}
