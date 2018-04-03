import os
import io
import shutil
import subprocess
import base64
import zipfile

def lambda_handler(event, context):
    
    # Extract input ZIP file to /tmp/latex...
    shutil.rmtree("/tmp/latex", ignore_errors=True)
    os.mkdir("/tmp/latex")
    z = zipfile.ZipFile(io.BytesIO(base64.b64decode(event["input"])))
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

    # Read "document.pdf"...
    with open("document.pdf", "rb") as f:
        pdf = f.read()

    # Return base64 encoded pdf and stdout log from pdflaxex...
    return {
        "output": base64.b64encode(pdf).decode('ascii'),
        "stdout": r.stdout.decode('utf_8')
    }
