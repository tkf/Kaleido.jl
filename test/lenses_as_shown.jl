[
    PropertyBatchLens(:a, :b, :c)
    KeyBatchLens(:a, :b, :c)
    IndexBatchLens(:a, :b, :c)
    MultiLens(((@lens _.x), (@lens _[1])))
    MultiLens((a = (@lens _.x), b = (@lens _[1])))
    BijectionLens(exp, log)
    MultiLens((BijectionLens(exp, log), BijectionLens(log, exp)))
]
