contract crowdfund {
    
    struct contribution {
        address sender;
        uint256 value;
    }
    
    struct campaign {
        address recipient;
        uint256 goal;
        uint256 deadline;
        uint256 contrib_total;
        uint256 contrib_count;
        uint256 shh_identiy;
        mapping (uint256 => contribution) contrib;
    }
    
    mapping (uint256 => campaign) campaigns;
    
    function create_campaign (uint256 id, address recipient, uint256 goal, uint256 deadline, uint256 shh_identiy) {
        campaign c = campaigns[id];
        
        if (c.recipient != 0) return;
        
        c.recipient = recipient;
        c.goal = goal;
        c.deadline = deadline;
        c.shh_identiy = shh_identiy;   
    }
    
    function contribute (uint256 id) {
        campaign c = campaigns[id];
        
        var total = c.contrib_total + msg.value;
        c.contrib_total = total;
        
        contribution con = c.contrib[c.contrib_count];
        
        con.sender = msg.sender;
        con.value = msg.value;
        
        c.contrib_count++;
        
        if (total >= c.goal) {
            c.recipient.send (total);
            this.clear (id);
            return;
        }
        
        if (block.timestamp > c.deadline) {
            for (uint256 i = 0; i < c.contrib_count;i++) {
                c.contrib [i].sender.send (c.contrib[i].value);
            }
            this.clear (id);
            return;
        }
    }
    
    function clear (uint256 id) {
        if (address(this) == msg.sender) {
            campaign c = campaigns[id];
            
            c.recipient = 0;
            c.goal = 0;
            c.deadline = 0;     
            c.contrib_total = 0;       
            
            for (uint256 i=0;i< c.contrib_count;i++){
                c.contrib [i].sender = 0;
                c.contrib [i].value = 0;
            }
            
            c.contrib_count = 0;
        }
    }
    
    function get_total (uint256 id) returns (uint256 total) {
        return campaigns[id].contrib_total;
    }
    
    function get_recipient (uint256 id) returns (address recipient) {
        return campaigns[id].recipient;
    }
    
    function get_deadline (uint256 id) returns (uint256 deadline) {
        return campaigns[id].deadline;
    }
    
    function get_goal (uint256 id) returns (uint256 goal) {
        return campaigns[id].goal;
    }
    
    function get_shh_identiy (uint256 id) returns (uint256 identiy) {
        return campaigns[id].shh_identiy;
    }
    
    function get_contrib_count (uint256 id) returns (uint256 contrib_count) {
        return campaigns[id].contrib_count;
    }
    
    function get_free_id () returns (uint256 id) {
        uint256 i = 0;
        while (campaigns[i].recipient != 0) i++;
        return i;
    }
}
