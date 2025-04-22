package prop_test

import "core:math/rand"
import "core:strings"
import "core:fmt"
import "core:math"

/*
some generators for some built in types
*/

generate_i64 :: proc(raw : rawptr) -> i64
{
    return (transmute(i64)rand.uint64()) % 16 - 8
}

reduce_i64 :: proc(raw : rawptr, old : i64) -> i64
{
    rnd := rand.uint64()
    if rnd % 3 == 0
    {
        return old / 2
    }
    else if rnd % 3 == 1
    {
        return old - 1
    }
    else
    {
        return abs(old)
    }
}

delete_i64 :: proc(old : i64) {}

print_i64 :: proc(sb : ^strings.Builder, i : i64)
{
    fmt.sbprint(sb, i)
}

GENERATOR_I64 :: Generator(i64){
    nil,
    generate_i64,
    reduce_i64,
    delete_i64,
    print_i64
}

generate_f32 :: proc(raw : rawptr) -> f32
{
    return rand.float32() * 8
}

reduce_f32 :: proc(raw : rawptr, old : f32) -> f32
{
    rnd := rand.uint64()
    if rnd % 2 == 0
    {
        return math.round(old)
    }
    else
    {
        return math.round(old) + 0.5
    }
}

delete_f32 :: proc(old : f32) {}

print_f32 :: proc(sb : ^strings.Builder, f : f32)
{
    fmt.sbprint(sb, f)
}

GENERATOR_F32 :: Generator(f32){
    nil,
    generate_f32,
    reduce_f32,
    delete_f32,
    print_f32
}
