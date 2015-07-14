#!/usr/bin/env python3
import json

prompt = 'ilya@weave-01:~$ '

highlight = {
    'weave-01': 'red',
    'weave-02': 'red',
    'docker': 'red',
    'run': 'red',
    '--name': 'red',
    'hello': 'red',
    '-ti': 'red',
    'ubuntu': 'red',
    'netcat': 'red',
    '-lk': 'red',
    '1234': 'red',
    'Hello, Weave!\r\n': 'red',
    'export DOCKER_HOST=tcp://127.0.0.1:12375\r\n': 'red',
}

colours = {
    'red': '\033[91m',
}

def get_colour(k):
  return [0, colours[highlight[k]]]

def start_colour(x, o):
  return (x[1] + o, get_colour(x[0]))

def term_colour(x, o):
  l = len(x[0]) if x[2] else 1
  return (x[1] + l + o, [0, '\033[00m'])

for f in ['rec-weave-01.json', 'rec-weave-02.json']:
    with open(f) as json_data:
        tokens = []
        d = json.load(json_data)
        json_data.close()
        commands = d['stdout']
        word = ''
        word_start = 0
        for i,x in enumerate(commands):
            curr = x[1]
            if curr == prompt: continue
            elif curr != '\r\n' and curr != ' ' and len(curr) == 1:
                if word_start == 0:
                    word_start = i
                    word = curr
                else:
                    word += curr
            elif (curr == '\r\n' or curr == ' ') and word_start != 0:
                tokens.append((word, word_start, True))
                word_start = 0
            elif curr != '\r\n' and len(curr) > 1:
                tokens.append((curr, i, False))
         
        offset = 0
        for x in tokens:
            if x[0] in highlight.keys():
                commands.insert(*(start_colour(x, offset)))
                offset += 1
                commands.insert(*(term_colour(x, offset)))
                offset += 1
    
        d['commands'] = commands
    
        with open('fancy-' + f, 'w') as json_output:
            json_output.write(json.dumps(d))
            json_output.close()
