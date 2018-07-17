import os
import io
import shutil
import subprocess
import base64
import zipfile
import boto3

def lambda_handler(event, context):
    
    # Extract input ZIP file to /tmp/latex...
    shutil.rmtree("/tmp/latex", ignore_errors=True)
    os.mkdir("/tmp/latex")

    print(event)

    if 'input_bucket' in event:
        r = boto3.client('s3').get_object(Bucket=event['input_bucket'],
                                          Key=event['input_key'])
        bytes = r["Body"].read()
    else:
        bytes = base64.b64decode(event["input"])

    z = zipfile.ZipFile(io.BytesIO(bytes))
    z.extractall(path="/tmp/latex")

    os.environ['PATH'] += ":/var/task/texlive/2017/bin/x86_64-linux/"
    os.environ['HOME'] = "/tmp/latex/"
    os.environ['PERL5LIB'] = "/var/task/texlive/2017/tlpkg/TeXLive/"

    os.chdir("/tmp/latex/")

    # Run pdflatex...
    r = subprocess.run(["latexmk",
                        "-verbose",
                        "-interaction=batchmode",
                        "-pdf",
                        "-output-directory=/tmp/latex",
                        "document.tex"],
                       stdout=subprocess.PIPE,
                       stderr=subprocess.STDOUT)
    print(r.stdout.decode('utf_8'))

    if "output_bucket" in event:
        boto3.client('s3').upload_file("document.pdf",
                                       event['output_bucket'],
                                       event['output_key'])
        return {
            "stdout": r.stdout.decode('utf_8')
        }

    else:
        # Read "document.pdf"...
        with open("document.pdf", "rb") as f:
            pdf = f.read()

        # Return base64 encoded pdf and stdout log from pdflaxex...
        return {
            "output": base64.b64encode(pdf).decode('ascii'),
            "stdout": r.stdout.decode('utf_8')
        }
