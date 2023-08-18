FROM public.ecr.aws/lts/ubuntu:22.04_stable

RUN apt update && \
  apt install -y --no-install-recommends python3 python3-pip npm && \
  rm -r /var/lib/apt/lists /var/cache/apt/archives && \
  npm install -g diff2html-cli@5.2.9

WORKDIR /function

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY lambda_function.py .

ENTRYPOINT [ "/usr/bin/python3", "-m", "awslambdaric" ]
CMD [ "lambda_function.handler" ]
