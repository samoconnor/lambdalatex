import os
import io
import shutil
import subprocess
import base64
import zipfile

def main(event, context):
    
    # Extract input ZIP file to /tmp/latex...
    shutil.rmtree("/tmp/latex", ignore_errors=True)
    os.mkdir("/tmp/latex")
    z = zipfile.ZipFile(io.BytesIO(base64.b64decode(event["input"])))
    z.extractall(path="/tmp/latex")

    r = subprocess.run(["ls", "-laR", "/tmp/latex"])

    os.environ['PATH'] += ":/var/task/texlive/2017/bin/x86_64-linux/"
    os.environ['HOME'] = '/tmp/'

    # Run pdflatex...
    r = subprocess.run(["/var/task/texlive/2017/bin/x86_64-linux/pdflatex",
                        "-interaction=batchmode",
                        "-output-directory=/tmp/latex",
                        "/tmp/latex/document.tex"],
                       stdout=subprocess.PIPE,
                       stderr=subprocess.STDOUT)
    print(r.stdout.decode('utf_8'))

    # Read "document.pdf"...
    with open('/tmp/latex/document.pdf', 'rb') as f:
        pdf = f.read()

    # Return base64 encoded pdf and stdout log from pdflaxex...
    return {
        "output": base64.b64encode(pdf).decode('ascii'),
        "stdout": r.stdout.decode('utf_8')
    }
