// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

// ERC20 token functions
interface ERC20 {
    function transfer(address, uint256) external returns (bool);

    function approve(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract goodCause {
    // GoodCause is a decentralized crowdfunding page where people can help each other by donating directly to the person who makes a request

    address internal cUsd = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1; // cUsd contract address
    uint256 internal maxIndex = 0; // Index variable to keep track of the total number of requests

    // Structure containing all the data needed for a request
    struct Request {
        address payable owner;
        uint256 id;
        string title;
        string description;
        string image;
        uint256 goal;
        uint256 funded;
        bool activeStatus;
    }

    mapping(uint256 => Request) private requests;

    event RequestEvent(
        address indexed owner,
        string title,
        string description,
        string image,
        uint256 indexed goal,
        uint256 funded,
        bool indexed success
    );

    // modifier to check if a request exists
    modifier exists(uint256 _id) {
        require(requests[_id].activeStatus, "Query of nonexistent request");
        _;
    }

    function latestRequest() public view returns (uint256) {
        // maxIndex keeps track of the number of requests, very important in order to iterate through the mapping later
        return maxIndex;
    }

    /**
     * @dev allow users to create a neq request for donations
     * @notice input data needs to only contain valid values
     */
    function newRequest(
        string calldata _title,
        string calldata _description,
        string calldata _image,
        uint256 _goal
    ) public {
        require(bytes(_title).length > 0, "Empty title");
        require(bytes(_description).length > 0, "Empty description");
        require(bytes(_image).length > 0, "Empty image");
        // Accesses the mapping and creates another request structure with the info specified,
        // this array will later be accessed using javascript
        requests[maxIndex] = Request(
            payable(msg.sender),
            maxIndex,
            _title,
            _description,
            _image,
            _goal,
            0, // funded initialized as zero
            true // activeStatus initialized as true
        );
        // Important to increase maxIndex variable to match the number of requests
        maxIndex++;
    }

    function requestData(uint256 _id)
        public
        view
        exists(_id)
        returns (Request memory)
    {
        // Retrieves all information in the request structure for a specific request. This will me used to display the info on the web
        return (requests[_id]);
    }

    /**
     * @dev allow users to donate to an active request
     * @param _amount the amount a user wants to donate
     * @notice if goal for request is reached, it is stored on the transaction logs and then removed from the contract's state
     */
    function donate(uint256 _id, uint256 _amount) public payable exists(_id) {
        require(
            _amount >= 1 ether,
            "Amount to donate must be at least one CUSD"
        );
        Request storage currentRequest = requests[_id];

        require(
            currentRequest.owner != msg.sender,
            "You can't donate to your requests"
        );
        // This requirement ensures the sender has sent the amount specified to the owner of the request,
        // if the transaction fails, the next line won't run
        require(
            ERC20(cUsd).transferFrom(msg.sender, currentRequest.owner, _amount),
            "Transaction failed, please try again."
        );
        // This part will only run if the transaction is successful, it keeps track of the total donated amount
        currentRequest.funded += _amount;
        // If the goal is achieved, store request's data in the transaction logs and then remove it from the contract's state
        if (currentRequest.funded >= currentRequest.goal) {
            emit RequestEvent(
                currentRequest.owner,
                currentRequest.title,
                currentRequest.description,
                currentRequest.image,
                currentRequest.goal,
                currentRequest.funded,
                true
            );
            uint256 newMaxIndex = maxIndex - 1;
            requests[_id] = requests[newMaxIndex];
            delete requests[newMaxIndex];
            maxIndex--;
        }
    }

    /**
     * @dev allow requests' owners to delete their requests
     * @notice request data will be stored on the transaction logs and then removed from the contract's state
     */
    function deleteRequest(uint256 _id) public exists(_id) {
        Request storage currentRequest = requests[_id];
        require(
            msg.sender == currentRequest.owner,
            "Only the owner has permission to do this"
        );
        // store request's data in the transaction logs and then remove it from the contract's state
        emit RequestEvent(
            currentRequest.owner,
            currentRequest.title,
            currentRequest.description,
            currentRequest.image,
            currentRequest.goal,
            currentRequest.funded,
            false
        );
        uint256 newMaxIndex = maxIndex - 1;
        requests[_id] = requests[newMaxIndex];
        delete requests[newMaxIndex];
        maxIndex--;
    }
}
