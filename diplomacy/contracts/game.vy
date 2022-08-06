enum Map:
  ADR
  AEG
  ALB
  ANK
  APU
  ARM
  BAL
  BAR
  BEL
  BER
  BLA
  BOH
  BRE
  BUD
  BUL
  BUR
  CLY
  CON
  DEN
  EAS
  ECH
  EDI
  FIN
  GAL
  GAC # Gascony
  GOB
  GOL
  GRE
  HEL
  HOL
  ION
  IRI
  KIE
  LON
  LVN
  LVP
  MAO
  MAR
  MOS
  MUN
  NAF
  NAO
  NAP
  NTH
  NWG
  NWY
  PAR
  PIC
  PIE
  POR
  PRU
  ROM
  RUH
  RUM
  SER
  SEV
  SIL
  SKA
  SMY
  SPA
  STP
  SWE
  SYR
  TRI
  TUN
  TUS
  TYR
  TYS
  UKR
  VEN
  VIE
  WAL
  WAR
  WES
  YOR

enum Order:
  BLD # Build
  CTO # Move by Convoy
  CVY # Convoy
  BSD # Disband
  HLD # Hold
  MTO # Move to
  RTO # Retreat to
  SUP # Support

enum Unit:
  FLT # Fleet
  AMY # Army

struct Move:
  position: Map
  order: Order
  target: Map

struct Position: 
  country: uint8
  unit: Unit

buyIn: uint256
commitlimit: uint256
reveallimit: uint256
maxNMR: uint256

players: HashMap[uint8, address]
commits: HashMap[uint8, bytes32]
reveals: HashMap[uint8, DynArray[Move, 18]]
claims: HashMap[uint8, uint256]
missed: HashMap[uint8, uint256]

completed: bool
deadline: uint256
phase: uint256
state: HashMap[Map, Position]

@external
def __init__(buyIn: uint256, commitlimit: uint256, reveallimit: uint256, maxNMR: uint256):
  self.buyIn = buyIn
  self.commitlimit = commitlimit
  self.reveallimit = reveallimit
  self.maxNMR = maxNMR

@external
@payable
def join(country: uint8):
  assert msg.value >= self.buyIn, "Game requires buy-in"
  assert self.players[country] == 0x0000000000000000000000000000000000000000, "Country already selected"
  self.players[country] = msg.sender
  self.claims[country] = self.buyIn

@external
def start():
  for i in range(8):
    assert self.players[i] != 0x0000000000000000000000000000000000000000, "Not enough players to start"
  self.deadline = block.timestamp + self.commitlimit

@external
def commit(country: uint8, commitment: bytes32, claim: uint256):
  assert self.deadline != 0, "Game has not started yet"
  assert block.timestamp < self.deadline, "Deadline has passed"
  assert not self.completed, "Game has finished"
  assert self.players[country] == msg.sender, "Invalid sender"
  assert self.claims[country] != 0, "Player has already left the game"
  self.commits[country] = commitment
  self.claims[country] = claim

@external
def finalizeCommits():
  for i in range(8):
    if self.claims[i] > 0 and self.commits[i] == 0x0000000000000000000000000000000000000000000000000000000000000000:
      return
  self.deadline = block.timestamp

@external
def reveal(country: uint8, moves: DynArray[Move, 18], salt: bytes32):
  assert self.players[country] == msg.sender, "Invalid sender"
  assert block.timestamp < self.deadline + self.reveallimit, "Deadline has passed"
  assert keccak256(concat(_abi_encode(moves), salt)) == self.commits[country]
  self._validateMoves(moves)
  self.reveals[country] = moves

@internal
def _validateMoves(moves: DynArray[Move, 18]):
  pass

@external
def resolve():
  self._resolveMoves()
  self._checkNMR()
  self._checkCompleted()
  self._resetMoves()

@internal
def _resolveMoves():
  pass

@internal
def _setDefeated(country: uint8):
  self.claims[country] = 0

@internal
def _checkNMR():
  if self.maxNMR == 0:
    return
  for i in range(8):
    moves: DynArray[Move, 18] = self.reveals[i]
    if len(moves) == 0:
      self.missed[i] += 1
      if self.missed[i] > self.maxNMR:
        self.claims[i] = 0

@internal
def _checkCompleted():
  totalClaims: uint256 = 0
  for i in range(8):
    totalClaims += self.claims[i]
  if totalClaims <= self.balance:
    self.completed = True
    factor: uint256 = self.balance / totalClaims
    for i in range(8):
      self.claims[i] = self.claims[i] * factor  

@internal
def _resetMoves():
  if self.completed:
    return
  for i in range(8):
    self.commits[i] = 0x0000000000000000000000000000000000000000000000000000000000000000
    self.reveals[i] = []

@external
def withdraw(country: uint8):
  assert self.completed, "Game still on-going"
  assert self.players[country] == msg.sender, "Invalid address"
  claim: uint256 = self.claims[country]
  assert claim > 0, "Defeated cannot claim"
  send(msg.sender, claim)