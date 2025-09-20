# AcademicVote

AcademicVote is a decentralized platform for university governance and student organization decisions built on the Stacks blockchain using Clarity smart contracts. This platform enables transparent, secure, and tamper-proof voting processes for academic institutions.

## Features

- **Proposal Management**: Create and manage academic proposals with customizable voting durations
- **Weighted Voting**: Support for voting power based on user roles and stakes
- **Authorization System**: Role-based access control for proposal creation
- **Transparent Results**: Real-time vote tracking and immutable results
- **Emergency Controls**: Contract pause functionality for emergency situations
- **Multiple Proposal Types**: Support for different types of academic decisions
- **Time-bound Voting**: Configurable voting periods with automatic finalization
- **Vote Verification**: Prevent double voting and ensure voting eligibility

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity
- **Clarity Version**: 2
- **Epoch**: 2.5
- **Minimum Voting Duration**: 144 blocks (~24 hours)
- **Maximum Voting Duration**: 1008 blocks (~1 week)
- **Voting Power Threshold**: 1 unit minimum

## Project Structure

```
AcademicVote/
├── README.md
└── AcademicVote_contract/
    ├── contracts/
    │   └── AcademicVote.clar
    ├── settings/
    │   ├── Devnet.toml
    │   ├── Testnet.toml
    │   └── Mainnet.toml
    ├── tests/
    ├── Clarinet.toml
    ├── package.json
    └── tsconfig.json
```

## Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) for Stacks smart contract development
- Node.js (v16 or higher)
- npm or yarn

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd AcademicVote
```

2. Navigate to the contract directory:
```bash
cd AcademicVote_contract
```

3. Install dependencies:
```bash
npm install
```

4. Verify installation:
```bash
clarinet check
```

## Usage Examples

### Creating a Proposal

```clarity
;; Only authorized proposers or contract owner can create proposals
(contract-call? .AcademicVote create-proposal
  "Student Fee Increase"
  "Proposal to increase student activity fees by $50 per semester to fund new recreational facilities"
  u720  ;; 5 days voting period
  "fee-change"
)
```

### Voting on a Proposal

```clarity
;; Vote for proposal ID 1 (true = for, false = against)
(contract-call? .AcademicVote vote u1 true)
```

### Checking Proposal Results

```clarity
;; Get proposal details
(contract-call? .AcademicVote get-proposal u1)

;; Get voting results
(contract-call? .AcademicVote get-proposal-results u1)
```

### Setting Voting Power

```clarity
;; Contract owner can set voting power for users
(contract-call? .AcademicVote set-voting-power 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 u100)
```

## Contract Functions Documentation

### Public Functions

#### `set-voting-power (user principal) (power uint)`
Sets the voting power for a specific user. Can be called by the contract owner or the user themselves.
- **Parameters**:
  - `user`: Principal address of the user
  - `power`: Voting power amount
- **Returns**: `(response bool uint)`

#### `authorize-proposer (user principal)`
Authorizes a user to create proposals. Only callable by contract owner.
- **Parameters**: `user`: Principal address to authorize
- **Returns**: `(response bool uint)`

#### `revoke-proposer (user principal)`
Revokes proposal creation authorization from a user. Only callable by contract owner.
- **Parameters**: `user`: Principal address to revoke authorization
- **Returns**: `(response bool uint)`

#### `create-proposal (title description duration proposal-type)`
Creates a new proposal for voting.
- **Parameters**:
  - `title`: Proposal title (max 100 characters)
  - `description`: Proposal description (max 500 characters)
  - `duration`: Voting duration in blocks (144-1008 blocks)
  - `proposal-type`: Type of proposal (max 30 characters)
- **Returns**: `(response uint uint)` - Proposal ID on success

#### `vote (proposal-id vote-for)`
Casts a vote on an active proposal.
- **Parameters**:
  - `proposal-id`: ID of the proposal to vote on
  - `vote-for`: Boolean (true for yes, false for no)
- **Returns**: `(response bool uint)`

#### `finalize-proposal (proposal-id)`
Finalizes a proposal after voting period ends. Can be called by anyone.
- **Parameters**: `proposal-id`: ID of the proposal to finalize
- **Returns**: `(response string-ascii uint)`

#### `set-contract-paused (paused)`
Emergency pause/unpause functionality. Only callable by contract owner.
- **Parameters**: `paused`: Boolean to pause/unpause contract
- **Returns**: `(response bool uint)`

### Read-Only Functions

#### `get-proposal (proposal-id)`
Retrieves proposal details by ID.

#### `get-user-vote (proposal-id voter)`
Gets a user's vote on a specific proposal.

#### `get-voting-power (user)`
Returns the voting power of a user.

#### `is-authorized-proposer (user)`
Checks if a user is authorized to create proposals.

#### `get-proposal-counter()`
Returns the current proposal counter.

#### `is-contract-paused()`
Checks if the contract is currently paused.

#### `get-proposal-results (proposal-id)`
Gets voting results for a proposal.

#### `is-proposal-active (proposal-id)`
Checks if a proposal is currently active for voting.

## Deployment Guide

### Local Development

1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy the contract:
```clarity
::deploy_contract AcademicVote contracts/AcademicVote.clar
```

### Testnet Deployment

1. Configure testnet settings in `settings/Testnet.toml`
2. Deploy using Clarinet:
```bash
clarinet deployments generate --testnet
clarinet deployments apply --testnet
```

### Mainnet Deployment

1. Configure mainnet settings in `settings/Mainnet.toml`
2. Deploy using Clarinet:
```bash
clarinet deployments generate --mainnet
clarinet deployments apply --mainnet
```

## Testing

Run the test suite:
```bash
npm test
```

Run tests with coverage:
```bash
npm run test:report
```

Watch mode for development:
```bash
npm run test:watch
```

## Security Notes

### Important Security Considerations

1. **Access Control**: The contract implements role-based access control. Only authorized proposers can create proposals, and only the contract owner can manage authorizations.

2. **Vote Integrity**: Each user can only vote once per proposal, and votes are recorded with timestamps and voting power.

3. **Time Bounds**: Proposals have strict time boundaries to prevent manipulation of voting periods.

4. **Emergency Pause**: The contract includes an emergency pause mechanism that can halt all operations if needed.

5. **Voting Power Threshold**: A minimum voting power threshold prevents spam voting.

### Best Practices

- Regularly audit authorized proposers
- Monitor contract activity for unusual patterns
- Use the emergency pause function judiciously
- Implement proper off-chain verification for proposal content
- Consider implementing additional governance layers for high-stakes decisions

### Known Limitations

- Voting power must be set manually by the contract owner or users
- No automatic delegation mechanism
- Proposals cannot be modified once created
- No built-in quorum requirements

## Error Codes

- `ERR-NOT-AUTHORIZED (100)`: Caller not authorized for this action
- `ERR-PROPOSAL-NOT-FOUND (101)`: Proposal ID does not exist
- `ERR-VOTING-CLOSED (102)`: Voting period has ended
- `ERR-ALREADY-VOTED (103)`: User has already voted on this proposal
- `ERR-INVALID-DURATION (104)`: Voting duration outside allowed range
- `ERR-INSUFFICIENT-BALANCE (105)`: Insufficient voting power
- `ERR-PROPOSAL-ENDED (106)`: Proposal voting period has ended
- `ERR-PROPOSAL-NOT-ENDED (107)`: Proposal voting period has not ended

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Run the test suite
6. Submit a pull request

## License

This project is licensed under the ISC License.

## Contact

For questions, issues, or contributions, please open an issue on the repository or contact the development team.