module GreinerHormann
import Base.show
import Base.push!

type Vertex
    location::Array{Float64}
    next
    prev
    nextpoly
    intersect::Bool
    entry::Bool
    neighbor
    alpha::Float64

    Vertex(x) = new(x, None, None, None, false, true, None, 0.0)
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
    print("Polygon:")
    while vert != None
        println("Vertex:")
        println("\tMem:", pointer_from_objref(vert))
        println("\tLocation:",vert.location)
        println("\tNext:",pointer_from_objref(vert.next))
        println("\tPrev:",pointer_from_objref(vert.prev))
        println("\tNextPoly:",pointer_from_objref(vert.nextpoly))
        println("\tNeighbor:",pointer_from_objref(vert.neighbor))
        println("\tIntersect:",vert.intersect)
        println("\tEntry:",vert.entry)
        println("\tAlpha:",vert.alpha)
        vert = vert.next
    end
    print("")
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
    while q2 != None
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

function clip(subject::Polygon, clip::Polygon)
    # Phase 1
    sv = subject.start
    cv = clip.start
    while sv.next != None
        while cv.next != None
            println("finding intersection")
            intersect, a, b = intersection(sv, sv.next, cv, cv.next)
            println(intersect, a, b)
            if intersect
                i1 = Vertex(cv, cv.next, a)
                i2 = Vertex(sv, sv.next, b)
                i1.intersect = true
                i2.intersect = true
                i1.neighbor = i2
                i2.neighbor = i1
                cv = i1.next # make sure we hop over the vertex we just inserted
            else
                cv = cv.next
            end
        end
        sv = sv.next
    end

    # Phase 2
    status = false
    if isinside(subject.start, clip)
        status = false
    else
        status = true
    end
    sv = subject.start
    while sv.next != None
        if sv.intersect
            sv.entry = status
            status = !status
        end
        sv = sv.next
    end

    status = false
    if isinside(clip.start, subject)
        status = false
    else
        status = true
    end
    cv = clip.start
    while cv.next != None
        if cv.intersect
            cv.entry = status
            status = !status
        end
        cv = cv.next
    end

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

    return true, a, b

end


export Vertex, Polygon, push!, clip, intersection, isinside, show
end # module
