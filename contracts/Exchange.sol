
pragma solidity ^0.5.0;
import "./Token.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";



//TODO:
//[x] Set the fee amount
//[x] Deposit Ether
//[x] Withdraw Eether
//[x] Deposit tokens
//[x] Withdraw tokens
//[x] Check balances
//[x] Make order
//[x] Cancel order
//[x] Fill order
//[x] Charge fees

contract Exchange {

	// Variables

	using SafeMath for uint;
	address public feeAccount; // the account that receives exchange
	uint256 public feePercent; // the fee percentage
	address constant ETHER = address(0); // store Ether in tokens mapping with blank address

	//mapping(address => uint256) public balanceOf;
	
	mapping(address => mapping(address => uint256)) public tokens;
	mapping(uint256 => _Order) public orders;
	uint256 public orderCount;
	mapping(uint256 => bool) public orderCancelled;
	mapping(uint256 => bool) public orderFilled;
	
	// Events

	event Deposit(address token, address user, uint256 amount, uint256 balance);
	event Withdraw(address token, address user, uint256 amount, uint256 balance);

	event Order (

		uint256 id,
		address user,
		address tokenGet,  
		uint256 amountGet,
		address tokenGive,  
		uint256 amountGive,
		uint256 timestamp  
	);


	event Cancel (

		uint256 id,
		address user,
		address tokenGet,  
		uint256 amountGet,
		address tokenGive,  
		uint256 amountGive,
		uint256 timestamp  
	);

	event Trade (

		uint256 id,
		address user,
		address tokenGet,  
		uint256 amountGet,
		address tokenGive,  
		uint256 amountGive,
		address userFill,
		uint256 timestamp  
	);

	// Structs

	struct _Order {
		uint256 id;
		address user;
		address tokenGet; // token the user receives in the trade
		uint256 amountGet;
		address tokenGive; // token the user sends in order to receive the the token they want
		uint256 amountGive;
		uint256 timestamp; // time the order was created

	}
		

	// a way to model the order
	// a way to store the order
	// add the order to the storage

	constructor(address _feeAccount, uint256 _feePercent) public {
		feeAccount = _feeAccount;
		feePercent = _feePercent;
	}

	// fallback: reverts if ether is sent directly to this exchange
	
	function() external {
		revert();
	}

	function depositEther() payable public {
		tokens[ETHER][msg.sender] = tokens[ETHER][msg.sender].add(msg.value);
		emit Deposit(ETHER, msg.sender, msg.value, tokens[ETHER][msg.sender]);

	}

	function withdrawEther(uint _amount) public {
		require(tokens[ETHER][msg.sender] >= _amount);
		tokens[ETHER][msg.sender] = tokens[ETHER][msg.sender].sub(_amount);
		msg.sender.transfer(_amount);
		emit Withdraw(ETHER, msg.sender, _amount, tokens[ETHER][msg.sender]);

	}



	function depositToken(address _token, uint _amount) public {
		require(_token != ETHER);
		require(Token(_token).transferFrom(msg.sender, address(this), _amount));
		tokens[_token][msg.sender] = tokens[_token][msg.sender].add(_amount);
		emit Deposit(_token, msg.sender, _amount, tokens[_token][msg.sender]);
		// Manange depoit - update balance
		// Emit event

	}

	function withdrawToken(address _token, uint256 _amount) public {
		require(_token != ETHER);
		require(tokens[_token][msg.sender] >= _amount);
		tokens[_token][msg.sender] = tokens[_token][msg.sender].sub(_amount);
		require(Token(_token).transfer(msg.sender, _amount));
		emit Withdraw(_token, msg.sender, _amount, tokens[_token][msg.sender]);
	}

	function balanceOf(address _token, address _user) public view returns (uint256) {
		return tokens[_token][_user];


	}

	function makeOrder(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive) public {
		orderCount = orderCount.add(1);

		orders[orderCount] = _Order(orderCount, msg.sender, _tokenGet, _amountGet, _tokenGive, _amountGive, now);
		emit Order(orderCount, msg.sender, _tokenGet, _amountGet, _tokenGive, _amountGive, now);
	}

	function cancelOrder(uint256 _id) public {
		
		_Order storage _order = orders[_id];
		require(address(_order.user) == msg.sender);
		require(_order.id == _id);
		 
		orderCancelled[_id] = true;
		emit Cancel(_order.id, msg.sender, _order.tokenGet, _order.amountGet, _order.tokenGive, _order.amountGive, now);
	}

	function fillOrder(uint256 _id) public {

		require(_id > 0 && _id <= orderCount);
		require(!orderFilled[_id]);
		require(!orderCancelled[_id]);
		_Order storage _order = orders[_id];
		_trade(_order.id, _order.user, _order.tokenGet, _order.amountGet, _order.tokenGive, _order.amountGive);
		orderFilled[_order.id] = true; 
		
		// makr order as filled


	}

	function _trade(uint256 _orderId, address _user, address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive)  internal {
		// fee paid by the user that fills the order, a.k.a msg.sender
		// fee deducted from _amountGet

		uint256 _feeAmount = _amountGive.mul(feePercent).div(100);

		// execute trade

		tokens[_tokenGet][msg.sender] = tokens[_tokenGet][msg.sender].sub(_amountGet.add(_feeAmount));
		tokens[_tokenGet][_user] = tokens[_tokenGet][_user].add(_amountGet);
		tokens[_tokenGet][feeAccount] = tokens[_tokenGet][feeAccount].add(_feeAmount);

		tokens[_tokenGive][_user] = tokens[_tokenGive][_user].sub(_amountGive);
		tokens[_tokenGive][msg.sender] = tokens[_tokenGive][msg.sender].add(_amountGive);
		emit Trade(_orderId, _user, _tokenGet, _amountGet, _tokenGive, _amountGive, msg.sender, now);
		// charge fees
		// emi trade event
	}
}


// Deposit & withdraw funds
// Manage orders -- make or cancel
// Handle trades -- charge fees
