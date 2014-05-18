using GreinerHormann
using Base.Test

# Test Doubly linked list
println("Testing doubly linked list")
poly = Polygon()
for i = 1:10
    push!(poly, Vertex(rand(2)))
end
vert1 = poly.start
vert2 = vert1.next
for i = 1:9
    @test is(vert1, vert2.prev)
    vert1 = vert1.next
    vert2 = vert2.next
end

