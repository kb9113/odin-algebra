// Implementation of polynomials field over some underling algebraic structures.
package polynomial
import "core:math"
import "core:math/cmplx"
import "core:slice"
import "base:intrinsics"
import "core:log"
import "core:mem"
import "core:fmt"
import "core:strings"
import "../algebraic_structures/ring"
import "../algebraic_structures/field"
import "../algebraic_structures/euclidean_ring"

/*
This structure represents a polynomial of any degree.
This should not be constructed directly the make_from_coefficients function should be used instead.
The coefficients are stored so that there index is the power of x.
The highest power coefficient should never be zero.

Inputs:
- $T: the type of the coefficients
- $ST: the type of the algebraic structure used to operate on the coefficients

Example:
	Polynomial(f32, Numeric(f32))
	Polynomial(Polynomial(f32, Numeric(f32)), EuclideanRing(f32))

*/
Polynomial :: struct($T : typeid, $ST : typeid)
{
    coefficients : [dynamic]T,
    algebraic_structure : ST
}

// used to make uninitialized polynomials unless you set degree to -1 the returned polynomial will not be valid
// since all its coefficients will be 0
make_uninitialized :: proc{
    make_uninitialized_numeric,
    make_uninitialized_algebraic_structure,
}

make_uninitialized_numeric :: proc($T : typeid, degree : int) ->
    Polynomial(T, field.NumericField(T)) where intrinsics.type_is_numeric(T)
{
    ans := Polynomial(T, field.NumericField(T)){}
    ans.coefficients = make([dynamic]T, degree + 1)
    return ans
}

make_uninitialized_algebraic_structure :: proc($T : typeid, algebraic_structure : $ST, degree : int) ->
    Polynomial(T, ST)
{
    ans := Polynomial(T, ST){}
    ans.coefficients = make([dynamic]T, degree + 1)
    ans.algebraic_structure = algebraic_structure
    return ans
}

/*
Makes a polynomial from the coefficients.
Clones the slice so the slice can go off the stack.
Does not clone the underlying data structures.
*/
make_from_coefficients :: proc{

    make_from_coefficients_numeric,
    make_from_coefficients_algebraic_structure,
}

make_from_coefficients_numeric :: proc($T : typeid, coefficients : []T, allocator := context.allocator) ->
    Polynomial(T, field.NumericField(T)) where intrinsics.type_is_numeric(T)
{
    ans := Polynomial(T, field.NumericField(T)){}
    ans.coefficients = slice.clone_to_dynamic(coefficients, allocator)
    assert(is_valid(ans))
    return ans
}

make_from_coefficients_algebraic_structure :: proc($T : typeid, algebraic_structure : $ST, coefficients : []T, allocator := context.allocator) ->
    Polynomial(T, ST)
{
    ans := Polynomial(T, ST){}
    ans.coefficients = slice.clone_to_dynamic(coefficients, allocator)
    ans.algebraic_structure = algebraic_structure
    assert(is_valid(ans))
    return ans
}

// determines if a polynomial is valid a polynomial is valid if it is the zero polynomial
// or its leading coefficient is not zero
is_valid :: proc(p : Polynomial($T, $ST)) -> bool
{
    if len(p.coefficients) == 0
    {
        return true
    }
    when ST == field.NumericField(T) || ST == euclidean_ring.EuclideanRing(T)
    {
        return p.coefficients[len(p.coefficients) - 1] != 0
    }
    else
    {
        return !p.algebraic_structure.eq(p.coefficients[len(p.coefficients) - 1], p.algebraic_structure.add_identity)
    }
}

// shrinks a polynomial that may or may not be valid to a valid polynomial by removing leading zeros
shrink_to_valid :: proc(p : ^Polynomial($T, $ST))
{
    when ST == field.NumericField(T) || ST == euclidean_ring.EuclideanRing(T)
    {
        i := len(p.coefficients) - 1
        for i >= 0 && p.coefficients[i] == 0
        {
            unordered_remove(&p.coefficients, i)
            i -= 1
        }
    }
    else
    {
        i := len(p.coefficients) - 1
        for i >= 0 && p.algebraic_structure.eq(p.coefficients[i], p.algebraic_structure.add_identity)
        {
            p.algebraic_structure.delete(p.coefficients[i])
            unordered_remove(&p.coefficients, i)
            i -= 1
        }
    }
}

// returns the degree of a polynomial -1 is returned of the zero polynomial
degree :: proc(p : Polynomial($T, $ST)) -> int
{
    assert(is_valid(p))
    return len(p.coefficients) - 1
}

resize_or_init_polynomial :: proc(p : ^Polynomial($T, $ST), algebraic_structure : ST, new_degree : int, loc := #caller_location)
{
    if cap(p.coefficients) == 0
    {
        // l has not yet been initalized so we initalize it
        p.coefficients = make([dynamic]T, context.allocator, loc)
        p.algebraic_structure = algebraic_structure
    }

    old_degree := degree(p^)
    if old_degree < new_degree
    {
        resize(&p.coefficients, new_degree + 1, loc)
    }
    if old_degree > new_degree
    {
        when ST != field.NumericField(T)
        {
            for i in (new_degree + 1)..=old_degree
            {
                p.algebraic_structure.delete(p.coefficients[i])
            }
        }
        resize(&p.coefficients, new_degree + 1, loc)
    }
}
