defmodule EthExplorer.Ethereum.Transaction do
  @moduledoc """
  Handles Ethereum transaction operations including signing and encoding.
  """

  @doc """
  Signs an Ethereum transaction with a private key.

  ## Parameters
    - tx_params: Map containing transaction parameters (to, value, gas, gasPrice, nonce)
    - private_key: Hex string of private key with or without 0x prefix
    - chain_id: Integer chain ID of the network (1 for mainnet, usually specific values for dev networks)

  ## Returns
    - {:ok, signed_tx} - The signed transaction as a hex string
    - {:error, reason} - Error with reason
  """
  def sign_transaction(tx_params, private_key, chain_id \\ 1337) do
    try do
      # Ensure private key has proper format
      private_key = normalize_private_key(private_key)
      
      # Encode transaction data for signing (RLP format)
      rlp_encoded = encode_unsigned_tx(tx_params, chain_id)
      
      # Hash the encoded transaction
      tx_hash = ExKeccak.hash_256(rlp_encoded)
      
      # Sign the transaction hash with the private key
      case ExSecp256k1.sign_compact(tx_hash, private_key) do
        {:ok, {signature, recovery_id}} ->
          # Extract r and s from the 64-byte signature
          signature_r = binary_part(signature, 0, 32)
          signature_s = binary_part(signature, 32, 32)
          
          # Adjust the recovery ID for Ethereum format
          v = calculate_v(recovery_id, chain_id)
          
          # Create the signed transaction
          signed_tx = encode_signed_tx(tx_params, v, signature_r, signature_s, chain_id)
          
          {:ok, "0x" <> signed_tx}
          
        {:error, reason} ->
          {:error, "Failed to sign transaction: #{reason}"}
      end
    rescue
      e -> {:error, "Failed to sign transaction: #{inspect(e)}"}
    end
  end

  @doc """
  Derives an Ethereum address from a private key.
  
  ## Parameters
    - private_key: Hex string of private key with or without 0x prefix
  
  ## Returns
    - {:ok, address} - The derived address with 0x prefix
    - {:error, reason} - Error with reason
  """
  def derive_address(private_key) do
    try do
      # Normalize the private key
      private_key = normalize_private_key(private_key)
      
      # Get the public key from the private key
      case ExSecp256k1.create_public_key(private_key) do
        {:ok, public_key} ->
          # Remove the first byte (0x04 prefix for uncompressed keys)
          public_key = binary_part(public_key, 1, byte_size(public_key) - 1)
          
          # Hash the public key with Keccak-256
          public_key_hash = ExKeccak.hash_256(public_key)
          
          # Take the last 20 bytes (40 hex characters) and add 0x prefix
          address = "0x" <> Base.encode16(binary_part(public_key_hash, 12, 20), case: :lower)
          
          {:ok, address}
          
        {:error, reason} ->
          {:error, "Failed to create public key: #{reason}"}
      end
    rescue
      e -> {:error, "Failed to derive address: #{inspect(e)}"}
    end
  end

  # Private functions

  # Normalizes a private key to binary format
  defp normalize_private_key(private_key) do
    private_key = if String.starts_with?(private_key, "0x") do
      String.slice(private_key, 2..-1//1)
    else
      private_key
    end
    
    Base.decode16!(private_key, case: :mixed)
  end

  # Calculates the v value based on recovery ID and chain ID
  defp calculate_v(recovery_id, chain_id) do
    # EIP-155 formula: v = recovery_id + 35 + chain_id * 2
    recovery_id + 35 + (chain_id * 2)
  end

  # Encodes an unsigned transaction with RLP
  defp encode_unsigned_tx(tx_params, chain_id) do
    # Convert hex strings to integers where needed
    nonce = hex_to_int(tx_params["nonce"])
    gas_price = hex_to_int(tx_params["gasPrice"])
    gas_limit = hex_to_int(tx_params["gas"])
    value = hex_to_int(tx_params["value"])
    
    # Data is empty for simple ETH transfers
    data = tx_params["data"] || "0x"
    data = if String.starts_with?(data, "0x"), do: binary_part(Base.decode16!(String.slice(data, 2..-1//1), case: :mixed), 0, byte_size(Base.decode16!(String.slice(data, 2..-1//1), case: :mixed))), else: <<>>
    
    # Convert address to binary
    to_address = if tx_params["to"] do
      Base.decode16!(String.slice(tx_params["to"], 2..-1//1), case: :mixed)
    else
      <<>>  # Empty for contract creation
    end
    
    # RLP encode the transaction
    ExRLP.encode([
      nonce,
      gas_price,
      gas_limit,
      to_address,
      value,
      data,
      chain_id,
      0,
      0
    ])
  end

  # Encodes a signed transaction with RLP
  defp encode_signed_tx(tx_params, v, r, s, _chain_id) do
    # Convert hex strings to integers where needed
    nonce = hex_to_int(tx_params["nonce"])
    gas_price = hex_to_int(tx_params["gasPrice"])
    gas_limit = hex_to_int(tx_params["gas"])
    value = hex_to_int(tx_params["value"])
    
    # Data is empty for simple ETH transfers
    data = tx_params["data"] || "0x"
    data = if String.starts_with?(data, "0x"), do: binary_part(Base.decode16!(String.slice(data, 2..-1//1), case: :mixed), 0, byte_size(Base.decode16!(String.slice(data, 2..-1//1), case: :mixed))), else: <<>>
    
    # Convert address to binary
    to_address = if tx_params["to"] do
      Base.decode16!(String.slice(tx_params["to"], 2..-1//1), case: :mixed)
    else
      <<>>  # Empty for contract creation
    end
    
    # RLP encode the signed transaction
    signed_tx = ExRLP.encode([
      nonce,
      gas_price,
      gas_limit,
      to_address,
      value,
      data,
      v,
      r,
      s
    ])
    
    # Encode the result as hex
    Base.encode16(signed_tx, case: :lower)
  end

  # Converts a hex string to an integer
  defp hex_to_int(nil), do: 0
  defp hex_to_int("0x" <> hex), do: String.to_integer(hex, 16)
  defp hex_to_int(hex), do: String.to_integer(hex, 16)
end