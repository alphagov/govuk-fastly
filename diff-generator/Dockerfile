FROM public.ecr.aws/lts/ubuntu:22.04_stable

RUN apt update; apt install -y curl gpg; \
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | gpg --dearmor > /usr/share/keyrings/nodesource.gpg;  \
  echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x jammy main" | tee /etc/apt/sources.list.d/nodesource.list; \
  apt update; \
  apt install -y --no-install-recommends python3 python3-pip nodejs; \
  rm -r /var/lib/apt/lists /var/cache/apt/archives; \
  npm install -g diff2html-cli@5

WORKDIR /function

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY lambda_function.py .

ENTRYPOINT [ "/usr/bin/python3", "-m", "awslambdaric" ]
CMD [ "lambda_function.handler" ]
