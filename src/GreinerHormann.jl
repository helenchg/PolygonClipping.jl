module GreinerHormann

import Base.show
import Base.push!
using Debug
using ImmutableArrays

type Vertex
    location::Vector2{Float64}
    next
    prev
    nextpoly
    intersect::Bool
    entry::Bool
    neighbor
    visited::Bool

    Vertex(x) = new(Vector2(x), nothing, nothing, nothing, false, true, nothing, false)
end

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

    Polygon() = new(nothing, nothing)
end

function show(io::IO, p::Polygon)
    vert = p.start
    println("A Wild Porygon Appeared:")
    i = 1
    while vert != nothing
        print(i, " ")
        show(io, vert)
        i = i + 1
        vert = vert.next
    end
end

function push!(p::Polygon, v::Vertex)
    if p.start == nothing
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
    println("added :", v.location)
end

function Vertex(s::Vertex, c::Vertex, alpha::Float64)
    # Insert a vertex between s and c at alpha from s
    location = s.location + alpha*(c.location-s.location)
    a = Vertex(location)
    s.next = a
    c.prev = a
    a.next = c
    a.prev = s
    return a
end

function Vertex(s::Vertex, c::Vertex, location::Vector2{Float64})
    # Insert a vertex between s and c at location
    a = Vertex(location)
    s.next = a
    c.prev = a
    a.next = c
    a.prev = s
    return a
end

function unprocessed(p::Polygon)
    v = p.start
    while v.next != nothing
        if !v.visited && v.intersect
            return true
        end
        v = v.next
    end
    return false
end

function isinside(v::Vertex, p::Polygon)
    # See: http://www.sciencedirect.com/science/article/pii/S0925772101000128
    # "The point in polygon problem for arbitrary polygons"
    # An implementation of Hormann-Agathos (2001) Point in Polygon algorithm
    c = false
    r = v.location
    q1 = p.start
    if q1.location == r
        error("Vertex case")
        return
    end
    q2 = q1.next
    while q2 != nothing
        if q2.location[2] == r[2]
            if q2.location[1] == r[1]
                error("Vertex case")
                return
            elseif (q1.location[2] == r[2]) && ((q2.location[1] > r[1]) == (q1.location[1] < r[1]))
                error("Edge case")
                return
            end
        end
        if (q1.location[2] < r[2]) != (q2.location[2] < r[2])
            if q1.location[1] >= r[1]
                if q2.location[1] > r[1]
                    c = !c
                elseif ((det([q1.location q2.location]) > 0) == (q2.location[2] > q1.location[2]))
                    c = !c
                end
            elseif q2.location[1] > r[1]
                if ((det([q1.location q2.location]) > 0) == (q2.location[2] > q1.location[2]))
                    c = !c
                end
            end
        end
        q1 = q1.next
        q2 = q2.next
    end
    return c
end

function phase1!(subject::Polygon, clip::Polygon)
    sv = subject.start
    while sv.next != nothing
        cv = clip.start
        while cv.next != nothing
            intersect, a, b = intersection(sv, sv.next, cv, cv.next)
            if intersect
                println(a,b)
                println(cv, cv.next)
                println(sv, sv.next)
                i1 = Vertex(sv, sv.next, a)
                i2 = Vertex(cv, cv.next, i1.location)
                i1.intersect = true
                i2.intersect = true
                i1.neighbor = i2
                i2.neighbor = i1
            else
                cv = cv.next
            end
        end
        sv = sv.next
    end
end

function clip(subject::Polygon, clip::Polygon)
    # Phase 1
    phase1!(subject, clip)

    println(subject)
    println(clip)

    # Phase 2
    status = false
    sv = subject.start
    if isinside(sv, clip)
        println("subject Is inside")
        status = false
    else
        status = true
    end
    while sv != nothing
        if sv.intersect
            sv.entry = status
            status = !status
        else
            sv.entry = status
        end
        sv = sv.next
    end

    status = false
    cv = clip.start
    if isinside(cv, subject)
        println("clip Is inside")
        status = false
    else
        status = true
    end
    while cv != nothing
        if cv.intersect
            cv.entry = status
            status = !status
        else
            cv.entry = status
        end
        cv = cv.next
    end

    #println(subject)
    #println(clip)

    # phase 3
    results = Polygon[]
    numpoly = 1
    while unprocessed(subject)
        current = subject.start
        while current.next != nothing
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
        println(current.location)
        while true
            println("Skip:", current.location)
            if current.entry
                current = current.next
                println("Next:",current.location)
                push!(results[numpoly], Vertex(current.location))
                current.visited = true
                while !current.intersect
                    println("Next loop:",current.location)
                    current = current.next
                    push!(results[numpoly], Vertex(current.location))
                    current.visited = true
                end
            else
                current = current.prev
                println("Prev:",current.location)
                push!(results[numpoly], Vertex(current.location))
                current.visited = true
                while !current.intersect
                    println("Prev:",current.location)
                    current = current.prev
                    push!(results[numpoly], Vertex(current.location))
                    current.visited = true
                end
            end
            current.visited = true
            current = current.neighbor
            println("loop:", current.location)
            if current.location == start
                break
            else
                current.visited = true
                current = current.neighbor
            end
        end
        numpoly = numpoly + 1
    end

    println(subject)
    println(clip)
    return results
end


function intersection(sv, svn, cv, cvn)
    s1 = sv.location
    s2 = svn.location
    c1 = cv.location
    c2 = cvn.location

    den = (c2[2] - c1[2]) * (s2[1] - s1[1]) - (c2[1] - c1[1]) * (s2[2] - s1[2])
    if den == 0
        return false, 0, 0
    end
    a = ((c2[1] - c1[1]) * (s1[2] - c1[2]) - (c2[2] - c1[2]) * (s1[1] - c1[1])) / den
    b = ((s2[1] - s1[1]) * (s1[2] - c1[2]) - (s2[2] - s1[2]) * (s1[1] - c1[1])) / den

    if ((a == 1 || a == 0) && (0 <= b <= 1)) || ((b == 1 || b == 0) && (0 <= a <= 1))
        #error("Degenerate case between:", s1, s2, " and ", c1, c2, " got a:", a, " b:", b)
        return false, 0, 0
    elseif (0 < a < 1) && (0 < b < 1)
        return true, a, b
    else
        return false, 0, 0
    end
end


export Vertex, Polygon, push!, clip, intersection, isinside, show, unprocessed, phase1!
end # module
