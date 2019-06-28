import os
import shutil
import subprocess
from tempfile import NamedTemporaryFile, mkdtemp
from flask import Flask, request, send_file, Response
from werkzeug.exceptions import BadRequest
from flask_cors import CORS
app = Flask(__name__)
CORS(app)

MAX_SIZE = 2048

@app.route('/compile', methods=['POST'])
def compile():
    if request.content_length > MAX_SIZE:
        return Response("ERROR: exceeded max size of {} characters".format(MAX_SIZE), status=400, mimetype='text/plain')

    data = request.data
    tmpdir = mkdtemp()
    source_file = os.path.join(tmpdir, 'source.kit')
    output_file = os.path.join(tmpdir, 'output.js')
    output_log = os.path.join(tmpdir, 'stderr.out')

    try:
        with open(source_file, 'w') as f:
            f.write(str(data))

        with open(os.devnull, 'w') as devnull, open(output_log, 'w') as output:
            process = subprocess.Popen(
                ['timeout', '30', 'kitc', '--build-dir', tmpdir, '-q', '--build', 'none', '--host', 'emscripten', source_file, '-o', output_file, '-l', '-s', '-l', 'WASM=0', '-l', '-s', '-l', 'EXIT_RUNTIME=1'],
                stderr=output
            )
            process.communicate()

            if process.returncode:
                preamble = ''
                if process.returncode == 124:
                    preamble = 'Compiler timed out'
                elif 'macro' in data:
                    preamble = 'NOTE: macros are disabled in the playground\n\n'
                with open(output_log, 'r') as stderr:
                    return Response(preamble + stderr.read(), status=400, mimetype='text/plain')

        with open(output_file) as f:
            response = f.read()

        return response

    finally:
        shutil.rmtree(tmpdir)

if __name__ == '__main__':
    app.run(host = '0.0.0.0')
