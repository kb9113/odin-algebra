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
This file contains the implementation of the ring algebraic structure for polynomials
*/

// makes an ring structure for a polynomial given the coefficients ring structure
make_polynomial_ring :: proc($T : typeid, coeffiencet_structure : $ST) ->
    ring.Ring(Polynomial(T, ST)) where intrinsics.type_is_subtype_of(ST, ring.Ring(T))
{
    l_add :: proc(ans : ^Polynomial(T, ST), l : Polynomial(T, ST), r : Polynomial(T, ST))
    {
        add(ans, l, r)
    }

    l_sub :: proc(ans : ^Polynomial(T, ST), l : Polynomial(T, ST), r : Polynomial(T, ST))
    {
        sub(ans, l, r)
    }

    l_mul :: proc(ans : ^Polynomial(T, ST), l : Polynomial(T, ST), r : Polynomial(T, ST))
    {
        mul(ans, l, r)
    }

    l_neg :: proc(ans : ^Polynomial(T, ST), l : Polynomial(T, ST))
    {
        neg(ans, l)
    }

    return ring.Ring(Polynomial(T, ST)){
        make_polynomial_base(T, coeffiencet_structure),
        l_add,
        l_sub,
        l_mul,
        l_neg,
        add_ident_polynomial(T, coeffiencet_structure),
        mul_ident_polynomial(T, coeffiencet_structure)
    }
}

delete_polynomial_ring :: proc(v : ring.Ring(Polynomial($T, $ST)))
{
    delete_polynomial(v.add_identity)
    delete_polynomial(v.mul_identity)
}

// makes an commutative ring structure for a polynomial given the coefficients commutative ring structure
make_polynomial_commutative_ring :: proc($T : typeid, coeffiencet_structure : $ST) ->
    ring.CommutativeRing(Polynomial(T, ST)) where intrinsics.type_is_subtype_of(ST, ring.CommutativeRing(T))
{
    return ring.CommutativeRing(Polynomial(T, ST)){
        make_polynomial_ring(T, coeffiencet_structure)
    }
}

delete_polynomial_commutative_ring :: proc(v : ring.CommutativeRing(Polynomial($T, $ST)))
{
    delete_polynomial_ring(v.ring)
}

// polynomial addition sets ans to l + r
add :: proc{
    add_ring,
    add_numeric,
}

add_ring :: proc(ans : ^Polynomial($T, $ST), l : Polynomial(T, ST), r : Polynomial(T, ST))
    where intrinsics.type_is_subtype_of(ST, ring.Ring(T))
{
    using ans.algebraic_structure
    assert(is_valid(ans^))
    assert(is_valid(l))
    assert(is_valid(r))

    deg_ans := degree(ans^)
    deg_l := degree(l)
    deg_r := degree(r)

    resize_or_init_polynomial(ans, l.algebraic_structure, max(deg_l, deg_r))

    for i in 0..=max(deg_l, deg_r)
    {
        if i <= deg_l && i <= deg_r
        {
            add(&ans.coefficients[i], l.coefficients[i], r.coefficients[i])
        }
        else if i <= deg_l
        {
            set(&ans.coefficients[i], l.coefficients[i])
        }
        else
        {
            set(&ans.coefficients[i], r.coefficients[i])
        }
    }
    shrink_to_valid(ans)
}

add_numeric :: proc(ans : ^Polynomial($T, $ST), l : Polynomial(T, ST), r : Polynomial(T, ST))
    where ST == field.NumericField(T) || ST == euclidean_ring.NumericEuclideanRing(T)
{
    assert(is_valid(ans^))
    assert(is_valid(l))
    assert(is_valid(r))

    deg_ans := degree(ans^)
    deg_l := degree(l)
    deg_r := degree(r)

    resize_or_init_polynomial(ans, l.algebraic_structure, max(deg_l, deg_r))

    for i in 0..=max(deg_l, deg_r)
    {
        if i <= deg_l && i <= deg_r
        {
            ans.coefficients[i] = l.coefficients[i] + r.coefficients[i]
        }
        else if i <= deg_l
        {
            ans.coefficients[i] = l.coefficients[i]
        }
        else
        {
            ans.coefficients[i] = r.coefficients[i]
        }
    }
    shrink_to_valid(ans)
}

// polynomial subtraction sets ans to l - r
sub :: proc{
    sub_ring,
    sub_numeric,
}

sub_ring :: proc(ans : ^Polynomial($T, $ST), l : Polynomial(T, ST), r : Polynomial(T, ST))
    where intrinsics.type_is_subtype_of(ST, ring.Ring(T))
{
    using ans.algebraic_structure
    assert(is_valid(ans^))
    assert(is_valid(l))
    assert(is_valid(r))

    deg_ans := degree(ans^)
    deg_l := degree(l)
    deg_r := degree(r)

    resize_or_init_polynomial(ans, l.algebraic_structure, max(deg_l, deg_r))

    for i in 0..=max(deg_l, deg_r)
    {
        if i <= deg_l && i <= deg_r
        {
            sub(&ans.coefficients[i], l.coefficients[i], r.coefficients[i])
        }
        else if i <= deg_l
        {
            set(&ans.coefficients[i], l.coefficients[i])
        }
        else
        {
            neg(&ans.coefficients[i], r.coefficients[i])
        }
    }
    shrink_to_valid(ans)
}

sub_numeric :: proc(ans : ^Polynomial($T, $ST), l : Polynomial(T, ST), r : Polynomial(T, ST))
    where ST == field.NumericField(T) || ST == euclidean_ring.NumericEuclideanRing(T)
{
    assert(is_valid(ans^))
    assert(is_valid(l))
    assert(is_valid(r))

    deg_ans := degree(ans^)
    deg_l := degree(l)
    deg_r := degree(r)

    resize_or_init_polynomial(ans, l.algebraic_structure, max(deg_l, deg_r))

    for i in 0..=max(deg_l, deg_r)
    {
        if i <= deg_l && i <= deg_r
        {
            ans.coefficients[i] = l.coefficients[i] - r.coefficients[i]
        }
        else if i <= deg_l
        {
            ans.coefficients[i] = l.coefficients[i]
        }
        else
        {
            ans.coefficients[i] = -r.coefficients[i]
        }
    }
    shrink_to_valid(ans)
}

// polynomial self multiplication sets ans to ans * ans
mul_self_ring :: proc(ans : ^Polynomial($T, $ST))
    where intrinsics.type_is_subtype_of(ST, ring.Ring(T))
{
    using ans.algebraic_structure

    deg_l := degree(ans^)
    deg_r := degree(ans^)

    resize_or_init_polynomial(ans, ans.algebraic_structure, deg_l + deg_r)

    temp_var : T

    for i := (deg_l + deg_r); i >= 0; i -= 1
    {
        j_min := max(0, i - deg_l)
        j_max := min(i, deg_r)
        for j in j_min..=j_max
        {
            // we need to do the one with the largest
            l_index := i - j
            r_index := j
            if j_min != j_max && j == j_max
            {
                // in the special case where the 2 polynomials are in the same memory
                // we skip the last multiplication since what we are multipling by has already been overwitten
                continue
            }

            mul(&temp_var, ans.coefficients[l_index], ans.coefficients[r_index])

            if j == j_min
            {
                // first itteration
                set(&ans.coefficients[i], temp_var)
                if j_min != j_max
                {
                    // in the special case where the 2 polynomials are in the same memory
                    // we need to double the first multiplication cause we cannot compute the last one
                    add(&ans.coefficients[i], ans.coefficients[i], temp_var)
                }
            }
            else
            {
                add(&ans.coefficients[i], ans.coefficients[i], temp_var)
            }
        }
    }
    delete(temp_var)
}

// polynomial self multiplication sets ans to ans * ans
mul_self_numeric :: proc(ans : ^Polynomial($T, $ST))
    where ST == field.NumericField(T) || ST == euclidean_ring.NumericEuclideanRing(T)
{
    deg_l := degree(ans^)
    deg_r := degree(ans^)

    resize_or_init_polynomial(ans, ans.algebraic_structure, deg_l + deg_r)

    for i := (deg_l + deg_r); i >= 0; i -= 1
    {
        j_min := max(0, i - deg_l)
        j_max := min(i, deg_r)
        for j in j_min..=j_max
        {
            // we need to do the one with the largest
            l_index := i - j
            r_index := j
            if j_min != j_max && j == j_max
            {
                // in the special case where the 2 polynomials are in the same memory
                // we skip the last multiplication since what we are multipling by has already been overwitten
                continue
            }

            temp_var := ans.coefficients[l_index] * ans.coefficients[r_index]
            if j == j_min
            {
                // first itteration
                ans.coefficients[i] = temp_var
                if j_min != j_max
                {
                    // in the special case where the 2 polynomials are in the same memory
                    // we need to double the first multiplication cause we cannot compute the last one
                    ans.coefficients[i] += temp_var
                }
            }
            else
            {
                ans.coefficients[i] += temp_var
            }
        }
    }
}

// polynomial *= opertation sets ans = ans * r
mul_self_by_other_ring_left :: proc(ans : ^Polynomial($T, $ST), r : Polynomial(T, ST))
    where intrinsics.type_is_subtype_of(ST, ring.Ring(T))
{
    using ans.algebraic_structure

    deg_l := degree(ans^)
    deg_r := degree(r)

    resize_or_init_polynomial(ans, ans.algebraic_structure, deg_l + deg_r)

    temp_var : T

    for i := (deg_l + deg_r); i >= 0; i -= 1
    {
        j_min := max(0, i - deg_l)
        j_max := min(i, deg_r)
        for j in j_min..=j_max
        {
            l_index := i - j
            r_index := j

            mul(&temp_var,
                ans.coefficients[l_index],
                r.coefficients[r_index]
            )

            if j == j_min
            {
                // first itteration
                set(&ans.coefficients[i], temp_var)
            }
            else
            {
                add(&ans.coefficients[i], ans.coefficients[i], temp_var)
            }
        }
    }

    delete(temp_var)
}

// polynomial sets ans = l * ans
mul_self_by_other_ring_right :: proc(ans : ^Polynomial($T, $ST), l : Polynomial(T, ST))
    where intrinsics.type_is_subtype_of(ST, ring.Ring(T))
{
    using ans.algebraic_structure

    deg_l := degree(l)
    deg_r := degree(ans^)

    resize_or_init_polynomial(ans, l.algebraic_structure, deg_l + deg_r)

    temp_var : T

    for i := (deg_l + deg_r); i >= 0; i -= 1
    {
        j_min := max(0, i - deg_r)
        j_max := min(i, deg_l)
        for j in j_min..=j_max
        {
            l_index := j
            r_index := i - j

            mul(&temp_var,
                l.coefficients[l_index],
                ans.coefficients[r_index]
            )

            if j == j_min
            {
                // first itteration
                set(&ans.coefficients[i], temp_var)
            }
            else
            {
                add(&ans.coefficients[i], ans.coefficients[i], temp_var)
            }
        }
    }

    delete(temp_var)
}

// polynomial sets ans = ans * r
mul_self_by_other_numeric :: proc(ans : ^Polynomial($T, $ST), r : Polynomial(T, ST))
    where ST == field.NumericField(T) || ST == euclidean_ring.NumericEuclideanRing(T)
{
    deg_l := degree(ans^)
    deg_r := degree(r)

    resize_or_init_polynomial(ans, r.algebraic_structure, deg_l + deg_r)

    for i := (deg_l + deg_r); i >= 0; i -= 1
    {
        j_min := max(0, i - deg_l)
        j_max := min(i, deg_r)
        for j in j_min..=j_max
        {
            l_index := i - j
            r_index := j

            if j == j_min
            {
                // first itteration
                ans.coefficients[i] = ans.coefficients[l_index] * r.coefficients[r_index]
            }
            else
            {
                ans.coefficients[i] += ans.coefficients[l_index] * r.coefficients[r_index]
            }
        }
    }
}

// polynomial multiplication where ans, l and r are indepeneted ie they there coefficients are all in differnt memory
mul_independent_ring :: proc(ans : ^Polynomial($T, $ST), l : Polynomial(T, ST), r : Polynomial(T, ST))
    where intrinsics.type_is_subtype_of(ST, ring.Ring(T))
{
    using ans.algebraic_structure

    deg_l := degree(l)
    deg_r := degree(r)

    resize_or_init_polynomial(ans, l.algebraic_structure, deg_l + deg_r)

    // in this case we do not require any temporary variables
    // we use ans.coefficients[0] as a temporary variable so we do not need to do any allocations
    for i in 1..=(deg_l + deg_r)
    {
        set(&ans.coefficients[i], add_identity)
        for j in max(0, i - deg_r)..=min(i, deg_l)
        {
            l_index := j
            r_index := i - j

            mul(&ans.coefficients[0], l.coefficients[l_index], r.coefficients[r_index])
            add(&ans.coefficients[i], ans.coefficients[i], ans.coefficients[0])
        }
    }
    // set ans.coefficients[0] as we where using it as a temporary variable
    mul(&ans.coefficients[0], l.coefficients[0], r.coefficients[0])
}

// polynomial multiplication where ans, l and r are indepeneted ie they there coefficients are all in differnt memory
mul_independent_numeric :: proc(ans : ^Polynomial($T, $ST), l : Polynomial(T, ST), r : Polynomial(T, ST))
    where ST == field.NumericField(T) || ST == euclidean_ring.NumericEuclideanRing(T)
{
    deg_l := degree(l)
    deg_r := degree(r)

    resize_or_init_polynomial(ans, l.algebraic_structure, deg_l + deg_r)

    // in this case we do not require any temporary variables
    // we use 0 as a temporary variable so we do not need to do any allocations
    for i in 1..=(deg_l + deg_r)
    {
        ans.coefficients[i] = 0
        for j in max(0, i - deg_r)..=min(i, deg_l)
        {
            l_index := j
            r_index := i - j
            ans.coefficients[i] += l.coefficients[l_index] * r.coefficients[r_index]
        }
    }
    ans.coefficients[0] = l.coefficients[0] * r.coefficients[0]
}

// polynomial multiplication sets ans = l * r
mul :: proc{
    mul_ring,
    mul_numeric,
}

mul_ring :: proc(ans : ^Polynomial($T, $ST), l : Polynomial(T, ST), r : Polynomial(T, ST))
    where intrinsics.type_is_subtype_of(ST, ring.Ring(T))
{
    assert(is_valid(ans^))
    assert(is_valid(l))
    assert(is_valid(r))

    if degree(l) == -1 || degree(r) == -1
    {
        resize_or_init_polynomial(ans, l.algebraic_structure, -1)
    }
    else if rawptr(raw_data(ans.coefficients)) != rawptr(raw_data(l.coefficients)) &&
        rawptr(raw_data(ans.coefficients)) != rawptr(raw_data(r.coefficients))
    {
        mul_independent_ring(ans, l, r)
    }
    else if rawptr(raw_data(ans.coefficients)) == rawptr(raw_data(l.coefficients)) &&
        rawptr(raw_data(l.coefficients)) != rawptr(raw_data(r.coefficients))
    {
        mul_self_by_other_ring_left(ans, r)
    }
    else if rawptr(raw_data(ans.coefficients)) == rawptr(raw_data(r.coefficients)) &&
        rawptr(raw_data(l.coefficients)) != rawptr(raw_data(r.coefficients))
    {
        mul_self_by_other_ring_right(ans, l)
    }
    else
    {
        mul_self_ring(ans)
    }
}

mul_numeric :: proc(ans : ^Polynomial($T, $ST), l : Polynomial(T, ST), r : Polynomial(T, ST))
    where ST == field.NumericField(T) || ST == euclidean_ring.NumericEuclideanRing(T)
{
    assert(is_valid(ans^))
    assert(is_valid(l))
    assert(is_valid(r))

    if degree(l) == -1 || degree(r) == -1
    {
        resize_or_init_polynomial(ans, l.algebraic_structure, -1)
    }
    else if rawptr(raw_data(ans.coefficients)) != rawptr(raw_data(l.coefficients)) &&
        rawptr(raw_data(ans.coefficients)) != rawptr(raw_data(r.coefficients))
    {
        mul_independent_numeric(ans, l, r)
    }
    else if rawptr(raw_data(ans.coefficients)) == rawptr(raw_data(l.coefficients)) &&
        rawptr(raw_data(l.coefficients)) != rawptr(raw_data(r.coefficients))
    {
        mul_self_by_other_numeric(ans, r)
    }
    else if rawptr(raw_data(ans.coefficients)) == rawptr(raw_data(r.coefficients)) &&
        rawptr(raw_data(l.coefficients)) != rawptr(raw_data(r.coefficients))
    {
        mul_self_by_other_numeric(ans, l)
    }
    else
    {
        mul_self_numeric(ans)
    }
}

// polynomial negation sets ans = -l
neg :: proc(ans : ^Polynomial($T, $ST), l : Polynomial(T, ST))
{
    assert(is_valid(ans^))
    assert(is_valid(l))

    deg_ans := degree(ans^)
    deg_l := degree(l)

    resize_or_init_polynomial(ans, l.algebraic_structure, deg_l)

    for i in 0..=deg_l
    {
        when ST == field.NumericField(T) || ST == euclidean_ring.NumericEuclideanRing(T)
        {
            ans.coefficients[i] = -l.coefficients[i]
        }
        else
        {
            ans.algebraic_structure.neg(&ans.coefficients[i], l.coefficients[i])
        }
    }
    shrink_to_valid(ans)
}

// returns the additive identity polynomial ie the 0 polynomial
add_ident_polynomial :: proc($T : typeid, algebraic_structure : $ST) -> Polynomial(T, ST)
{
    return make_uninitialized(T, algebraic_structure, -1)
}

// returns the multiplicative identity polynomial ie the 1 polynomial
mul_ident_polynomial :: proc($T : typeid, algebraic_structure : $ST) -> Polynomial(T, ST)
{
    ans := make_uninitialized(T, algebraic_structure, 0)
    when ST == field.NumericField(T) || ST == euclidean_ring.NumericEuclideanRing(T)
    {
        ans.coefficients[0] = 1
    }
    else
    {
        algebraic_structure.set(&ans.coefficients[0], algebraic_structure.mul_identity)
    }
    return ans
}
