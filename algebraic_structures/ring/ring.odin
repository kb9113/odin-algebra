/*
Interface for a Ring and CommutativeRing
- add - called to perform the operation ans = left + right
- sub - called to perform the operation ans = left - right
- mul - called to perform the operation ans = left * right
- neg - called to perform the operation ans = -left
- add_identity - a + additive_identity == a for all a
- mul_identity - a * mul_identity == a for all a
- all functions can be called where 2 or 3 input parameters point to the same piece of memory
*/
package ring
import "core:mem"
import "../base"
import "core:strings"
import "core:fmt"

/*
Interface for a ring:
- add - called to perform the operation ans = left + right
- sub - called to perform the operation ans = left - right
- mul - called to perform the operation ans = left * right
- neg - called to perform the operation ans = -left
- add_identity - a + additive_identity == a for all a
- mul_identity - a * mul_identity == a for all a
- all functions can be called where 2 or 3 input parameters point to the same piece of memory
*/
Ring :: struct($T : typeid)
{
    using base : base.Base(T),
    add : proc(ans : ^T, left : T, right : T),
    sub : proc(ans : ^T, left : T, right : T),
    mul : proc(ans : ^T, left : T, right : T),
    neg : proc(ans : ^T, left : T),
    add_identity : T,
    mul_identity : T,
}

/*
Has no additional operations above what Ring has just indicates to the type system that addition is commutative
*/
CommutativeRing :: struct($T : typeid)
{
    using ring : Ring(T)
}

add_f32 :: proc(a : ^f32, l : f32, r : f32) { a^ = l + r }
sub_f32 :: proc(a : ^f32, l : f32, r : f32) { a^ = l - r }
mul_f32 :: proc(a : ^f32, l : f32, r : f32) { a^ = l * r }
neg_f32 :: proc(a : ^f32, l : f32) { a^ = -l }

RING_F32 :: CommutativeRing(f32){
    Ring(f32){
        base.BASE_F32,
        add_f32,
        sub_f32,
        mul_f32,
        neg_f32,
        0,
        1
    }
}

add_u32 :: proc(a : ^u32, l : u32, r : u32) { a^ = l + r }
sub_u32 :: proc(a : ^u32, l : u32, r : u32) { a^ = l - r }
mul_u32 :: proc(a : ^u32, l : u32, r : u32) { a^ = l * r }
neg_u32 :: proc(a : ^u32, l : u32) { a^ = -l }

RING_U32 :: CommutativeRing(u32){
    Ring(u32){
        base.BASE_U32,
        add_u32,
        sub_u32,
        mul_u32,
        neg_u32,
        0,
        1
    }
}

add_i32 :: proc(a : ^i32, l : i32, r : i32) { a^ = l + r }
sub_i32 :: proc(a : ^i32, l : i32, r : i32) { a^ = l - r }
mul_i32 :: proc(a : ^i32, l : i32, r : i32) { a^ = l * r }
neg_i32 :: proc(a : ^i32, l : i32) { a^ = -l }

RING_I32 :: CommutativeRing(i32){
    Ring(i32){
        base.BASE_I32,
        add_i32,
        sub_i32,
        mul_i32,
        neg_i32,
        0,
        1
    }
}

add_i64 :: proc(a : ^i64, l : i64, r : i64) { a^ = l + r }
sub_i64 :: proc(a : ^i64, l : i64, r : i64) { a^ = l - r }
mul_i64 :: proc(a : ^i64, l : i64, r : i64) { a^ = l * r }
neg_i64 :: proc(a : ^i64, l : i64) { a^ = -l }

RING_I64 :: CommutativeRing(i64){
    Ring(i64){
        base.BASE_I64,
        add_i64,
        sub_i64,
        mul_i64,
        neg_i64,
        0,
        1
    }
}

// sets ans = x^power for any ring
integer_pow :: proc(ans : ^$T, x : T, power : uint, ring : Ring(T))
{
    using ring
    tmp_var : T
    set(&tmp_var, x)
    set(ans, ring.mul_identity)

    curr_pow := power
    for curr_pow > 0
    {
        if curr_pow % 2 == 1
        {
            mul(ans, ans^, tmp_var)
        }
        curr_pow /= 2
        mul(&tmp_var, tmp_var, tmp_var)
    }
    delete(tmp_var)
}
