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

type Polygon
    start

    Polygon() = new(None)
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
    else
        tail = p.start
        while tail.next != None
            tail = tail.next
        end
        v.prev = tail
        tail.next = v
    end
end


export Vertex, Polygon, push!
end # module
