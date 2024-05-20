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

		

	# js = js.replace(/\,$/,'') + '},`' + content + '`'

	# console.log 'content is',content,pars,attrs
	return {
		attributes: attrs
		flags: []
		content: content
		toString: do js.replace(/\,$/,'') + '},`' + this.content + '`'
		# #js: js
	}


let bundles = [{
	dir: 'seti-icons'
	ns: 'SETI'
	svgo:yes
},{
	dir: 'codicons'
	ns: 'CODICONS'
	sourcedir: './vendor/codicons/src/icons'
	svgo:yes
},{
	dir: 'material-icons'
	sourcedir: './vendor/material-design-icons/svg/filled'
	ns: 'MATERIAL'
	# filename: 'baseline.svg'
	style: 'fill:currentColor'
	svgo:yes
},{
	dir: 'material-icons'
	sourcedir: './vendor/material-design-icons/svg/outlined'
	ns: 'MATERIAL'
	subname: 'outlined'
	style: 'fill:currentColor'
	svgo:yes
},{
	dir: 'material-icons'
	sourcedir: './vendor/material-design-icons/svg/round'
	ns: 'MATERIAL'
	subname: 'round'
	style: 'fill:currentColor'
	svgo:yes
},{
	dir: 'material-icons'
	sourcedir: './vendor/material-design-icons/svg/two-tone'
	ns: 'MATERIAL'
	subname: 'two-tone'
	style: 'fill:currentColor'
	svgo:yes
},{
	dir: 'phosphor-icons'
	sourcedir: './sources/phosphor-icons/svg/Regular'
	flags: 'phosphor'
	ns: 'PHOSPHOR'
	# subname: 'two-tone'
	# style: 'stroke:currentColor'
	svgo:yes
},{
	dir: 'phosphor-icons'
	sourcedir: './sources/phosphor-icons/svg/Fill'
	flags: 'phosphor filled'
	subname: 'filled'
	ns: 'PHOSPHOR'
	svgo:yes
},{
	dir: 'phosphor-icons'
	sourcedir: './sources/phosphor-icons/svg/Duotone'
	flags: 'phosphor duotone'
	subname: 'duotone'
	ns: 'PHOSPHOR'
	svgo:yes
}]

let only = process.argv[2]

for pkg in bundles
	if only and !pkg.dir.match(only)
		continue

	let ns = pkg.ns
	let dir = pkg.dir


	let mjs = `const EXPORT_NS = "{ns}"\n\n`
	let cjs = `const EXPORT_NS = "{ns}"\n\n`
	mjs += fs.readFileSync('./base.js','utf8')
	cjs += fs.readFileSync('./base.js','utf8')

	# continue unless dir == 'codicons'
	let srcdir = pkg.sourcedir or "./sources/{dir}"
	let files = fs.readdirSync(srcdir)
	let outdir = "./packages/imba-{dir}"
	let outname = pkg.subname or "index"

	console.log files

	for filename,i in files
		continue if filename == ".DS_Store"
		# break if i > 20
		let src = "{srcdir}/{filename}"

		if pkg.filename
			src += "/{pkg.filename}"

		let body = fs.readFileSync(src,'utf8')
		let outbody = body
		let optim = optimize(body, {multipass: false, removeViewBox: false})
		let rawname = filename.replace(/(-duotone|-fill)?\.svg$/,'')

		if !optim.info.width
			if let viewBox = body.match(/viewBox="0 0 (\d+) (\d+)"/)
				optim.info.width = parseInt(viewBox[1])
				optim.info.height = parseInt(viewBox[2])

		# console.log optim

		let preview = datauri(outbody,pkg)

		if pkg.style
			# parsed.attributes.style = pkg.style
			outbody = outbody.replace "<svg ",`<svg style="{pkg.style}" `

		let parsed = parsesvg(outbody)

		if ns == 'PHOSPHOR'
			# parsed.content = `<g class='stroke'>{parsed.content}</g>`
			if false # filename.match(/play|pause|ghost/) or false # == 'play.svg'
				let filledsrc = src.replace(/Regular|Duotone/,'Fill').replace(/(-duotone)?\.svg/,'-fill.svg')
				let filledraw = fs.readFileSync(filledsrc,'utf8')
				let filled = parsesvg(filledraw)

				parsed.content += `<g class='filled'>{filled.content}</g>`
				parsed.flags.push('multi')

				# outbody = outbody.replace('</svg>',`<g>{filled.content}</g></svg>`)
			
			# outbody = outbody.replace(/stroke-line(cap|join)="round"/g,'')
			# outbody = outbody.replace(/stroke-width="16"/g,'')
			yes
			# outbody = outbody.replace(/stroke-line(cap|join)="round"/g,'')
			parsed.content = parsed.content.replace(/<rect width="256" height="256" fill="none"\/>/g,'')
			

		let name = rawname.replace(/[-\.]/g,'Ξ')
		console.log src, body.length,optim.data.length,parsed.#js

		name = name.replace(/Ξ/g,'_').toUpperCase!

		if !name.match(/^[A-Z]/)
			name = "_" + name

		let outname = rawname + '.svg'
		# fs.writeFileSync("{outdir}/lib/{outname}",outbody)

		let img = "![]({preview}|width=120,height=120)\n"
		
		mjs += "/**\n * {dir} / {filename} ({optim.info.width}x{optim.info.height})\n * {img}\n **/\n"
		mjs += "export const {name} = /* @__PURE__ */ new Icon({String(parsed)},'{pkg.flags or ''}');\n\n"
		cjs += "/**\n * {dir} / {filename} ({optim.info.width}x{optim.info.height})\n * {img}\n **/\n"
		cjs += "exports.{name} = /* @__PURE__ */ new Icon({String(parsed)},'{pkg.flags or ''}');\n\n"

	fs.writeFileSync("{outdir}/{outname}.mjs",mjs)
	fs.writeFileSync("{outdir}/{outname}.cjs",cjs)