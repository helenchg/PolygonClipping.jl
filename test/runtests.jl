using GreinerHormann
using Base.Test

# Test Doubly linked list
println("Testing doubly linked list...")
poly = Polygon()
for i = 1:10
    push!(poly, Vertex(rand(2)))
end
vert1 = poly.start
vert2 = vert1.next
for i = 1:9
    @test vert1 === vert2.prev
    vert1 = vert1.next
    vert2 = vert2.next
end

println("Testing vertex constructors...")
vert1 = Vertex([0,0])
vert2 = Vertex([2,1])
poly = Polygon()
push!(poly, vert1)
push!(poly, vert2)
a = Vertex(poly.start, poly.start.next, 0.25)
@test a.location == [0.5,0.25]
@test poly.start === vert1
@test a.prev === vert1
@test a.next === vert2
@test vert1.next === a
@test vert2.prev === a

