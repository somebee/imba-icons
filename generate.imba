import fs from 'fs'
import np from 'path'
import {optimize} from 'svgo'

def datauri input
	input = input.split("\n").map(do $1.trim!).join('')
	input = input.replace(/currentColor/g,'#3b82f6')
	return 'data:image/svg+xml;utf8,' + global.encodeURIComponent(input)


let bundles = [{
	dir: 'seti-icons'
	ns: 'SETI'
},{
	dir: 'codicons'
	ns: 'CODICONS'
}]

for {dir,ns} in bundles
	let out = `const EXPORT_NS = "{ns}"\n\n`

	let files = fs.readdirSync("./sources/{dir}")
	let outdir = "./packages/imba-{dir}"
	console.log files

	for src in files
		let body = fs.readFileSync("./sources/{dir}/{src}",'utf8')
		let optim = optimize(body, multipass: true)
		let name = src.replace(/\.svg$/,'').replace(/[-\.]/g,'Ξ')
		console.log src, body.length,optim.data.length

		# name = "iconΞ{name}"
		# if name.match(/^(export|tag|if|else|const|var|let|const)$/)
		#	name = name + "Ξicon"

		name = name.replace(/Ξ/g,'_').toUpperCase!
		fs.writeFileSync("{outdir}/lib/{src}",optim.data)

		let doc = "![]({datauri(optim.data)}|width=120,height=120)"
		out += "# {doc}\n"
		out += "export const {name} = import('./lib/{src}')\n\n"

	fs.writeFileSync("{outdir}/index.imba",out)
		