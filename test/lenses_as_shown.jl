[
    MultiLens(((@lens _.x), (@lens _[1])))
    BijectionLens(exp, log)
    MultiLens((BijectionLens(exp, log), BijectionLens(log, exp)))
]
