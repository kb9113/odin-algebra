package rational
import "../prop_based"
import "core:math/rand"
import "core:strings"


RationalGeneratorInfo :: struct($T : typeid, $ST : typeid)
{
    coefficent_generator : prop_based.Generator(T),
    coefficent_algebraic_structure : ST
}

// makes a generator for rationals given a generator of the numerator and denominator
// used for property based testing of rationals
make_generator :: proc(
    coefficent_generator : prop_based.Generator($T),
    coefficent_algebraic_structure : $ST
) -> prop_based.Generator(Rational(T, ST))
{
    generator_info_ptr := new(RationalGeneratorInfo(T, ST))
    generator_info_ptr.coefficent_generator = coefficent_generator
    generator_info_ptr.coefficent_algebraic_structure = coefficent_algebraic_structure

    generate_rat :: proc(generator_info_raw : rawptr) -> Rational(T, ST)
    {
        generator_info := (cast(^RationalGeneratorInfo(T, ST))generator_info_raw)^

        numerator : T
        denominator : T

        generator_info.coefficent_algebraic_structure.set(
            &numerator, generator_info.coefficent_generator.generate(generator_info.coefficent_generator.raw)
        )
        generator_info.coefficent_algebraic_structure.set(
            &denominator, generator_info.coefficent_generator.generate(generator_info.coefficent_generator.raw)
        )

        for generator_info.coefficent_algebraic_structure.eq(
            denominator, generator_info.coefficent_algebraic_structure.add_identity
        )
        {
            new_denominator := generator_info.coefficent_generator.generate(generator_info.coefficent_generator.raw)
            generator_info.coefficent_algebraic_structure.set(&denominator, new_denominator)
            generator_info.coefficent_algebraic_structure.delete(new_denominator)
        }

        ans := make_rational(
            numerator,
            denominator,
            generator_info.coefficent_algebraic_structure
        )

        return ans
    }

    reduce_rat :: proc(generator_info_raw : rawptr, r : Rational(T, ST)) ->
        Rational(T, ST)
    {
        generator_info := (cast(^RationalGeneratorInfo(T, ST))generator_info_raw)^

        numerator : T
        denominator : T

        generator_info.coefficent_algebraic_structure.set(
            &numerator, generator_info.coefficent_generator.reduce(generator_info.coefficent_generator.raw, r.numerator)
        )
        generator_info.coefficent_algebraic_structure.set(
            &denominator, generator_info.coefficent_generator.reduce(generator_info.coefficent_generator.raw, r.denominator)
        )

        for generator_info.coefficent_algebraic_structure.eq(
            denominator, generator_info.coefficent_algebraic_structure.add_identity
        )
        {
            new_denominator := generator_info.coefficent_generator.generate(generator_info.coefficent_generator.raw)
            generator_info.coefficent_algebraic_structure.set(&denominator, new_denominator)
            generator_info.coefficent_algebraic_structure.delete(new_denominator)
        }

        ans := make_rational(
            numerator,
            denominator,
            generator_info.coefficent_algebraic_structure
        )

        return ans
    }

    delete_rat :: proc(p : Rational(T, ST))
    {
        delete_rational(p)
    }

    print_rat :: proc(sb : ^strings.Builder, p : Rational(T, ST))
    {
        sb_print_rational(sb, p)
    }

    ans := prop_based.Generator(Rational(T, ST)){
        rawptr(generator_info_ptr),
        generate_rat,
        reduce_rat,
        delete_rat,
        print_rat
    }
    return ans
}

delete_generator :: proc(gen : prop_based.Generator(Rational($T, $ST)))
{
    free(cast(^RationalGeneratorInfo(T, ST))gen.raw)
}
