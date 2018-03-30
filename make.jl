module MakeLatexLambda

using JSON
using AWSCore
using AWSS3
using AWSLambda

function all()
    build()
    zip()
    deploy()
    test()
end


# Build docker image from Dockerfile.
function build()
    run(`docker build -t octech/lambdalatex .`)
end


# Create Lambda deployment .ZIP file from docker image.
function zip()
    rm("latexlambda.zip", force=true)
    run(`docker run --rm -it -v $(pwd()):/var/host octech/lambdalatex zip --symlinks -r -9 /var/host/latexlambda.zip .`)
end


# Deploy .ZIP file to Lambda.
function deploy()
    AWSCore.set_debug_level(2)
    aws = AWSCore.default_aws_config()
    n = AWSCore.aws_account_number(aws)
    aws[:lambda_bucket] = "octech.latexlambda.deploy.$n"
    s3_create_bucket(aws[:lambda_bucket])
    s3_put(aws[:lambda_bucket], "latexlambda.zip", read("latexlambda.zip"))
    if lambda_configuration("latex") == nothing
        create_lambda(aws, "latex"; Runtime="python3.6",
                                    S3Key="latexlambda.zip")
    else
        update_lambda(aws, "latex"; S3Key="latexlambda.zip")
    end
end


# Docker image interactive shell.
function shell()
    run(`docker run --rm -it -v $(pwd()):/var/host octech/lambdalatex bash`)
end


# Test latex in local docker image.
function localtest()
    pycmd = """
        import lambda_main
        import json
        out = lambda_main.main({'input': '''
            $(escape_string(readstring("test_input.tex")))
        '''}, {})
        with open('/var/host/test_output.json', 'w') as f:
            f.write(json.dumps(out))
        """
    run(`docker run --rm -v $(pwd()):/var/host octech/lambdalatex python3 -c $pycmd`)
    out = JSON.parse(readstring("test_output.json"))
    write("test_output_local.pdf", base64decode(out["output"]))
    write("test_output_local.stdout", out["stdout"])
end


# Test latex on Lambda.
function test()
    out = invoke_lambda("latex"; input=readstring("test_input.tex"))
    write("test_output_lambda.pdf", base64decode(out[:output]))
    write("test_output_lambda.stdout", out[:stdout])
end


# Remove intermediate files.
function clean()
    rm("test_output.json", force=true)
    rm("test_output_local.stdout", force=true)
    rm("test_output_local.pdf", force=true)
    rm("test_output_lambda.stdout", force=true)
    rm("test_output_lambda.pdf", force=true)
    rm("latexlambda.zip", force=true)
end


if length(ARGS) == 0
    all()
else
    include_string("$(ARGS[1])()")
end


end # module MakeLatexLambda
