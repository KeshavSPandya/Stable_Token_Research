import { BigInt, Bytes } from "@graphprotocol/graph-ts"
import {
  Swap as SwapEvent,
  RouteUpdated
} from "../generated/PSM/PSM"
import {
  AllocatorMint,
  AllocatorRepay,
  LineUpdated
} from "../generated/AllocatorVault/AllocatorVault"
import {
  Deposit,
  Withdraw
} from "../generated/SavingsVault/SavingsVault"
import {
  AddressParamUpdated,
  UintParamUpdated,
  BoolParamUpdated
} from "../generated/ParamRegistry/ParamRegistry"
import { Transfer } from "../generated/OxUSD/OxUSD"
import {
  SystemState,
  Swap,
  PSMRoute,
  Allocator,
  AllocatorAction,
  User,
  SavingsAction,
} from "../generated/schema"

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

function getSystemState(): SystemState {
  let state = SystemState.load("0xUSD");
  if (state == null) {
    state = new SystemState("0xUSD");
    state.totalSupply = BigInt.fromI32(0);
  }
  return state;
}

//--- PSM Handlers ---//

export function handleSwap(event: SwapEvent): void {
  let swap = new Swap(event.transaction.hash.toHex());
  swap.user = event.params.user;
  swap.stable = event.params.stable;
  swap.amountIn = event.params.amountIn;
  swap.amountOut = event.params.amountOut;
  swap.feeAmount = event.params.feeAmount;
  swap.timestamp = event.block.timestamp;
  swap.save();

  let route = PSMRoute.load(event.params.stable.toHex());
  if (route != null) {
    // A mint increases the buffer, a redeem decreases it.
    // We can infer this from the event parameters, but for now we'll just update from the contract state.
    // This part would need the contract instance to call `routes(stable)`.
    // For simplicity, we'll assume the buffer updates are handled externally or via a different mechanism.
  }
}

export function handleRouteUpdated(event: RouteUpdated): void {
  let route = PSMRoute.load(event.params.stable.toHex());
  if (route == null) {
    route = new PSMRoute(event.params.stable.toHex());
  }
  route.maxDepth = event.params.maxDepth;
  route.spreadBps = BigInt.fromI32(event.params.spreadBps);
  route.save();
}

//--- AllocatorVault Handlers ---//

export function handleAllocatorMint(event: AllocatorMint): void {
  let allocator = Allocator.load(event.params.allocator.toHex());
  if (allocator != null) {
    allocator.debt = allocator.debt.plus(event.params.amount);
    allocator.save();
  }

  let action = new AllocatorAction(event.transaction.hash.toHex());
  action.type = "MINT";
  action.allocator = event.params.allocator.toHex();
  action.to = event.params.to;
  action.amount = event.params.amount;
  action.timestamp = event.block.timestamp;
  action.save();
}

export function handleAllocatorRepay(event: AllocatorRepay): void {
  let allocator = Allocator.load(event.params.allocator.toHex());
  if (allocator != null) {
    allocator.debt = allocator.debt.minus(event.params.amount);
    allocator.save();
  }

  let action = new AllocatorAction(event.transaction.hash.toHex());
  action.type = "REPAY";
  action.allocator = event.params.allocator.toHex();
  action.repayer = event.params.repayer;
  action.amount = event.params.amount;
  action.timestamp = event.block.timestamp;
  action.save();
}

export function handleLineUpdated(event: LineUpdated): void {
  let allocator = Allocator.load(event.params.allocator.toHex());
  if (allocator == null) {
    allocator = new Allocator(event.params.allocator.toHex());
    allocator.debt = BigInt.fromI32(0);
  }
  allocator.ceiling = event.params.ceiling;
  allocator.dailyCap = event.params.dailyCap;
  allocator.save();
}

//--- SavingsVault Handlers ---//

export function handleDeposit(event: Deposit): void {
  let user = User.load(event.params.sender.toHex());
  if (user == null) {
    user = new User(event.params.sender.toHex());
    user.s0xUSD_balance = BigInt.fromI32(0);
  }
  user.s0xUSD_balance = user.s0xUSD_balance.plus(event.params.shares);
  user.save();

  let action = new SavingsAction(event.transaction.hash.toHex() + "-" + event.logIndex.toString());
  action.type = "DEPOSIT";
  action.user = event.params.sender.toHex();
  action.owner = event.params.owner;
  action.assets = event.params.assets;
  action.shares = event.params.shares;
  action.timestamp = event.block.timestamp;
  action.save();
}

export function handleWithdraw(event: Withdraw): void {
    let user = User.load(event.params.sender.toHex());
    if (user != null) {
        user.s0xUSD_balance = user.s0xUSD_balance.minus(event.params.shares);
        user.save();
    }

    let action = new SavingsAction(event.transaction.hash.toHex() + "-" + event.logIndex.toString());
    action.type = "WITHDRAW";
    action.user = event.params.sender.toHex();
    action.owner = event.params.owner;
    action.assets = event.params.assets;
    action.shares = event.params.shares;
    action.timestamp = event.block.timestamp;
    action.save();
}

//--- 0xUSD Transfer Handler for Total Supply ---//

export function handleTransfer(event: Transfer): void {
  let state = getSystemState();
  if (event.params.from.toHex() == ZERO_ADDRESS) {
    // Mint
    state.totalSupply = state.totalSupply.plus(event.params.value);
  }
  if (event.params.to.toHex() == ZERO_ADDRESS) {
    // Burn
    state.totalSupply = state.totalSupply.minus(event.params.value);
  }
  state.save();
}

//--- ParamRegistry Handlers (example) ---//
// In a real implementation, you would have handlers for each param update event.
// For brevity, we'll omit them here, but they would follow a similar pattern
// to the handlers above, creating AddressParamUpdated, etc. entities.
