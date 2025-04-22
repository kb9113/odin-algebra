# odin-algebra

An abstract algebra library written in odin. It implements interfaces for different algebraic structures as well as polynomials and rationals which operate over theses structures. This means algebraic objects can be composed to form more complicated algebraic structures. For example you can have polynomials with polynomial coefficients or represent the rational functions as a rational with polynomial numerator and denominator.

## Algebraic Structures
- Ring
- Commutative Ring
- Integral Domain
- Euclidean Ring
- Field

## Algebraic Objects
- Polynomial - implement the euclidean ring structure if the coefficients are a field
- Rational - implements the field structure

## Examples
This library implements all the basic operations you would expect to find on a polynomial as well as differentiation, integration, complex and real root finding and sub resultant sequence calculations. \
\
This means this library can be used to solve systems of multivariate polynomial equations.
```odin
id := make_polynomial_integral_domain(f32, field.FIELD_F32)
defer delete_polynomial_integral_domain(id)

//x^2-10x-y^2
r1 := make_from_coefficients(
    Polynomial(f32, field.Field(f32)),
    id,
    []Polynomial(f32, field.Field(f32)){
        make_from_coefficients(f32, field.FIELD_F32, []f32{0, 0, -1}),
        make_from_coefficients(f32, field.FIELD_F32, []f32{-10}),
        make_from_coefficients(f32, field.FIELD_F32, []f32{1}),
    }
)
defer delete_polynomial(r1)

// x^2+1+y
r2 := make_from_coefficients(
    Polynomial(f32, field.Field(f32)),
    id,
    []Polynomial(f32, field.Field(f32)){
        make_from_coefficients(f32, field.FIELD_F32, []f32{1, 1}),
        make_from_coefficients(f32, field.FIELD_F32, []f32{}),
        make_from_coefficients(f32, field.FIELD_F32, []f32{1}),
    }
)
defer delete_polynomial(r2)

// y^4 + 2 y^3 + 3 y^2 + 102 y + 101
res := resultant(r1, r2)
defer delete_polynomial(res)

// compute the y values of the roots
y_values := real_roots(res)
defer delete(y_values)
for y in y_values
{
    // sub the y values back into the polynomials
    substituted_polynomial_r1 := make_uninitialized(f32, field.FIELD_F32, degree(r1))
    defer delete_polynomial(substituted_polynomial_r1)
    substituted_polynomial_r2 := make_uninitialized(f32, field.FIELD_F32, degree(r2))
    defer delete_polynomial(substituted_polynomial_r2)
    for i in 0..=degree(r1)
    {
        substituted_polynomial_r1.coefficients[i] = eval(r1.coefficients[i], y)
    }
    for i in 0..=degree(r2)
    {
        substituted_polynomial_r2.coefficients[i] = eval(r2.coefficients[i], y)
    }

    // compute x values for both polynomials
    x_values_r1 := real_roots(substituted_polynomial_r1)
    defer delete(x_values_r1)
    x_values_r2 := real_roots(substituted_polynomial_r2)
    defer delete(x_values_r2)

    // match up and print roots in both
    for x1 in x_values_r1
    {
        for x2 in x_values_r2
        {
            if abs(x1 - x2) < 1e-6
            {
                fmt.println("root x =", x1, "y =", y)
            }
        }
    }
}
```
