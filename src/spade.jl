typealias Item Char
typealias Id Int64
# a Sequence is an ordered list of events (N.B. time removed)
typealias Sequence Vector{Vector{Item}}

type SequenceDBRow
    sid::Id #sequence id
    eid::Id #event id (or time)
    items::Vector{Item} #items in the event
end

type Atom
    sequence::Sequence
    idlist::Vector{Tuple{Id,Id}}
end

typealias SequenceDB Vector{SequenceDBRow}

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
function getidlists(rows::SequenceDB)
    idlists = Dict{Item,Vector{Tuple{Id,Id}}}()
    for row in rows, item in row.items
        idlists[item] = push!(get(idlists,item,[]),(row.sid,row.eid))
    end
    return idlists
end

function frequent1sequences(sequencedb::SequenceDB,min_sup::Int64)
    # a sequence is frequent if it appears in more than min_sup sequences
    idlists = getidlists(sequencedb)
    countsids = function(list::Vector{Tuple{Id,Id}})
        length(unique(map(t->t[1],list)))
    end
    frequencies::Dict{Item,Int64} = Dict([(k,countsids(v)) for (k,v) in idlists])
    filter((k,v)-> v>min_sup, frequencies)
end

function horizontaldb(sequencedb::SequenceDB)
    horizdb = Dict{Id,Vector{Tuple{Item,Id}}}()
    for row in sequencedb, item in row.items
        horizdb[row.sid]=push!(get(horizdb,row.sid,[]), (item,row.eid))
    end
    return horizdb
end

function potentialFreq2seqs(ts::Vector{Tuple{Item,Id}},frequentitems::Set{Item})
    s = Set{Sequence}()
    for i=1:length(ts), j=1:length(ts)
        if i!=j &&
            in(ts[i][1],frequentitems) && in(ts[j][1],frequentitems) &&
            ts[i][1]!=ts[j][1] && # exclude same item
            ts[i][2] <= ts[j][2]  # only consider subsequent-in-time pairs
            if ts[i][2]==ts[j][2]  # same event
                # N.B. we assume lexicographical order on items within event
                push!(s,Vector[sort([ts[i][1],ts[j][1]])])
            else
                push!(s,Vector[[ts[i][1]],[ts[j][1]]])
            end
        end
    end
    return s
end

function frequent2sequences(sequencedb::SequenceDB, frequentitems::Set{Item} , min_sup::Int64=1)
    horizdb = horizontaldb(sequencedb)
    frequencies = Dict{Sequence,Int64}()
    for (sid,ts) in horizdb
        for sequence in potentialFreq2seqs(ts,frequentitems)
            frequencies[sequence]=get(frequencies,sequence,0)+1
        end
    end
    filter((k,v)-> v>min_sup, frequencies)
end

function possiblepairs(seq1::Sequence, seq2::Sequence)
    # this assummes each is just a singleton for now
    a = seq1[1][1]
    b = seq2[1][1]
    return Vector[[a,b]],Vector[[a],[b]],Vector[[b],[a]]
end


a = Atom(Vector[['A']], idlists['A'])
d = Atom(Vector[['D']], idlists['D'])
out = Dict{Sequence,Vector{Tuple{Id,Id}}}()

for (s1,e1) in a.idlist, (s2,e2) in d.idlist
    if s1==s2 && e1==e2 && !in((s2,e2),get(out,Vector[sort(['A','B'])],[]))
        out[Vector[sort(['A','D'])]] = push!(get(out,Vector[sort(['A','D'])],[]), (s2,e2))
    end
    if s1==s2 && e1<e2 && !in((s2,e2),get(out,Vector[['A'],['D']],[]))
        out[Vector[['A'],['D']]] = push!(get(out,Vector[['A'],['D']],[]), (s2,e2))
    end
    if s1==s2 && e2<e1 && !in((s1,e1),get(out,Vector[['D'],['A']],[]))
        out[Vector[['D'],['A']]] = push!(get(out,Vector[['D'],['A']],[]), (s1,e1))
    end
end

function joinpairs(seq1::Sequence, seq2::Sequence)
    out = Dict{Sequence,Vector{Tuple{Id,Id}}}()
    # case event, event
    if length(seq1) == length(seq2) == 1
        p=seq1[1][1]
        a=seq1[1][2]
        b=seq2[1][2]
        
    end
    # case event, sequence
    if length(seq1)==1 && length(seq2)==2
        
    end
    # case sequence, sequence
    if length(seq1) == length(seq2) == 2
        
