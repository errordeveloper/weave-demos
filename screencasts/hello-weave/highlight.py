import json

prompt = 'ilya@weave-01:~$ '

highlight = [
    ('weave-01', 'red'),
    ('weave-02', 'red'),
    ('docker', 'red'),
    ('run', 'red'),
    ('--name', 'red'),
    ('hello', 'red'),
    ('netcat', 'red'),
    ('-lk', 'red'),
    ('1234', 'red'),
    ('sudo curl -s -L git.io/weave -o /usr/local/bin/weave', 'red'),
    ('b4e40e4b4665a1ffa23f90eb3ab57c83ef243e64151bedc1501235df6e532e09\r\n', 'red'),
    ('Hello, Weave!\r\n', 'red'),
]

highlight_tokens = [t[0] for t in highlight]

tokens = []

colours = {
    'red': ('\033[91m', '\033[00m'),
}

for f in ['rec-weave-01.json', 'rec-weave-02.json']:
    with open(f) as json_data:
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
            if x[0] in highlight_tokens:
                commands.insert(x[1] + offset, [0, colours['red'][0]])
                offset += 1
                l = len(x[0]) if x[2] else 1
                commands.insert(x[1] + l + offset, [0, colours['red'][1]])
                offset += 1
    
        d['commands'] = commands
    
        with open('fancy-' + f, 'w') as json_output:
            json_output.write(json.dumps(d))
            json_output.close()
