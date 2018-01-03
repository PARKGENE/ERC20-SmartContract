pragma solidity ^0.4.15;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
contract SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b != 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function mulByFraction(uint256 number, uint256 numerator, uint256 denominator) internal returns (uint256) {
        return div(mul(number, numerator), denominator);
    }
}

contract Owned {

    address public owner;

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != 0x0);
        owner = newOwner;
    }
}


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 is SafeMath {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;   // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;


    

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol) public
        {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes


    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint256 _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) 
        {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) 
        {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

}

/******************************************/
/*       ADVANCED TOKEN STARTS HERE       */
/******************************************/
/**
* Constructor function
*
* Initializes contract with initial supply tokens to the creator of the contract
*/
contract AdvancedToken is TokenERC20 {

    function AdvancedToken( 
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol) TokenERC20(initialSupply, tokenName, tokenSymbol) public 
        {
        }


    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other ccount
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply 
        Burn(_from, _value);
        return true;
    }

        /**
     * Destroy tokens from account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function _burnFrom(address _from, uint256 _value) internal returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        totalSupply -= _value;                              // Update totalSupply 
        Burn(_from, _value);
        return true;
    }

}

/******************************************/
/*       ADVANCED TOKEN STARTS HERE       */
/******************************************/

contract GENEToken is Owned, AdvancedToken {
 
    uint256 public foundersTokens;
    uint256 public remainingFoundersTokens;

    address public tokenPreSaleAddress=0x0;
    address public tokenSaleAddress=0x0;
    address public earlyBirdAddress=0x0;
    address public bountyAddress=0x0;


    address public foundersAddress=0x0;
    address public advisorsAddress=0x0;
    address public employeesBoardAddress=0x0;

    address public parkgeneFutureFundAddress=0x0;
    address public parkgeneCharityFundAddress=0x0;

    uint public earlyBirdStarted;
    uint public earlyBirdEnded;

    uint public tokenPreSaleStarted;
    uint public tokenPreSaleEnded;

    uint public tokenSaleStarted;
    uint public tokenSaleEnded;

    uint  afterSaleFoundersDispatch1;
    uint  afterSaleFoundersDispatch2;
    uint  afterSaleFoundersDispatch3;

    uint256 public parkgeneFutureFundTokens;

    uint256 public tokensSold;

    uint256 public earlyBirdTokensSold;
    uint256 public preSaleTokensSold;
    uint256 public saleTokensSold;

    enum TokenStatus {TokenCreation,EarlyBirdStarted,TokenPreSaleStarted,TokenPreSaleEnded,TokenSaleStarted,TokenSaleEnded,FinalTokenDistributationEnded}
    TokenStatus public tokenSaleStatus=TokenStatus.TokenCreation;


    /* Initializes contract with initial supply tokens to the creator of the contract */
    function GENEToken() AdvancedToken(1000000000, "PARKGENE Token", "GENE") public {
     }

    //Assign tokens to the required(during the token sale) addresses
    function assignTokensToInitialHolders(address _earlyBirdAddress, address _pretokenSaleAddress, address _bountyAddress, address _tokenSaleAddress, address _foundersAddress, address _AdvisorsAddress, address _EmployeesBoardAddress, address _parkgeneFutureFundAddress, address _parkgeneCharityFundAddress) onlyOwner public {
        require (_pretokenSaleAddress != 0x0);     // Prevent transfer to 0x0 address. 
        require (_bountyAddress != 0x0);     
        require (_earlyBirdAddress != 0x0);  
        require (_tokenSaleAddress != 0x0);      
        require (_foundersAddress != 0x0); 
        require (_AdvisorsAddress != 0x0); 
        require (_EmployeesBoardAddress != 0x0); 
        require (_parkgeneFutureFundAddress != 0x0); 
        require (_parkgeneCharityFundAddress != 0x0); 

        earlyBirdAddress = _earlyBirdAddress;
        tokenPreSaleAddress = _pretokenSaleAddress;
        bountyAddress = _bountyAddress;
        tokenSaleAddress = _tokenSaleAddress;
        foundersAddress = _foundersAddress;
        advisorsAddress = _AdvisorsAddress;
        employeesBoardAddress = _EmployeesBoardAddress;
        parkgeneFutureFundAddress = _parkgeneFutureFundAddress;
        parkgeneCharityFundAddress = _parkgeneCharityFundAddress;


        foundersTokens = mulByFraction(totalSupply,10,100);
        remainingFoundersTokens = foundersTokens;

        _transfer(owner,tokenPreSaleAddress, mulByFraction(totalSupply,4,100));

        _transfer(owner,bountyAddress, mulByFraction(totalSupply,5,100));    

        _transfer(owner,earlyBirdAddress, mulByFraction(totalSupply,1,100)); 

        _transfer(owner,tokenSaleAddress, mulByFraction(totalSupply,30,100));  

        _transfer(owner,advisorsAddress,mulByFraction(totalSupply,4,100));

        _transfer(owner,employeesBoardAddress,mulByFraction(totalSupply,6,100));

        _transfer(owner,parkgeneFutureFundAddress,mulByFraction(totalSupply,40,100));

    }

    function airDrop(address[] _addresses,uint256 _amount) public {
        require(bountyAddress!=0x0);
        require(msg.sender==bountyAddress);
        for (uint i = 0; i < _addresses.length; i++) {
            _transfer(bountyAddress,_addresses[i],_amount);
        }
    }



        /* Start token presale */
    function startEarlyBird() onlyOwner public {
        require (earlyBirdAddress != 0x0); 
        require (tokenSaleStatus==TokenStatus.TokenCreation);
        tokenSaleStatus = TokenStatus.EarlyBirdStarted;
        earlyBirdStarted = now;
 
    }


    /* End early bird, transfer remaining tokens to the provided address and init token presale */
    function endEarlyBird(address _to) onlyOwner public {
        require (tokenSaleStatus==TokenStatus.EarlyBirdStarted);
        if (balanceOf[earlyBirdAddress]>0)
        _transfer(earlyBirdAddress,_to, balanceOf[earlyBirdAddress]);
        tokenSaleStatus = TokenStatus.TokenPreSaleStarted;
        earlyBirdEnded = now; 
        tokenPreSaleStarted = now; 
    }

    /* End token presale */
    function endTokenPreSale() onlyOwner public {
        require (tokenSaleStatus==TokenStatus.TokenPreSaleStarted);
        tokenSaleStatus = TokenStatus.TokenPreSaleEnded;
        tokenPreSaleEnded = now; 
    }

       /* Start token sale */
    function startTokenSale() onlyOwner public {    
        require (tokenPreSaleAddress != 0x0);     
        require (tokenSaleStatus==TokenStatus.TokenPreSaleEnded);       
        tokenSaleStatus = TokenStatus.TokenSaleStarted;
        tokenSaleStarted = now;
           
    }



    /* End token sale */
    function endTokenSale() onlyOwner public {
        require (tokenSaleStatus==TokenStatus.TokenSaleStarted);
        tokenSaleStatus = TokenStatus.TokenSaleEnded;
        tokenPreSaleEnded = now; 
        afterSaleFoundersDispatch1 = now; 
        afterSaleFoundersDispatch2 = now + 90 days;
        afterSaleFoundersDispatch3 = now + 180 days;
    
    }


        /* transfer tokens to founders, the allowed number of tokens is 30% after token sale,30% after 3 months and 40% after 6 months of the total founders tokens(10%)*/
    function dispatchToFounders() onlyOwner public {  
        require(tokenSaleStatus>=TokenStatus.TokenSaleEnded);
        require(remainingFoundersTokens>0);
        if (now>=afterSaleFoundersDispatch3) {
            uint256 toBeTransferedTokens = mulByFraction(foundersTokens,40,100);
            _transfer(owner,foundersAddress,toBeTransferedTokens);
            remainingFoundersTokens -= toBeTransferedTokens;
        } else {   
        if (now>=afterSaleFoundersDispatch2) {
            toBeTransferedTokens = mulByFraction(foundersTokens,30,100);
            _transfer(owner,foundersAddress,toBeTransferedTokens);
            remainingFoundersTokens -= toBeTransferedTokens;
        } else {
        if (now>=afterSaleFoundersDispatch1) {
            toBeTransferedTokens = mulByFraction(foundersTokens,30,100);
            _transfer(owner,foundersAddress,toBeTransferedTokens);
            remainingFoundersTokens -= toBeTransferedTokens; 
        }
        }
        }
    }


        /* Finish the token destribution, transfer bounty tokens to Charity fund address*/
    function dispatchBountyToparkgeneCharityFund() onlyOwner public {
        require(tokenSaleStatus>=TokenStatus.TokenSaleEnded); 
        if (balanceOf[bountyAddress]>0) 
        _transfer(bountyAddress,parkgeneCharityFundAddress,balanceOf[bountyAddress]);
        if (balanceOf[tokenSaleAddress]>0)
        _burnFrom(tokenSaleAddress, balanceOf[tokenSaleAddress]);  
        if (balanceOf[tokenPreSaleAddress]>0)
        _burnFrom(tokenPreSaleAddress, balanceOf[tokenPreSaleAddress]);
        tokenSaleStatus = TokenStatus.FinalTokenDistributationEnded;

    }


    /* Transfer tokens during Token sale, Should be called only from Early Bird, PretokenSale, tokenSale and Bounty addresses */
    function tokenSaleTransfer(address _to, uint256 _value) public {
        // Prevent transfer to 0x0 address.
        require(_to != 0x0);
        //Check if token sale status allows transfers(Allowed only when token sale status is Early Bird or PretokenSale or tokenSale and before ).   
        require(tokenSaleStatus!=TokenStatus.TokenCreation && tokenSaleStatus!=TokenStatus.TokenPreSaleEnded && tokenSaleStatus!=TokenStatus.FinalTokenDistributationEnded);
        //Check if token sale status allows sender to transfer tokens
        if (tokenSaleStatus==TokenStatus.EarlyBirdStarted ) {
            require(msg.sender==earlyBirdAddress);
            earlyBirdTokensSold += _value;
            tokensSold += _value;
        } else {
        if (tokenSaleStatus==TokenStatus.TokenPreSaleStarted) {
            require(msg.sender==tokenPreSaleAddress);
            preSaleTokensSold += _value;
            tokensSold += _value;
        } else {
        if (tokenSaleStatus==TokenStatus.TokenSaleStarted) {
            require(msg.sender==tokenSaleAddress);
            saleTokensSold += _value;
            tokensSold += _value;
        } else {
        require(tokenSaleStatus==TokenStatus.TokenSaleEnded && msg.sender==bountyAddress);    
        }
        }
        }
        //Use internal tarnsfer 
        _transfer(msg.sender, _to, _value);
        

    }


}
