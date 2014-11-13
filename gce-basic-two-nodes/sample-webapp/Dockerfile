FROM ubuntu:trusty

RUN apt-get update && apt-get install -y python python-pip

ADD ./requirements.txt /requirements.txt
RUN pip install -r requirements.txt

ADD ./app.py /app.py

EXPOSE 5000
CMD ["/usr/bin/python", "/app.py"]