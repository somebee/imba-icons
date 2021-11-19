import fs from 'fs'
import np from 'path'
import {optimize} from 'svgo'

def datauri input,pkg
	input = input.split("\n").map(do $1.trim!).join('')
	# if pkg.style
	# 	input = input.replace "<svg ",`<svg style="{pkg.style}" `
	input = input.replace(/currentColor/g,'#3b82f6')
	return 'data:image/svg+xml;utf8,' + global.encodeURIComponent(input)


let bundles = [{
	dir: 'seti-icons'
	ns: 'SETI'
	svgo:yes
},{
	dir: 'codicons'
	ns: 'CODICONS'
	svgo:yes
},{
	dir: 'material-icons'
	ns: 'MATERIAL'
	filename: 'baseline.svg'
	style: 'fill:currentColor'
	svgo:yes
}]

for pkg in bundles
	let ns = pkg.ns
	let dir = pkg.dir
	let out = `const EXPORT_NS = "{ns}"\n\n`

	let files = fs.readdirSync("./sources/{dir}")
	let outdir = "./packages/imba-{dir}"
	console.log files

	for filename in files
		continue if filename == ".DS_Store"
		let src = "./sources/{dir}/{filename}"


		if pkg.filename
			src += "/{pkg.filename}"

		let body = fs.readFileSync(src,'utf8')
		let outbody = body
		let optim = optimize(body, {multipass: false, removeViewBox: false})

		# if pkg.svgo
		#	outbody = optim.data

		if !optim.info.width
			if let viewBox = body.match(/viewBox="0 0 (\d+) (\d+)"/)
				optim.info.width = parseInt(viewBox[1])
				optim.info.height = parseInt(viewBox[2])

		if pkg.style
			outbody = outbody.replace "<svg ",`<svg style="{pkg.style}" `
			
		
		let name = filename.replace(/\.svg$/,'').replace(/[-\.]/g,'Ξ')
		console.log src, body.length,optim.data.length

		name = name.replace(/Ξ/g,'_').toUpperCase!

		if !name.match(/^[A-Z]/)
			name = "_" + name

		let outname = filename.replace(/\.svg$/,'') + '.svg'
		fs.writeFileSync("{outdir}/lib/{outname}",outbody)

		let img = "![]({datauri(outbody,pkg)}|width=120,height=120)\n"
		
		out += "# {dir} / {filename} ({optim.info.width}x{optim.info.height})\n"
		out += "# {img}\n"
		out += "export const {name} = import('./lib/{outname}')\n\n"

	fs.writeFileSync("{outdir}/index.imba",out)
		