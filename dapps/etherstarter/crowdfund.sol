contract crowdfund {
    
    event CampaignCreated (hash256 id);
    event Contributed (hash256 id);
    event CampaignFunded (hash256 id);
    event CampaignFinished (hash256 id);
    
    struct shh_identity {
        uint256 lsb;
        uint256 msb;
    }
    
    struct contribution {
        address sender;
        uint256 value;
    }
    
    struct campaign {
        address recipient;
        uint256 goal;
        uint256 deadline;
        uint256 creation_date;
        uint256 contrib_total;
        uint256 contrib_count;
        shh_identity identity;
        mapping (uint256 => contribution) contrib;
        hash256 next;
        hash256 prev;
		bool has_ended;
    }
    
    mapping (hash256 => campaign) campaigns;
    
    function prepend_campaign (hash256 id) private {
        campaign c = campaigns[id];
        
        c.next = 0;
        c.prev = campaigns[0].prev;
        
        campaigns[0].prev = id;
        if (c.prev != 0)
        campaigns[c.prev].next = id;        
    }    
    
    function finish_campaign (hash256 id) private {        
        campaign c = campaigns[id];
        
        if (c.prev != 0)
        campaigns[c.prev].next = c.next;
        if (c.next != 0)
        campaigns[c.next].prev = c.prev;
                
        c.prev = 0;
        c.next = campaigns[0].next;
        
        campaigns[0].next = id;
        if (c.next != 0)
        campaigns[c.next].prev = id;
    }
    
    function compute_id (address recipient, uint256 goal, uint256 deadline, uint256 identity_lsb, uint256 identity_msb) returns (hash256 id) {
        id = sha3 (recipient, goal, deadline, identity_lsb, identity_msb);
    }
    
    function create_campaign (address recipient, uint256 goal, uint256 deadline, uint256 identity_lsb, uint256 identity_msb) {
        var id = compute_id (recipient, goal, deadline, identity_lsb, identity_msb);
        
        campaign c = campaigns[id];
        
        if (c.recipient != 0) return;
        
        c.recipient = recipient;
        c.goal = goal;
        c.deadline = deadline;
        c.identity.lsb = identity_lsb;
        c.identity.msb = identity_msb;
        
        prepend_campaign (id);
        
        CampaignCreated (id);
    }
    
    function contribute (hash256 id) {
        campaign c = campaigns[id];
        
		if (c.recipient == 0) {
			msg.sender.send (msg.value);
			return;
		}
		
		if (block.timestamp > c.deadline) {
			if (c.has_ended) {
				msg.sender.send (msg.value);
				Contributed (id);
			} else {
				for (uint256 i = 0; i < c.contrib_count;i++) {
                    	c.contrib [i].sender.send (c.contrib[i].value);
            	    }
				msg.sender.send (msg.value);
				c.has_ended = true;
				finish_campaign (id);
				CampaignFinished (id);
			}
		} else {
			var total = c.contrib_total + msg.value;
			c.contrib_total = total;

			contribution con = c.contrib[c.contrib_count];

			con.sender = msg.sender;
			con.value = msg.value;
			
			if (c.has_ended) {
				c.recipient.send (msg.value);
				Contributed (id);
			} else if (total >= c.goal) {
				c.recipient.send (total);
				c.has_ended = true;
				finish_campaign (id);
				Contributed (id);
				CampaignFunded (id);
			}			
			c.contrib_count++;
		}		        
        
    }    
    
    function get_total (hash256 id) returns (uint256 total) {
        return campaigns[id].contrib_total;
    }
    
    function get_recipient (hash256 id) returns (address recipient) {
        return campaigns[id].recipient;
    }
    
    function get_deadline (hash256 id) returns (uint256 deadline) {
        return campaigns[id].deadline;
    }
    
    function get_creation_date (hash256 id) returns (uint256 deadline) {
        return campaigns[id].creation_date;
    }
    
    function get_goal (hash256 id) returns (uint256 goal) {
        return campaigns[id].goal;
    }
    
    function get_identity (hash256 id) returns (uint256 lsb, uint256 msb) {
        lsb = campaigns[id].identity.lsb;
        msb = campaigns[id].identity.msb;
    }
    
    function get_contrib_count (hash256 id) returns (uint256 contrib_count) {
        return campaigns[id].contrib_count;
    }
	
	function has_ended (hash256 id) returns (bool end) {
		return campaigns[id].has_ended;
	}
	
	function iterator_next (hash256 id) returns (hash256 next) {
	    return campaigns[id].next;
	}
     
    function iterator_prev (hash256 id) returns (hash256 prev) {
	    return campaigns[id].prev;
	}       
}
