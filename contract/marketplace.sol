// SPDX-License-Identifier: MIT  

pragma solidity >=0.7.0 <0.9.0;

// ERC20 token functions
interface ERC20
{
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract goodCause
{

    // GoodCause is a decentralized crowdfunding page where people can help each other by donating directly to the person who makes a request

    address internal cUsd = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1; // cUsd contract address
    uint internal maxIndex = 0; // Index variable to keep track of the total number of requests

    // Structure containing all the data needed for a request
    struct Request
    {
        address payable owner;
        uint id;
        string title;
        string description;
        string image;
        uint goal;
        uint funded;
        int activeStatus;
    }

    mapping(uint => Request) internal requests;

    // Used in some functions to protect a request from anyone other than the owner
    modifier ownerOnly(uint _id)
    {
        require(msg.sender == requests[_id].owner, "Only the owner has permission to do this"); // The function will only run if the first arguement is true
        _; // This means 'run the rest of the function to which this modifier was applied to'
    }

    function latestRequest() public view returns(uint)
    {
        // maxIndex keeps track of the number of requests, very important in order to iterate through the array later
        return maxIndex;
    }

    function newRequest(string memory _title, string memory _description, string memory _image, uint _goal) public
    {
        // Accesses the array and creates another request structure with the info specified, this array will later be accessed using javascript
        requests[maxIndex] = Request(payable(msg.sender), maxIndex, _title, _description, _image, _goal, 0, 1);
        // Important to increase maxIndex variable to match the number of requests
        maxIndex++;
    }

    function requestData(uint _id) public view returns(address payable, string memory, string memory, string memory, uint, uint, int)
    {
        // Retrieves all information in the request structure for a specific request. This will me used to display the info on the web
        return(requests[_id].owner, requests[_id].title, requests[_id].description, requests[_id].image, requests[_id].goal, requests[_id].funded, requests[_id].activeStatus);
    }

    function donate(uint _id, uint _amount) public payable
    {
        // This requirement ensures the sender has sent the amount specified to the owner of the request, if the transaction fails, the next line won't run
        require(ERC20(cUsd).transferFrom(msg.sender, requests[_id].owner, _amount), "Transaction failed, please try again.");
        // This part will only run if the transaction is successful, it keeps track of the total donated amount
        requests[_id].funded += _amount/1000000000000000000;
        // If the goal is complete change the active status to zero, hiding the request
        if (requests[_id].funded >= requests[_id].goal)
        {
            requests[_id].activeStatus = 0;
        }
    }

    function deleteRequest(uint _id) public ownerOnly(_id)
    {
        // This function does not delete the request, it will hide it from displaying
        requests[_id].activeStatus = 0;
    }
}