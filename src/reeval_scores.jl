function constructAdjMat(student_judge_tups,student_judge_cnts,unique_judges)
    njud = length(unique_judges)
    nstu = length(student_judge_tups)
    A = zeros(Int,njud,njud)
    
    for q = 1:nstu
        tup = student_judge_tups[q][1]
        cnt = student_judge_cnts[q]
        for k = 1:cnt
            jud_k = tup[k]
            kk = findfirst(unique_judges.==jud_k)
            for m = 1:cnt
                if k!=m
                    jud_m = tup[m]
                    mm = findfirst(unique_judges.==jud_m)
                    A[kk,mm] += 1
                end
            end
        end
    end
    return A
end

function constructMat(
        studentv,
        judgesv,
        scoresv,
        unique_judges,
        unique_student,
        student_judge_cnts,
        student_judge_tups,
        student_score_tups
    )
    
    nobs = length(scoresv)
    njud = length(unique_judges)

    A = zeros(nobs,njud)
    b = zeros(nobs);
    
    for i in 1:nobs
        stu = studentv[i]
        jud = judgesv[i]
        sco = scoresv[i]
        j = findfirst(unique_judges.==jud)
        q = findfirst(unique_student.==stu)
        cnt = student_judge_cnts[q]
        tup = student_judge_tups[q][1]
        stup = student_score_tups[q][1]

        A[i,j] += 1
        b[i] = sco

        for k in 1:cnt
            jud_j = tup[k]
            jj = findfirst(unique_judges.==jud_j)
            A[i,jj] += -1/cnt
            b[i] += -stup[k]/cnt
        end
    end
    return A, b
end

function safe_inv(s;thresh=1e-12)
    if s>thresh
        return 1/s
    else
        return 0
    end
end

function correct_scores(
        unique_judges,
        unique_student,
        student_judge_cnts,
        student_judge_tups,
        stu_scores_mean,
        judge_offsets
        )

    stu_scores_mean_out = copy(stu_scores_mean)
    
    for i in 1:length(unique_student)
        cnt = student_judge_cnts[i]
        tup = student_judge_tups[i][1]
        for k in 1:cnt
            jud_j = tup[k]
            jj = findfirst(unique_judges.==jud_j)
            stu_scores_mean_out[i] += -judge_offsets[jj]/cnt
        end
    end
    return stu_scores_mean_out
end

function reeval_scores(students, judges, scores; covar_on=false)
    
    df = DataFrame(
        student = students, 
        judges = judges, 
        scores = scores
        )

    gdf = groupby(df, :student)
    df_stu = sort(combine(gdf, [nrow => :count, :scores => mean,:judges => tuple, :scores => tuple]),:student)
    gdf = groupby(df, :judges)
    df_jud = sort(combine(gdf, [nrow => :count, :scores => mean,:student => tuple, :scores => tuple]),:judges);
    
    studentv = df.student
    judgesv = df.judges
    scoresv = df.scores

    unique_judges = df_jud.judges
    unique_student = df_stu.student
    student_judge_cnts = df_stu.count
    student_judge_tups = df_stu.judges_tuple
    student_score_tups = df_stu.scores_tuple
    stu_scores_mean = df_stu.scores_mean;
    
    A, b = constructMat(
        studentv,
        judgesv,
        scoresv,
        unique_judges,
        unique_student,
        student_judge_cnts,
        student_judge_tups,
        student_score_tups
    )
    
    U, S, V = svd(A'*A)
    judge_offsets = V*(Diagonal(safe_inv.(S))*(U'*(A'*b)))
    
    if covar_on
        judcovar = V*(Diagonal(safe_inv.(S))*U')
        judvar = diag(judcovar)
    else
        judcovar = NaN
        judvar = dropdims(sum(V'.*(Diagonal(safe_inv.(S))*U'),dims=1),dims=1)
    end
    
    cscores = correct_scores(
        unique_judges,
        unique_student,
        student_judge_cnts,
        student_judge_tups,
        stu_scores_mean,
        judge_offsets
    )
    
    df_stu.cscores = cscores
    
    Admat = constructAdjMat(student_judge_tups,student_judge_cnts,unique_judges)
    g = SimpleGraph(Admat)
    cc = connected_components(g)
    
    df_jud.judge_offsets = judge_offsets
    df_jud.judvar = judvar
    
    println("Block\t Judges\t Students\t Mean Score")
    for i=1:length(cc)
        ljud = length(cc[i])
        lstu = length(unique(vcat(map(x->x[1],df_jud.student_tuple[cc[i]])...)))
        mscore = mean(df_jud.scores_mean[cc[i]])
        println("$i \t $ljud \t $lstu \t\t $mscore")
    end
    
    if covar_on
        return df_stu, df_jud, judcovar
    else
        return df_stu, df_jud
    end
    
end