@testset "reeval_scores.jl" begin
    students = ["A","E","B","E","F","F","A","B","C","D","C","D"]
    judges = ["a","a","b","b","c","d","c","d","e","e","f","f"]
    scores = [1,6,3,7,7,7,4,5,8,8,8,8]
    gt = [4,5,8,8,9,7];
    
    df_stu, df_jud = reeval_scores(students, judges, scores);
    
    fname = tempname()*".csv"
    CSV.write(fname,sort(df_stu,:cscores,rev=true))
    
    @test sqrt.(sum((df_stu.cscores .- gt).^2)) ≈ 2.5
    
end