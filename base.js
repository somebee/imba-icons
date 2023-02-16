class Icon {

    constructor(attrs,content,flags = ''){
        this.attributes = attrs;
        this.content = content;
        this.flags = flags;
    }

    adoptNode(node){
        for (const [key, value] of Object.entries(this.attributes)) {
            node.setAttribute(key,value);
        }
		node.innerHTML = this.content;
    }
}

