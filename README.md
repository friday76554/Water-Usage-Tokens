# 💧 Water Usage Tokens (WUT)

A smart contract system for tracking water consumption and incentivizing conservation through tokenized rewards.

## 🚀 Features

- 🏠 **Water Meter Registration**: Register your water meter with location tracking
- 📊 **Usage Monitoring**: Submit and validate water consumption readings
- 🪙 **Token Rewards**: Earn tokens based on your water usage patterns
- 🎯 **Tier System**: Progress through 5 consumption tiers with increasing rewards
- ⚡ **Penalty System**: Automatic penalties for excessive water usage
- 💰 **Token Trading**: Buy, sell, and transfer water usage tokens
- 📈 **Analytics**: Track consumption history and efficiency metrics

## 🏗️ Contract Functions

### Core Token Operations
- `get-balance(owner)` - Check token balance
- `transfer(amount, sender, recipient, memo)` - Transfer tokens
- `purchase-tokens(amount)` - Buy tokens with STX
- `redeem-tokens(amount)` - Burn tokens for STX refund

### Water Meter Management
- `register-water-meter(meter-id, location)` - Register a new meter
- `submit-water-reading(consumption-amount, reading-type)` - Submit usage data
- `validate-reading(reading-id, is-valid)` - Validate submitted readings (owner only)
- `set-meter-status(owner, active)` - Enable/disable meters (owner only)
- `transfer-meter-ownership(new-owner)` - Transfer meter to new owner

### Rewards & Penalties
- `apply-consumption-reward(user)` - Apply tier-based rewards (owner only)
- `apply-usage-penalty(user, penalty-id)` - Apply penalties for overuse (owner only)
- `set-consumption-reward(tier, min, max, rate)` - Configure reward tiers (owner only)
- `set-usage-penalty(penalty-id, type, threshold, rate, desc)` - Set penalty rules (owner only)

### Analytics & Utilities
- `get-meter-efficiency(owner)` - Calculate consumption per block
- `calculate-water-bill(user)` - Estimate water bill based on usage
- `get-monthly-consumption(user, month, year)` - Monthly usage stats
- `get-reading-history(user, limit)` - Retrieve consumption history

## 🏆 Tier System

| Tier | Consumption Range | Reward Rate |
|------|------------------|-------------|
| 1    | 0 - 500 gallons  | 10 tokens/gallon |
| 2    | 501 - 2,000      | 15 tokens/gallon |
| 3    | 2,001 - 5,000    | 20 tokens/gallon |
| 4    | 5,001 - 10,000   | 25 tokens/gallon |
| 5    | 10,001+          | 30 tokens/gallon |

## ⚠️ Penalty Types

- **Excessive Usage**: >15,000 gallons (10% token penalty)
- **Wasteful Practices**: >20,000 gallons (15% token penalty)
- **Commercial Overuse**: >50,000 gallons (5% token penalty)

## 🛠️ Usage Instructions

### 1. Register Your Water Meter
```clarity
(contract-call? .Water-Usage-Tokens register-water-meter "METER-001" u"123 Main St, Apt 4B")
```

### 2. Submit Water Readings
```clarity
(contract-call? .Water-Usage-Tokens submit-water-reading u250 "monthly")
```

### 3. Purchase Tokens
```clarity
(contract-call? .Water-Usage-Tokens purchase-tokens u100)
```

### 4. Check Your Balance
```clarity
(contract-call? .Water-Usage-Tokens get-balance tx-sender)
```

## 🔧 Development

### Prerequisites
- Clarinet CLI installed
- Node.js for testing

### Setup
```bash
clarinet new water-usage-project
cd water-usage-project
```

### Testing
```bash
clarinet check
npm install
npm test
```

### Deployment
```bash
clarinet deploy --testnet
```

## 📋 Contract Details

- **Token Name**: Water Usage Token
- **Symbol**: WUT
- **Decimals**: 6
- **Base Token Price**: 1,000,000 microSTX
- **Initial Supply**: Minted based on validated consumption

## 🔐 Security Features

- Owner-only administrative functions
- Emergency pause/unpause functionality
- Input validation on all public functions
- Protected against unauthorized access

## 📄 License

MIT License - see LICENSE file for details
