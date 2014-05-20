using GreinerHormann
using Base.Test

# Test Doubly linked list
println("Testing Polygon Structure...")
poly = Polygon()
vert1 = Vertex([1,2])
push!(poly, vert1)
for i = 1:10
    push!(poly, Vertex(rand(2)))
end
vert1 = poly.start
vert2 = vert1.next
for i = 1:10
    @test vert1 === vert2.prev
    vert1 = vert1.next
    vert2 = vert2.next
end
# test we close the polygon and terminate with None
@test poly.start.location == poly.finish.next.location
@test poly.finish.next.next == None

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

# test isinside method
println("Testing point in polygon...")
poly1 = Polygon()
push!(poly1, Vertex([0,0]))
push!(poly1, Vertex([1,0]))
push!(poly1, Vertex([1,1]))
push!(poly1, Vertex([0,1]))
@test isinside(Vertex([0.5,0.5]), poly1) == true
@test isinside(Vertex([-0.5,0.5]), poly1) == false
for i = 1:100
    @test isinside(Vertex(rand(2)), poly1) == true
end

# add non-convexity
push!(poly1, Vertex([0.9,0.5]))
@test isinside(Vertex([0.9,0.9]), poly1) == true
@test isinside(Vertex([0.9,0.9]), poly1) == true
@test isinside(Vertex([0.99,0.1]), poly1) == true
@test isinside(Vertex([0.5,0.5]), poly1) == false
# the test below is an edge case we don't handle yet
#@test isinside(Vertex([0.9,0.1]), poly1) == true

# add self-intersection
push!(poly1, Vertex([1.1, 0.25]))
@test isinside(Vertex([1.09,0.24]), poly1) == true
@test isinside(Vertex([1.09,0.26]), poly1) == true
@test isinside(Vertex([0.9,0.25]), poly1) == false


# test intersection method
println("Testing line intersection method...")
@test (intersection(Vertex([0,0]), Vertex([1,1]), Vertex([1,0]), Vertex([0,1]))
        == (true, 0.5, 0.5))
@test (intersection(Vertex([0,0]), Vertex([1,1]), Vertex([1/2,0]), Vertex([0,1/2]))
        == (true, 0.25, 0.5))
@test (intersection(Vertex([0,0]), Vertex([2,2]), Vertex([1/2,0]), Vertex([0,1/2]))
        == (true, 0.125, 0.5))
@test (intersection(Vertex([0,0]), Vertex([0,1]), Vertex([1,0]), Vertex([1,1]))
        == (false, 0, 0))
@test (intersection(Vertex([0.5,0]), Vertex([0.5,1]), Vertex([0,0.5]), Vertex([1,0.5]))
        == (true, 0.5, 0.5))
@test (intersection(Vertex([0,0]), Vertex([1,1]), Vertex([0,0]), Vertex([-1,-1]))
        == (false, 0, 0))
@test (intersection(Vertex([0,0]), Vertex([0,0]), Vertex([1,1]), Vertex([1,1]))
        == (false, 0, 0))
@test (intersection(Vertex([0,0]), Vertex([1,0]), Vertex([0.25,0.5]), Vertex([0.25,-0.5]))
        == (true, 0.25, 0.5))
@test (intersection(Vertex([1,0]), Vertex([0,0]), Vertex([0.25,0.5]), Vertex([0.25,-0.5]))
        == (true, 0.75, 0.5))
@test (intersection(Vertex([0,0]), Vertex([1,0]), Vertex([0.25,-0.5]), Vertex([0.25,0.25]))
        == (true, 0.25, 2/3))
@test (intersection(Vertex([0,0]), Vertex([1,0]), Vertex([0.25,0.25]), Vertex([0.25,-0.5]))
        == (true, 0.25, 1/3))
@test (intersection(Vertex([0,0]), Vertex([1,0]), Vertex([1.5,0.5]), Vertex([1.5,-0.5]))
        == (false, 0, 0))


# test vertex constructor for insertion
vert1 = Vertex([0,0])
vert2 = Vertex([1,1])
vert3 = Vertex(vert1, vert2, 0.25)
@test vert3.next === vert2
@test vert3.prev === vert1
@test vert3.location == [0.25,0.25]
vert3 = Vertex(vert2, vert1, 0.25)
@test vert3.next === vert1
@test vert3.prev === vert2
@test vert3.location == [0.75,0.75]

# test unprocessed
poly1 = Polygon()
push!(poly1, Vertex([0,0]))
push!(poly1, Vertex([1,0]))
push!(poly1, Vertex([1,1]))
push!(poly1, Vertex([0,1]))
@test unprocessed(poly1) == false
poly1.start.next.intersect = true
@test unprocessed(poly1) == true
poly1.start.next.visited = true
@test unprocessed(poly1) == false

# test clipping
println("Testing clipping...")
poly1 = Polygon()
push!(poly1, Vertex([0,0]))
push!(poly1, Vertex([1,0]))
push!(poly1, Vertex([1,1]))
push!(poly1, Vertex([0,1]))

poly2 = Polygon()
push!(poly2, Vertex([0.5,0.5]))
push!(poly2, Vertex([1.5,0.5]))
push!(poly2, Vertex([1.5,-0.5]))
push!(poly2, Vertex([0.5,-0.5]))
a = clip(poly1, poly2)
println(a)
