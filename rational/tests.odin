package rational

import "core:testing"
import "core:log"
import "../algebraic_structures/euclidean_ring"
import "../algebraic_structures/integral_domain"
import "../algebraic_structures/field"
import "../prop_based"

@(test)
test_rational_over_i64_integral_domain_axioms :: proc(t: ^testing.T)
{
    id := make_rational_integral_domain(i64, euclidean_ring.EUCLIDEAN_RING_I64)
    defer delete_rational_integral_domain(id)
    rational_generator := make_generator(prop_based.GENERATOR_I64, euclidean_ring.EUCLIDEAN_RING_I64)
    defer delete_generator(rational_generator)
    integral_domain.test_integral_domain_axioms(t, rational_generator, id)
}

@(test)
test_rational_over_i64_integral_domain_safety_axioms :: proc(t: ^testing.T)
{
    id := make_rational_integral_domain(i64, euclidean_ring.EUCLIDEAN_RING_I64)
    defer delete_rational_integral_domain(id)
    rational_generator := make_generator(prop_based.GENERATOR_I64, euclidean_ring.EUCLIDEAN_RING_I64)
    defer delete_generator(rational_generator)
    integral_domain.test_memory_safety_axioms(t, rational_generator, id)
}

@(test)
test_rational_over_i64_euclidean_ring_axioms :: proc(t: ^testing.T)
{
    er := make_rational_euclidean_ring(i64, euclidean_ring.EUCLIDEAN_RING_I64)
    defer delete_rational_euclidean_ring(er)
    rational_generator := make_generator(prop_based.GENERATOR_I64, euclidean_ring.EUCLIDEAN_RING_I64)
    defer delete_generator(rational_generator)
    euclidean_ring.test_euclidean_ring_axioms(t, rational_generator, er)
}

@(test)
test_rational_over_i64_field_axioms :: proc(t: ^testing.T)
{
    f := make_rational_field(i64, euclidean_ring.EUCLIDEAN_RING_I64)
    defer delete_rational_field(f)
    rational_generator := make_generator(prop_based.GENERATOR_I64, euclidean_ring.EUCLIDEAN_RING_I64)
    defer delete_generator(rational_generator)
    field.test_field_axioms(t, rational_generator, f)
}
