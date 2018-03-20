using JSON


if length(ARGS) < 1
    println("usage: julia make.jl [build|shell|test|clean]")
    exit(1)
end


if ARGS[1] == "build"
    run(`docker build -t latexlambda .`)
end

if ARGS[1] == "zip"
    rm("latexlambda.zip", force=true)
    run(`docker run --rm -it -v $(pwd()):/var/host latexlambda zip --symlinks -r -9 /var/host/latexlamba.zip .`)
end

if ARGS[1] == "shell"
    run(`docker run --rm -it -v $(pwd()):/var/host latexlambda bash`)
end


if ARGS[1] == "test"
    pycmd = """
        import lambda_main
        import json
        out = lambda_main.main({'input': '''
            $(escape_string(readstring("test_input.tex")))
        '''}, {})
        with open('/var/host/test_output.json', 'w') as f:
            f.write(json.dumps(out))
        """
    run(`docker run --rm -v $(pwd()):/var/host latexlambda python3 -c $pycmd`)
    out = JSON.parse(readstring("test_output.json"))
    write("test_output.pdf", base64decode(out["output"]))
    write("test_output.stdout", out["stdout"])
end


if ARGS[1] == "clean"
    rm("test_output.json", force=true)
    rm("test_output.stdout", force=true)
    rm("test_output.pdf", force=true)
    rm("latexlambda.zip", force=true)
end
