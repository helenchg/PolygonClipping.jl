module GreinerHormann
import Base.show

type Vertex
    location::Array
    next
    prev
    nextpoly
    intersect::Bool
    entry::Bool
    neighbor
    alpha::Float64

    Vertex(x) = new(x, None, None, None, false, false, None, 0.0)
end

################################################################################
#
# Polygon:
#   start
#   finish
#
# Push!(Polygon, Vertex)
#   Notes:
#   For cleaner implmentation, the last Vertex always points to a vertex with
#   the same location as the start vertex
#
################################################################################

type Polygon
    start
    finish

    Polygon() = new(None, None)
end

function show(io::IO, p::Polygon)
    vert = p.start
    print("Polygon(")
    while vert != None
        print(vert.location)
        vert = vert.next
    end
    print(")")
end

function push!(p::Polygon, v::Vertex)
    if p.start == None
        p.start = v
        p.finish = v
        close = Vertex(v.location)
        close.prev = v
        p.start.next = close
    else
        v.next = p.finish.next
        v.prev = p.finish
        p.finish.next = v
        p.finish = v
    end
end

function Vertex(s::Vertex, c::Vertex, alpha)
    # Insert a vertex between s and c at alpha from s
    location = s.location + alpha*(c.location-s.location)
    a = Vertex(location)
    s.next = a
    c.prev = a
    a.next = c
    a.prev = s
    return a
end

export Vertex, Polygon, push!
end # module
