# Latex TeX Live for AWS Lambda

AWS Lambda imposes a 50MB limit on `.zip` deployment archives.
To reduce the size of Tex Live, most optional packages have been disabled in
`texlive.profile`. If you require additional packages you will have to
modify the `Dockerfile` to add the required packages to the
[`tlmgr install`](https://www.tug.org/texlive/pkginstall.html) list. 


## Prerequisites

 - Julia 0.6.2: https://julialang.org/downloads/
 - Docker Community Edition: https://www.docker.com/community-edition


## Installation

Download this repository:

    git clone https://github.com/samoconnor/lambdalatex.git


Configure AWS Credentials environment variables for your AWS account:

    AWS_ACCESS_KEY_ID=AKIAXXXXXXXXXXXXXXXX
    AWS_SECRET_ACCESS_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    AWS_DEFAULT_REGION=ap-southeast-2


Run the build script:

    julia make.jl

The build script will:
 - Create a local docker image `octech/lambdalatex` containing a small Tex Live
   installation.
 - Package the Tex Live installation into a `latexlambda.zip` file.
 - Deploy the `.zip` as an AWS Lambda Function named "latex".
 - Invoke the Lambda Function, passing `test_input.tex` as input and saving
   the output to `test_output_lambda.pdf`


## Interface

The input to the "latex" lambda function is a base-64 encoded .ZIP file
containing `document.tex` and any required supporting files (images etc).

    {
      "input": "JVBERi0xLjUKJdD ...",
    }

The output contains a base64 encoded PDF file and debug messages:

    {
      "output": "JVBERi0xLjUKJdD ...",
      "stdout": "This is pdfTeX, Version 3.14159265-2.6-1.40.18 ..."
    }


## Use

Using the AWS CLI:

```bash
$ aws lambda invoke --function-name latex --payload "{
      \"input\": \"$(base64 < input.zip)\"
    }" output.json
$ cat output.json
```


Using Julia:

```julia
using AWSLambda
using InfoZIP

z = base64encode(create_zip("document.tex" =>
                            """
                            \\documentclass[11pt,letterpaper]{article}
                            \\begin{document}
                            Hello World!
                            \\end{document}
                            """))

out = invoke_lambda("latex"; input=z)
write("test_output_lambda.pdf", base64decode(out[:output]))
write("test_output_lambda.stdout", out[:stdout])
```

    
