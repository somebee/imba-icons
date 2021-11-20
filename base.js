class Icon {

    constructor(attrs,content){
        this.attrs = attrs;
        this.content = content;
    }

    adoptNode(node){
        for (const [key, value] of Object.entries(this.attrs)) {
            node.setAttribute(key,value);
        }
		node.innerHTML = this.content;        
    }
}

