# @version ^0.3.4

# External Interfaces

# Variables
BLUEPRINT: immutable(address)

@external
def __init__(blueprint: address):
  BLUEPRINT = blueprint

@external
@payable
def createGame(buyIn: uint256, commitlimit: uint256, reveallimit: uint256, maxNMR: uint256) -> address:
  # Using code_offset=3 for titanoboa
  game: address = create_from_blueprint(BLUEPRINT, buyIn, commitlimit, reveallimit, maxNMR, code_offset=3)
  return game
