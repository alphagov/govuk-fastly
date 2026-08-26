FROM public.ecr.aws/lts/ubuntu:22.04_stable

# See https://github.com/nodesource/distributions/wiki/Repository-Manual-Installation for node install instructions
RUN apt-get update && \
  apt-get install -y curl gpg && \
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
  echo 'Types: deb\n\
URIs: https://deb.nodesource.com/node_18.x/\n\
Suites: nodistro\n\
Components: main\n\
Signed-By: /etc/apt/keyrings/nodesource.gpg' > /etc/apt/sources.list.d/nodesource.sources && \
  apt-get update && \
  apt-get install -y --no-install-recommends python3 python3-pip nodejs && \
  rm -r /var/lib/apt/lists /var/cache/apt/archives && \
  npm install -g diff2html-cli@5

WORKDIR /function

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY lambda_function.py .

ENTRYPOINT [ "/usr/bin/python3", "-m", "awslambdaric" ]
CMD [ "lambda_function.handler" ]
