module PolygonClipping

import Base.show
import Base.push!
import Base.length
using ImmutableArrays

export Vertex, Polygon, push!, intersection, isinside, show, unprocessed,
       VertexException, EdgeException, DegeneracyException, length, remove, infill

type Vertex
    location::Vector2{Float64}
    next::Union{Vertex, Void}
    prev::Union{Vertex, Void}
    nextpoly::Union{Vertex, Void}
    intersect::Bool
    entry::Bool
    neighbor::Union{Vertex, Void}
    visited::Bool
    alpha::Float64

    Vertex(x) = new(Vector2(x), nothing, nothing, nothing, false, true, nothing, false, 0.0)
    Vertex(x::Float64,y::Float64) = new(Vector2(x,y), nothing, nothing, nothing, false, true, nothing, false, 0.0)
    Vertex(x::Real,y::Real) = new(Vector2(convert(Float64,x),convert(Float64,y)), nothing, nothing, nothing, false, true, nothing, false, 0.0)
    Vertex(x::Vector2, a::Vertex, b::Vertex) = new(x, a, b, nothing, false, true, nothing, false, 0.0)
end

type VertexException <: Exception end
type EdgeException <: Exception end
type DegeneracyException <: Exception end

function show(io::IO, vert::Vertex)
    println("Vertex:")
    println("\tMem:", pointer_from_objref(vert))
    println("\tLocation:",vert.location)
    println("\tNext:",pointer_from_objref(vert.next))
    println("\tPrev:",pointer_from_objref(vert.prev))
    println("\tNextPoly:",pointer_from_objref(vert.nextpoly))
    println("\tNeighbor:",pointer_from_objref(vert.neighbor))
    println("\tIntersect:",vert.intersect)
    println("\tEntry:",vert.entry)
    println("\tVisited:",vert.visited)
end

type Polygon
    start::Union{Vertex, Void}

    Polygon() = new(nothing)
end

Base.start(m::Polygon) = (m.start, false)
function Base.next(m::Polygon, state::Tuple{Vertex, Bool})
    if is(m.start, state[1])
        return (state[1], (state[1].next, true))
    else
        return (state[1], (state[1].next, state[2]))
    end
end
Base.done(m::Polygon, state::Tuple{Vertex, Bool}) = (is(m.start, state[1]) && state[2])
Base.done(m::Polygon, state::Tuple{Void, Bool}) = true

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
    if p.start == nothing
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

function Vertex(s::Vertex, c::Vertex, alpha::Float64)
    # Insert a vertex between s and c at alpha from s
    location = s.location + alpha*(c.location-s.location)
    a = Vertex(location, c, s)
    a.alpha = alpha
    s.next = a
    c.prev = a
    return a
end

function Vertex(s::Vertex, c::Vertex, location::Vector2{Float64})
    # Insert a vertex between s and c at location
    a = Vertex(location, c, s)
    s.next = a
    c.prev = a
    return a
end

function unprocessed(p::Polygon)
    for v in p
        if !v.visited && v.intersect
            return true
        end
    end
    return false
end

function remove(v::Vertex, poly::Polygon)
    if is(v, poly.start)
        if is(v.next, v)
            poly.start = nothing
            v.next = nothing
            v.prev = nothing
            return
        else
            poly.start = v.next
        end
    end
    v.next.prev = v.prev
    v.prev.next = v.next
    v.next = nothing
    v.prev = nothing
    return
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

function phase1!(subject::Polygon, clip::Polygon)
    sv = subject.start
    svn = sv.next
    while true
        cv = clip.start
        cvn = cv
        while true
            # Skip ahead to next non-inserted vertex
            while true
                cvn = cvn.next
                if !cvn.intersect
                    break
                end
            end

            intersect, a, b = intersection(sv, svn, cv, cvn)
            if intersect
                # Find where to insert vertices
                av = sv
                bv = cv
                while av.alpha <= a && !is(av, svn)
                    av = av.next
                end
                while bv.alpha <= b && !is(bv, cvn)
                    bv = bv.next
                end

                location = sv.location + a*(svn.location-sv.location)
                i1 = Vertex(av.prev, av, location)
                i2 = Vertex(bv.prev, bv, location)
                i1.alpha = a
                i2.alpha = b
                i1.intersect = true
                i2.intersect = true
                i1.neighbor = i2
                i2.neighbor = i1
            end
            if is(cvn, clip.start)
                break
            end
            cv = cvn
        end
        if is(svn, subject.start)
            break
        end
        sv = svn
        # Skip ahead to next non-inserted vertex
        while true
            svn = svn.next
            if !svn.intersect
                break
            end
        end
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
    search_start = subject.start
    while true
        current = search_start
        while true
            if current.intersect
                push!(results, Polygon())
                push!(results[numpoly], Vertex(current.location))
                break
            end
            current = current.next
            if current == subject.start
                return results
            end
        end
        start = current
        first_change = true
        while true
            if current.entry
                while true
                    current = current.next
                    push!(results[numpoly], Vertex(current.location))
                    if current.intersect
                        current.intersect = false
                        break
                    end
                end
            else
                while true
                    current = current.prev
                    push!(results[numpoly], Vertex(current.location))
                    if current.intersect
                        current.intersect = false
                        break
                    end
                end
            end
            if current.neighbor == start
                break
            elseif first_change
                first_change = false
                search_start = current
            end
            current = current.neighbor
            current.intersect = false
        end
        numpoly = numpoly + 1
    end
    return results
end

function infill(subject::Polygon, clip::Polygon)
    if subject.start == nothing || clip.start == nothing
        return
    end
    phase1!(subject, clip)

    phase2!(subject, clip)
    phase2!(clip, subject)

    results = Polygon[]
    numpoly = 1
    while unprocessed(subject)
        current = subject.start
        nonintersections = 1
        while true
            if current.intersect
                if !current.visited
                    current.visited = true
                    push!(results, Polygon())
                    newvert = Vertex(current.location)
                    newvert.intersect = true
                    push!(results[numpoly], newvert)
                    #current = current.neighbor
                    break
                end
            else
                nonintersections += 1
            end
            current.visited = true
            current = current.next
        end
        # we are going down the right-hand side of an intersection so our jogs are flipped
        flipped = false
        if nonintersections % 3 == 0
            flipped = true
        end
        start = current.location
        crossings = 1 # count first intersection
        traversing = true
        while traversing
            if current.entry
                while true
                    current = current.next
                    newvert = Vertex(current.location)
                    push!(results[numpoly], newvert)
                    current.visited = true
                    if current.intersect
                        newvert.intersect = true
                        break
                    end
                end
            else
                while true
                    current = current.prev
                    newvert = Vertex(current.location)
                    push!(results[numpoly], newvert)
                    current.visited = true
                    if current.intersect
                        newvert.intersect = true
                        break
                    end
                end
            end
            if current.neighbor.visited && current.intersect
                traversing = false
                # remove vertices that we inserted while traversing
                remove(results[numpoly].start.prev, results[numpoly])
                vert = results[numpoly].start.prev
                while !vert.intersect
                    vert_prev = vert.prev
                    remove(vert, results[numpoly])
                    vert = vert_prev
                end
                break
            end
            current = current.neighbor
            current.visited = true
            crossings = crossings + 1
            if flipped && crossings == 2
                current.entry = !current.entry
            end
            if !flipped && crossings == 4
                current.entry = !current.entry
                crossings = 0
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
