//Crowdfund v0.2
contract crowdfund {

    event CampaignCreated (hash256 id); // After create_campaign
    event Contributed (hash256 id); // Whenever contrib_count increases
    event CampaignFunded (hash256 id); // First time contrib_total > goal
    event CampaignFinished (hash256 id); // When deadline expires
    event CampaignInfoChanged (hash256 id); // Whenever info_hash changes

    struct shh_identity {
        uint256 lsb; // 256 least significant bits of whisper identity
        uint256 msb; // 256 most significant bits of whisper identity
    }

    struct contribution {
        address sender;
        uint256 value;
    }

    struct campaign {
        address creator; // sender of create_campaign, can update info_hash
        address recipient; // beneficiary of the campaign
        uint256 goal; // goal in wei
        uint256 deadline; // deadline as unix timestamp
        uint256 creation_date; // unix timestamp of create_campaign
        uint256 contrib_total; // amount raised
        uint256 contrib_count; // number of contributions
        shh_identity identity; // associated whsiper identity
        mapping (uint256 => contribution) contrib; // maps contribution id to contribution
        hash256 next; // doubly linked list for campaigns iteration. active campaigns left of campaigns[0]
        hash256 prev; // doubly linked list for campaigns iteration. past campaigns right of campaigns[0]
        bool has_ended; // block.timestamp > deadline
        hash256 desc_hash; // hash over title + description, immutable
        hash256 info_hash; // hash over updates, mutable by creator
    }

    // mapping from campaign id to campaign
    mapping (hash256 => campaign) campaigns;

    // adds campaign id to left lis
    function prepend_campaign (hash256 id) private {
        campaign c = campaigns[id];

        c.next = 0;
        c.prev = campaigns[0].prev;

        campaigns[0].prev = id;
        if (c.prev != 0)
        campaigns[c.prev].next = id;
    }

    // removes campaign id from list and readds it to the right lis
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

    // compute the id from campaign from relevant data
    function compute_id (address recipient, uint256 goal, uint256 deadline, uint256 identity_lsb, uint256 identity_msb, hash256 desc_hash) returns (hash256 id) {
        id = sha3 (recipient, goal, deadline, identity_lsb, identity_msb);
    }

    // create campaign if id unused
    function create_campaign (address recipient, uint256 goal, uint256 deadline, uint256 identity_lsb, uint256 identity_msb, hash256 desc_hash) {
        var id = compute_id (recipient, goal, deadline, identity_lsb, identity_msb, desc_hash);

        campaign c = campaigns[id];

        if (c.recipient != 0) return;

        c.recipient = recipient;
        c.goal = goal;
        c.deadline = deadline;
        c.identity.lsb = identity_lsb;
        c.identity.msb = identity_msb;
        c.creator = msg.sender;
        c.desc_hash = desc_hash;
        c.info_hash = 0;

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
            } else if (total >= c.goal) {
                c.recipient.send (total);
                c.has_ended = true;
                finish_campaign (id);
                CampaignFunded (id);
            }
            c.contrib_count++;
            Contributed (id);
        }
    }

    // Change info_hash if sender is creator
    function modify_info_hash (hash256 id, hash256 info_hash) {
        campaign c = campaigns[id];

        if (msg.sender == c.creator) {
            c.info_hash = info_hash;
            CampaignInfoChanged (id);
        }
    }

    // Various getters

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

    function get_creator (hash256 id) returns (address creator) {
        return campaigns[id].creator;
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

    function get_desc_hash (hash256 id) returns (hash256 next) {
        return campaigns[id].desc_hash;
    }

    function get_info_hash (hash256 id) returns (hash256 prev) {
        return campaigns[id].info_hash;
    }

    // Iterator functions for campaigns lis

    function iterator_next (hash256 id) returns (hash256 next) {
        return campaigns[id].next;
    }

    function iterator_prev (hash256 id) returns (hash256 prev) {
        return campaigns[id].prev;
    }
}
