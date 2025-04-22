package field
import "core:math"
import "core:mem"
import "../euclidean_ring"

/*
Interface for a Field:
- div - called to perform the operation ans = left / right
- mul_inverse - called to perform ans = 1 / left
- all functions can be called where 2 or 3 input paramters point to the same piece of memory.
*/
Field :: struct($T : typeid)
{
    using euclidean_ring : euclidean_ring.EuclideanRing(T),
    div : proc(ans : ^T, left : T, right : T),
    mul_inverse : proc(ans : ^T, left : T),
}

NumericField :: struct($T : typeid)
{

}

div_f32 :: proc(a : ^f32, l : f32, r : f32) { a^ = l / r }
mul_inverse_f32 :: proc(a : ^f32, l : f32) { a^ = 1 / l }

FIELD_F32 :: Field(f32){
    euclidean_ring.EUCLIDEAN_RING_F32,
    div_f32,
    mul_inverse_f32
}
