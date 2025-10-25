# 🏛️ NFT-based Ancestry & Culture Project

A Clarity smart contract that enables users to mint NFTs linked to family heritage stories and historical contributions, creating a digital archive of cultural heritage.

## 🌟 Features

- **🎭 Heritage Story NFTs**: Mint NFTs with detailed family heritage stories
- **📚 Historical Contributions**: Link NFTs to historical contributions and achievements  
- **✅ Verification System**: Trusted verifiers can validate heritage stories and contributions
- **🔐 Ownership Management**: Full NFT ownership and transfer capabilities
- **🎨 Metadata Support**: Rich metadata for stories, locations, and cultural significance
- **👥 Multi-role Access**: Contract owner, verifiers, and regular users

## 🚀 Quick Start

### Prerequisites
- Clarinet installed
- Stacks wallet for testing

### Installation
1. Clone the repository
2. Run `clarinet console` to interact with the contract

## 📖 Usage

### Minting an Ancestry NFT

```clarity
(contract-call? .NFT-ANCESTRY mint-ancestry-nft
    'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM  ;; recipient
    "https://example.com/metadata.json"            ;; URI
    "Great Grandmother's Journey"                   ;; story title
    "She immigrated from Ireland in 1920..."       ;; story content
    "County Cork, Ireland"                          ;; location
    "1920-1930"                                     ;; time period
    "First generation Irish-American family"       ;; cultural significance
    "Mary O'Sullivan"                               ;; contributor name
    "Community Builder"                             ;; contribution type
    "Established the first Irish cultural center"  ;; contribution description
    "Early 20th Century"                           ;; historical period
    "High"                                          ;; impact level
)
```

### Transferring an NFT

```clarity
(contract-call? .NFT-ANCESTRY transfer
    u1                                              ;; token ID
    tx-sender                                       ;; sender
    'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM   ;; recipient
)
```

### Verifying Heritage Stories

```clarity
;; Only verifiers can call this
(contract-call? .NFT-ANCESTRY verify-heritage-story u1)
```

### Updating Heritage Stories

```clarity
;; Only token owner can update
(contract-call? .NFT-ANCESTRY update-heritage-story
    u1                                              ;; token ID
    "Updated Story Title"                           ;; new title
    "Updated story content..."                      ;; new content
    "Updated location"                              ;; new location
    "Updated time period"                           ;; new time period
    "Updated cultural significance"                 ;; new significance
)
```

## 🏗️ Contract Structure

### Data Storage
- **Heritage Stories**: Title, content, location, time period, cultural significance
- **Historical Contributions**: Contributor name, type, description, period, impact level
- **Verification Status**: Tracks if stories/contributions are verified
- **NFT Metadata**: Token URIs and ownership information

### Key Functions

#### 🔹 Read-Only Functions
- `get-heritage-story(token-id)`: Get heritage story details
- `get-historical-contribution(token-id)`: Get contribution details
- `get-owner(token-id)`: Get NFT owner
- `get-contract-info()`: Get contract statistics

#### 🔹 Public Functions
- `mint-ancestry-nft(...)`: Mint new NFT with heritage data
- `transfer(token-id, sender, recipient)`: Transfer NFT
- `verify-heritage-story(token-id)`: Verify story (verifiers only)
- `verify-historical-contribution(token-id)`: Verify contribution (verifiers only)
- `update-heritage-story(...)`: Update story (owner only)
- `update-historical-contribution(...)`: Update contribution (owner only)

#### 🔹 Admin Functions
- `add-verifier(verifier)`: Add trusted verifier (owner only)
- `remove-verifier(verifier)`: Remove verifier (owner only)
- `set-mint-enabled(enabled)`: Enable/disable minting (owner only)

## 🔒 Security Features

- **Ownership Verification**: Only token owners can update their NFTs
- **Verifier System**: Trusted verifiers validate heritage content
- **Admin Controls**: Contract owner manages verifiers and minting
- **Input Validation**: Ensures metadata meets minimum requirements

## 🧪 Testing

Run tests with Clarinet:
```bash
clarinet test
```

## 📊 Error Codes

- `u100`: Owner only operation
- `u101`: Not token owner
- `u102`: Token already exists
- `u103`: Token not found
- `u104`: Invalid metadata
- `u105`: Story not found
- `u106`: Contribution not found
- `u107`: Not approved
- `u108`: Minting disabled

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

This project is open source and available under the MIT License.

## 🙏 Acknowledgments

Built with ❤️ for preserving cultural heritage and family stories through blockchain technology.
