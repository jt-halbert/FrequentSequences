addprocs(Base.CPU_CORES-1)

@everywhere n = 1000000
isprime(1)
a = convert(SharedArray{Int64,1},[1:n;])
b = SharedArray(Bool,n)
println("$(nprocs())")
@time begin
    @sync @parallel for i=1:n
        b[i] = isprime(a[i])
    end
end;

@time begin
    a = [1:n;]
    b = falses(n)
    for i=1:n
        b[i] = isprime(a[i])
    end
end;
