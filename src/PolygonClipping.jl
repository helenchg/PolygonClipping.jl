module PolygonClipping

import Base.show
import Base.push!
import Base.length
using ImmutableArrays

export Vertex, Polygon, push!, intersection, isinside, show, unprocessed,
       VertexException, EdgeException, DegeneracyException, length

type Vertex
    location::Vector2
    next::Vertex
    prev::Vertex
    nextpoly::Vertex
    intersect::Bool
    entry::Bool
    neighbor::Vertex
    visited::Bool

    Vertex() = new()
end

type VertexException <: Exception end
type EdgeException <: Exception end
type DegeneracyException <: Exception end

function show(io::IO, vert::Vertex)
    println("Vertex:")
    println("\tMem:", pointer_from_objref(vert))
    println("\tLocation:",vert.location)
    isdefined(vert,:next) ? println("\tNext:",pointer_from_objref(vert.next)):
    isdefined(vert,:prev) ? println("\tPrev:",pointer_from_objref(vert.prev)):
    isdefined(vert,:nextpoly) ? println("\tNextPoly:",pointer_from_objref(vert.nextpoly)):
    isdefined(vert,:neighbor) ? println("\tNeighbor:",pointer_from_objref(vert.neighbor)):
    println("\tIntersect:",vert.intersect)
    println("\tEntry:",vert.entry)
    println("\tVisited:",vert.visited)
end

type Polygon
    start::Vertex

    Polygon() = new()
end

Base.start(m::Polygon) = (m.start, false)
function Base.next(m::Polygon, state::(Vertex, Bool))
    if is(m.start, state[1])
        return (state[1], (state[1].next, true))
    else
        return (state[1], (state[1].next, state[2]))
    end
end
Base.done(m::Polygon, state::(Vertex, Bool)) = (state[2] && is(m.start, state[1]))

function length(p::Polygon)
    n = 0
    for i in p
        n += 1
    end
    n
end


function show(io::IO, p::Polygon)
    println("A Wild Porygon Appeared:")
    i = 1
    for vert in p
        print(i, " ")
        show(io, vert)
        i = i + 1
    end
end

function push!(p::Polygon, v::Vertex)
    if !isdefined(p, :start)
        p.start = v
        v.prev = v
        v.next = v
    else
        v.next = p.start
        v.prev = p.start.prev
        p.start.prev.next = v
        p.start.prev = v
    end
end

function Vertex(x, a::Vertex, b::Vertex)
    v = Vertex()
    v.location = Vector2(x)
    v.intersect = false
    v.entry = true
    v.visited = false
    v.next = a
    v.prev = b
    return v
end

function Vertex(x)
    v = Vertex()
    v.location = Vector2(x)
    v.intersect = false
    v.entry = true
    v.visited = false
    return v
end

function Vertex(s::Vertex, c::Vertex, location::Vector2)
    # Insert a vertex between s and c at location
    v = Vertex(location)
    v.next = c
    v.prev = s
    s.next = v
    c.prev = v
    return v
end

function Vertex(s::Vertex, c::Vertex, alpha::Float64)
    # Insert a vertex between s and c at alpha from s
    location = s.location + alpha*(c.location-s.location)
    v = Vertex(s, c, location)
    return v
end

function unprocessed(p::Polygon)
    for v in p
        if !v.visited && v.intersect
            return true
        end
    end
    return false
end

function isinside(v::Vertex, poly::Polygon)
    # See: http://www.sciencedirect.com/science/article/pii/S0925772101000128
    # "The point in polygon problem for arbitrary polygons"
    # An implementation of Hormann-Agathos (2001) Point in Polygon algorithm
    c = false
    r = v.location
    detq(q1,q2) = (q1[1]-r[1])*(q2[2]-r[2])-(q2[1]-r[1])*(q1[2]-r[2])
    for q1 in poly
        q2 = q1.next
        if q1.location == r
            throw(VertexException())
        end
        if q2.location[2] == r[2]
            if q2.location[1] == r[1]
                throw(VertexException())
            elseif (q1.location[2] == r[2]) && ((q2.location[1] > r[1]) == (q1.location[1] < r[1]))
                throw(EdgeException())
            end
        end
        if (q1.location[2] < r[2]) != (q2.location[2] < r[2]) # crossing
            if q1.location[1] >= r[1]
                if q2.location[1] > r[1]
                    c = !c
                elseif ((detq(q1.location,q2.location) > 0) == (q2.location[2] > q1.location[2])) # right crossing
                    c = !c
                end
            elseif q2.location[1] > r[1]
                if ((detq(q1.location,q2.location) > 0) == (q2.location[2] > q1.location[2])) # right crossing
                    c = !c
                end
            end
        end
    end
    return c
end

function isneighbor(sv, cv)
    sv_neighbor = (isdefined(sv, :neighbor) && sv.neighbor != cv && sv.neighbor != cv.next) || !isdefined(sv, :neighbor)
    svn_neighbor = (isdefined(sv.next, :neighbor) && sv.next.neighbor != cv && sv.next.neighbor != cv.next) || !isdefined(sv.next, :neighbor)
    if sv_neighbor && svn_neighbor
        return false
    end
    return true
end

function phase1!(subject::Polygon, clip::Polygon)
    sv = subject.start
    while true
        cv = clip.start
        while true
            if !isneighbor(sv, cv)
                intersect, a, b = intersection(sv, sv.next, cv, cv.next)
                if intersect
                    i1 = Vertex(sv, sv.next, a)
                    i2 = Vertex(cv, cv.next, i1.location)
                    i1.intersect = true
                    i2.intersect = true
                    i1.neighbor = i2
                    i2.neighbor = i1
                end
            end
            if is(cv.next, clip.start)
                break
            end
            cv = cv.next
        end
        if is(sv.next, subject.start)
            break
        end
        sv = sv.next
    end
end

function phase2!(subject::Polygon, clip::Polygon)
    status = false
    sv = subject.start
    if isinside(sv, clip)
        status = false
    else
        status = true
    end
    for sv in subject
        if sv.intersect
            sv.entry = status
            status = !status
        else
            sv.entry = status
        end
    end
end

function intersection(subject::Polygon, clip::Polygon)
    phase1!(subject, clip)

    phase2!(subject, clip)
    phase2!(clip, subject)

    results = Polygon[]
    numpoly = 1
    while unprocessed(subject)
        current = subject.start
        while true
            if current.intersect && !current.visited
                break
            end
            current.visited = true
            current = current.next
        end
        current.visited = true
        push!(results, Polygon())
        push!(results[numpoly], Vertex(current.location))
        start = current.location
        while true
            if current.entry
                while true
                    current = current.next
                    push!(results[numpoly], Vertex(current.location))
                    current.visited = true
                    if current.intersect
                        break
                    end
                end
            else
                while true
                    current = current.prev
                    push!(results[numpoly], Vertex(current.location))
                    current.visited = true
                    if current.intersect
                        break
                    end
                end
            end
            if current.location == start
                break
            else
                current = current.neighbor
                current.visited = true
            end
        end
        numpoly = numpoly + 1
    end
    return results
end

function intersection(sv::Vertex, svn::Vertex, cv::Vertex, cvn::Vertex)
    s1 = sv.location
    s2 = svn.location
    c1 = cv.location
    c2 = cvn.location

    den = (c2[2] - c1[2]) * (s2[1] - s1[1]) - (c2[1] - c1[1]) * (s2[2] - s1[2])
    if den == 0.0
        return false, 0.0, 0.0
    end
    a = ((c2[1] - c1[1]) * (s1[2] - c1[2]) - (c2[2] - c1[2]) * (s1[1] - c1[1])) / den
    b = ((s2[1] - s1[1]) * (s1[2] - c1[2]) - (s2[2] - s1[2]) * (s1[1] - c1[1])) / den

    if (0.0 < a < 1.0) && (0.0 < b < 1.0)
        return true, a, b
    elseif ((a in [0.0,1.0]) && (0.0 <= b <= 1.0)) || ((b in [0.0,1.0]) && (0.0 <= a <= 1.0))
        throw(DegeneracyException())
    else
        return false, 0.0, 0.0
    end
end

end # module
