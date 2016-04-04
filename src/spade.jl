typealias Item Char
typealias Id Int64
# a Sequence is an ordered list of events (N.B. time removed)
typealias Sequence Vector{Vector{Item}}

type SequenceDBRow
    sid::Id #sequence id
    eid::Id #event id (or time)
    items::Vector{Item} #items in the event
end

type SequenceDB
    rows::Vector{SequenceDBRow}
end

function prepareSampleDB(filename)
    getitems = function(itemstr::AbstractString)
        filter(c->c!=' ',collect(strip(itemstr)))::Vector{Item}
    end
    parseline = function(dblinestr)
        arr = split(dblinestr,',')
        SequenceDBRow(parse(Id,arr[1]), parse(Id,arr[2]), getitems(arr[3]))
    end
    rawdata = readlines(open(filename))
    map(parseline,rawdata[2:end])
end

# accumulates all the occurrences of a given atom(item) into a list
# TODO create a joiner of two id_list dictionaries... then parallelize
function getidlists(rows::Vector{SequenceDBRow})
    idlists = Dict{Item,Vector{Tuple{Id,Id}}}()
    for row in rows, item in row.items
        idlists[item] = push!(get(idlists,item,[]),(row.sid,row.eid))
    end
    return idlists
end

function frequent1sequences(sequencedb::SequenceDB,min_sup::Int64)
    # a sequence is frequent if it appears in more than min_sup sequences
    idlists = getidlists(sequencedb.rows)
    countsids = function(list::Vector{Tuple{Id,Id}})
        length(unique(map(t->t[1],list)))
    end
    frequencies::Dict{Item,Int64} = Dict([(k,countsids(v)) for (k,v) in idlists])
    filter((k,v)-> v>min_sup, frequencies)
end

function horizontaldb(sequence_db::SequenceDB)
    horizdb = Dict{Id,Vector{Tuple{Item,Id}}}()
    for row in sequence_db.rows, item in row.items
        horizdb[row.sid]=push!(get(horizdb,row.sid,[]), (item,row.eid))
    end
    return horizdb
end




function find2sequences(ts::Vector{Tuple{Item,Id}})
    s = Set{Sequence}()
    for i=1:length(ts), j=1:length(ts)
        if i!=j
            if ts[i][1]!=ts[j][1] # exclude same item
                if ts[i][2] <= ts[j][2] # only consider subsequent-in-time pairs
                    if ts[i][2]==ts[j][2]  # same event
                        # N.B. we assume lexographical order on items within event
                        push!(s,Vector[sort([ts[i][1],ts[j][1]])])
                    else
                        push!(s,Vector[[ts[i][1]],[ts[j][1]]])
                    end
                end
            end
        end
    end
    return s
end

