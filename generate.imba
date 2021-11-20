import fs from 'fs'
import np from 'path'
import {optimize} from 'svgo'

def datauri input,pkg
	input = input.split("\n").map(do $1.trim!).join('')
	# if pkg.style
	# 	input = input.replace "<svg ",`<svg style="{pkg.style}" `
	input = input.replace(/currentColor/g,'#3b82f6')
	return 'data:image/svg+xml;utf8,' + global.encodeURIComponent(input)

def parsesvg str
	let start = str.indexOf('<',1)
	let end = str.length - 6
	let content = str.slice(start,end)
	let pars = str.slice(4,start - 1)
	let attrs = {}
	let js = '{'

	pars.replace(/([\w\-]+)\=\"([^\"]+)/g) do(m,k,val)
		return if k == 'xmlns'
		attrs[k] = val

		if k.indexOf('-') >= 0
			k = '"' + k + '"'

		if val.match(/^\d+$/)
			val = parseInt(val)
			js += "{k}:{val},"
		else
			js += "{k}:\"{val}\","

		

	js = js.replace(/\,$/,'') + '},`' + content + '`'

	# console.log 'content is',content,pars,attrs
	return {
		attributes: attrs
		flags: []
		content: content
		#js: js
	}


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

	out += fs.readFileSync('./base.js','utf8')

	# continue unless dir == 'codicons'

	let files = fs.readdirSync("./sources/{dir}")
	let outdir = "./packages/imba-{dir}"
	console.log files

	for filename,i in files
		continue if filename == ".DS_Store"
		# break if i > 20
		let src = "./sources/{dir}/{filename}"

		if pkg.filename
			src += "/{pkg.filename}"

		let body = fs.readFileSync(src,'utf8')
		let outbody = body
		let optim = optimize(body, {multipass: false, removeViewBox: false})

		if !optim.info.width
			if let viewBox = body.match(/viewBox="0 0 (\d+) (\d+)"/)
				optim.info.width = parseInt(viewBox[1])
				optim.info.height = parseInt(viewBox[2])

		if pkg.style
			# parsed.attributes.style = pkg.style
			outbody = outbody.replace "<svg ",`<svg style="{pkg.style}" `

		let parsed = parsesvg(outbody)

		let name = filename.replace(/\.svg$/,'').replace(/[-\.]/g,'Ξ')
		console.log src, body.length,optim.data.length,parsed.#js

		name = name.replace(/Ξ/g,'_').toUpperCase!

		if !name.match(/^[A-Z]/)
			name = "_" + name

		let outname = filename.replace(/\.svg$/,'') + '.svg'
		fs.writeFileSync("{outdir}/lib/{outname}",outbody)

		let img = "![]({datauri(outbody,pkg)}|width=120,height=120)\n"
		
		out += "/**\n * {dir} / {filename} ({optim.info.width}x{optim.info.height})\n * {img}\n **/\n"
		# out += "# {img}\n"
		# out += "export const {name} = import('./lib/{outname}')\n\n"
		out += "export const {name} = /* @__PURE__ */ new Icon({parsed.#js});\n\n"

	fs.writeFileSync("{outdir}/index.js",out)
		