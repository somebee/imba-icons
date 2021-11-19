import fs from 'fs'
import np from 'path'
import {optimize} from 'svgo'

let out = ""

def datauri input
	input = input.split("\n").map(do $1.trim!).join('')
	input = input.replace(/currentColor/g,'#3b82f6')
	return 'data:image/svg+xml;utf8,' + global.encodeURIComponent(input)


let files = fs.readdirSync('./sources')
console.log files
for src in files
	let body = fs.readFileSync("./sources/{src}",'utf8')
	let optim = optimize(body, multipass: true)
	let name = src.replace(/\.svg$/,'').replace(/[-\.]/g,'Ξ')
	console.log src, body.length,optim.data.length

	if name.match(/^(export|tag|if|else|const|var|let|const)$/)
		name = name + "Ξicon"

	# if src == 'triangle-up.svg'
	# 	console.log body
	# 	console.log optim.data

	# out += "/** "
	
	# let base = global.btoa(optim.data)
	let doc = "![]({datauri(optim.data)}|width=120,height=120)"
	# out += "/** {doc} */"
	out += "# {doc}\n"
	out += "export const {name} = import('./assets/codicons/{src}')\n\n"
	# out += "export \{default as {name}\} from './assets/codicons/{src}'\n"

console.log out
fs.writeFileSync('./index.imba',out)
	