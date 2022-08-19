class Icon {

    constructor(attrs,content){
        this.attributes = attrs;
        this.content = content;
    }

    adoptNode(node){
        for (const [key, value] of Object.entries(this.attributes)) {
            node.setAttribute(key,value);
        }
		node.innerHTML = this.content;
    }
}

