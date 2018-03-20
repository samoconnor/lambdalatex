import os
import subprocess
import base64

def main(event, context):
    
    # Write input to "document.tex"...
    with open('/tmp/document.tex', 'w') as f:
        f.write(event["input"])

    os.environ['PATH'] += ":/var/task/texlive/2017/bin/x86_64-linux/"
    os.environ['HOME'] = '/tmp/'

    # Run pdflatex...
    r = subprocess.run(["/var/task/texlive/2017/bin/x86_64-linux/pdflatex",
                        "-interaction=batchmode",
                        "-output-directory=/tmp",
                        "/tmp/document.tex"],
                       stdout=subprocess.PIPE,
                       stderr=subprocess.STDOUT)
    print(r.stdout.decode('utf_8'))

    # Read "document.pdf"...
    with open('/tmp/document.pdf', 'rb') as f:
        pdf = f.read()

    # Return base64 encoded pdf and stdout log from pdflaxex...
    return {
        "output": base64.b64encode(pdf).decode('ascii'),
        "stdout": r.stdout.decode('utf_8')
    }
