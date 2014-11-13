import os, socket, redis
from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello():
    return "\n".join([
    	'<div style="text-align: center; font-size: 128px;">Hello World!</div>',
    	'<div style="text-align: center; font-size: 64px;">{0}</div>\n'.format(socket.gethostname())])

@app.route("/counter")
def counter():
	try:
		count = redis.StrictRedis(host=os.environ.get('REDIS', "localhost")).incr("counter")
	except:
		count = "redis not found"
	return "\n".join([
    	'<div style="text-align: center; font-size: 128px;">{0}</div>'.format(count),
    	'<div style="text-align: center; font-size: 64px;">{0}</div>\n'.format(socket.gethostname())])	

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)