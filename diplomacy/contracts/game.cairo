%lang starknet

from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.cairo_builtins import HashBuiltin

from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math import assert_in_range

struct MapEnum:
  member ADR: felt
  member AEG: felt
  member ALB: felt
  member ANK: felt
  member APU: felt
  member ARM: felt
  member BAL: felt
  member BAR: felt
  member BEL: felt
  member BER: felt
  member BLA: felt
  member BOH: felt
  member BRE: felt
  member BUD: felt
  member BUL: felt
  member BUR: felt
  member CLY: felt
  member CON: felt
  member DEN: felt
  member EAS: felt
  member ECH: felt
  member EDI: felt
  member FIN: felt
  member GAL: felt
  member GAS: felt
  member GOB: felt
  member GOL: felt
  member GRE: felt
  member HEL: felt
  member HOL: felt
  member ION: felt
  member IRI: felt
  member KIE: felt
  member LON: felt
  member LVN: felt
  member LVP: felt
  member MAO: felt
  member MAR: felt
  member MOS: felt
  member MUN: felt
  member NAF: felt
  member NAO: felt
  member NAP: felt
  member NTH: felt
  member NWG: felt
  member NWY: felt
  member PAR: felt
  member PIC: felt
  member PIE: felt
  member POR: felt
  member PRU: felt
  member ROM: felt
  member RUH: felt
  member RUM: felt
  member SER: felt
  member SEV: felt
  member SIL: felt
  member SKA: felt
  member SMY: felt
  member SPA: felt
  member STP: felt
  member SWE: felt
  member SYR: felt
  member TRI: felt
  member TUN: felt
  member TUS: felt
  member TYR: felt
  member TYS: felt
  member UKR: felt
  member VEN: felt
  member VIE: felt
  member WAL: felt
  member WAR: felt
  member WES: felt
  member YOR: felt
end
    
struct OrderEnum:
  member BLD: felt # Build
  member CTO: felt # Move by Convoy
  member CVY: felt # Convoy
  member BSD: felt # Disband
  member HLD: felt # Hold
  member MTO: felt # Move to
  member RTO: felt # Retreat to
  member SUP: felt # Support
end

struct UnitEnum:
  member FLT: felt
  member AMY: felt
end

struct MoveStruct:
  member position: MapEnum
  member order: OrderEnum
  member target: MapEnum
end

struct Position:
  member country: felt
  member unit: UnitEnum
end

# Stores the address of the owner of the contract
@storage_var
func owner() -> (owner_address : felt):
end

# Maps the address of a user to the number of answers they have correct
@storage_var
func winsByAddr(address : felt) -> (numCorrect : felt):
end

# Last winning address of the game
@storage_var
func lastWinner() -> (address : felt):
end

# Stores the current number to be solved
@storage_var
func currNumber() -> (res : felt):
end

# Stores whether the current number is active
@storage_var
func isActive() -> (res : felt):
end

# Constructor for the contract that is called when the contract is deployed
# Argument owner_address Address of the owner of the contract
# Set isActive and currNumber to be solved
@constructor
func constructor{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(owner_address : felt):
    owner.write(value=owner_address)
    isActive.write(1)
    currNumber.write(1234)
    return ()
end

@view
func getOwner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (ownerAddr : felt):
    let (ownerAddr) = owner.read()
    return (ownerAddr=ownerAddr)
end

# Gets the current number to guess
# Return currNumber
@view
func getCurrNumber{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (currNum : felt):
    let (currNum) = currNumber.read()
    return (currNum=currNum)
end

# Gets whether the game is active
# Return isActive - 1 if true, 0 if false
@view
func getIsActive{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (isActiveBool : felt):
    let (isActiveBool) = isActive.read()
    return (isActiveBool=isActiveBool)
end

# Gets the last winning address
# Return lastWinner
@view
func getLastWinner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (lastWinningAddr : felt):
    let (lastWinningAddr) = lastWinner.read()
    return (lastWinningAddr=lastWinningAddr)
end

# Gets the number of wins a user's addr has
# Return number of wins a user has
@view
func getNumberWins{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(address : felt)  -> (numWins : felt):
    let (numWins) = winsByAddr.read(address)
    return (numWins=numWins)
end

# Check a user's answer
# Argument userAnswer the sum of the digits as added by the user
# Return whether the answer is correct, if correct return 1, else 0
@external
func verifySum{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(userAnswer : felt) -> (isCorrect : felt):
    alloc_locals
    #Ensure the game is active, if not assertion will fail
    let (activeBool) = isActive.read()
    with_attr error_message("This game is not active"):
        assert activeBool = 1
    end
    #Get the current number and the result of finding sum of the digits
    let (currNum) = currNumber.read()
    let (res) = findSumDigits(currNum, 0)
    #If userAnswer = res, then that address has won the round and the game is no longer active
    if res == userAnswer:
        let (caller) = get_caller_address()
        isActive.write(0)
        let (currAddrWins) = winsByAddr.read(caller)
        winsByAddr.write(caller, currAddrWins+1)
        lastWinner.write(caller)
        return (isCorrect=1)
    end
    #If the user did not win the round return 0 as a false value to the front end
    return (isCorrect=0)
end

# Update the current number that users will try to sum the digits	
# Argument updatedNum the new number for users to work with	
@external	
func updateCurrNum{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(updatedNum : felt):	
    let (ownerBool) = isOwner()	
    with_attr error_message("This game is not active"):	
        assert ownerBool = 1	
    end	
    isActive.write(1)	
    currNumber.write(updatedNum)	
    return ()	
end	

# Gets whether the calling address is the owner of the contract	
# Return 1 if true, 0 otherwise
@view
func isOwner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (isOwner : felt):
    let (caller) = get_caller_address()
    let (ownerAddr) = owner.read()
    if caller == ownerAddr:
        return (isOwner=1)
    end
    return (isOwner=0)
end

#Recursively find the sum of the digits
func findSumDigits{range_check_ptr}(inputNum : felt, currSum : felt) -> (res : felt):
    #create base case
    if inputNum == 0:
        return (currSum)
    end
    #get your unsigned remainder of dividing by 10, this is the ones digit
    let (q,r) = unsigned_div_rem(inputNum, 10)
    #add the ones digit to the sum
    let updatedCurrSum = currSum + r
    #update the input to knock off the ones digit and recurse
    let updatedInput = (inputNum-r)/10
    let (res) = findSumDigits(updatedInput, updatedCurrSum) 
    return (res=res)
end