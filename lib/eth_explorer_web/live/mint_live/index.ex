defmodule EthExplorerWeb.MintLive.Index do
  use EthExplorerWeb, :live_view

  alias EthExplorer.Ethereum.Client
  alias EthExplorer.Ethereum.Transaction

  @chain_id 1337  # Besu dev network default chain ID

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Mint Tokens")
     |> assign(:private_key, "")
     |> assign(:to_address, "")
     |> assign(:amount, "")
     |> assign(:tx_hash, nil)
     |> assign(:error, nil)}
  end

  @impl true
  def handle_event("mint", %{"mint" => %{"private_key" => private_key, "to_address" => to_address, "amount" => amount}}, socket) do
    # Simple validation
    private_key = String.trim(private_key)
    to_address = String.trim(to_address)
    
    # Check if private key is valid
    valid_private_key = cond do
      String.starts_with?(private_key, "0x") -> 
        String.length(private_key) == 66
      true -> 
        String.length(private_key) == 64
    end
    
    cond do
      !valid_private_key ->
        {:noreply, assign(socket, error: "Invalid private key format. Must be 64 hex characters, with or without 0x prefix.")}
      
      !String.starts_with?(to_address, "0x") || String.length(to_address) != 42 ->
        {:noreply, assign(socket, error: "Invalid address format. Must start with 0x followed by 40 hex characters.")}
      
      !is_numeric(amount) ->
        {:noreply, assign(socket, error: "Amount must be a valid number.")}
      
      true ->
        # Attempt to send transaction
        case send_transaction(private_key, to_address, amount) do
          {:ok, tx_hash} ->
            {:noreply, 
             socket
             |> assign(:tx_hash, tx_hash)
             |> assign(:error, nil)}
          
          {:error, error} ->
            {:noreply, 
             socket
             |> assign(:tx_hash, nil)
             |> assign(:error, error)}
        end
    end
  end
  
  defp is_numeric(str) do
    case Float.parse(str) do
      {_num, ""} -> true
      {_num, "."} -> true
      {_num, _rest} -> false
      :error -> false
    end
  end

  defp send_transaction(private_key, to_address, amount) do
    # First get address from private key 
    case Transaction.derive_address(private_key) do
      {:ok, from_address} ->
        # Get nonce for the address
        case Client.get_transaction_count(from_address) do
          {:ok, nonce} ->
            # Convert amount to wei
            wei_amount = eth_to_wei(amount)
            
            # Create transaction
            # Fetch current gas price to ensure transaction goes through
            gas_price = case Client.get_gas_price() do
              {:ok, price} -> integer_to_hex(price)
              _ -> "0x3b9aca00"  # Fallback to 1 Gwei
            end
            
            tx = %{
              "from" => from_address,
              "to" => to_address,
              "value" => wei_amount,
              "gas" => "0x5208",  # 21,000 gas (standard ETH transfer)
              "gasPrice" => gas_price,
              "nonce" => integer_to_hex(nonce)
            }
            
            # Sign the transaction
            case Transaction.sign_transaction(tx, private_key, @chain_id) do
              {:ok, signed_tx} ->
                # Send the raw transaction
                case Client.send_raw_transaction(signed_tx) do
                  {:ok, tx_hash} -> 
                    # Transaction was successful
                    {:ok, tx_hash}
                  
                  {:error, %{"code" => code, "message" => message}} -> 
                    # Handle specific error codes with helpful messages
                    error_message = case code do
                      -32000 -> "Transaction underpriced. Try increasing the gas price."
                      -32001 -> "Transaction nonce too low. Try refreshing the page and resubmit."
                      -32002 -> "Transaction nonce too high. Try refreshing the page and resubmit."
                      -32003 -> "Insufficient funds for gas * price + value."
                      -32010 -> "Transaction gas too low. Try increasing gas limit."
                      _ -> "Transaction error (#{code}): #{message}"
                    end
                    {:error, error_message}
                  
                  {:error, error} -> 
                    # Generic error handling
                    {:error, "Failed to send transaction: #{inspect(error)}"}
                end
                
              {:error, reason} ->
                {:error, "Transaction signing error: #{reason}"}
            end
          
          {:error, error} ->
            {:error, "Failed to get nonce: #{inspect(error)}"}
        end
        
      {:error, reason} ->
        {:error, "Failed to derive address: #{reason}"}
    end
  end

  defp eth_to_wei(eth_str) do
    {eth_float, _} = Float.parse(eth_str)
    wei = eth_float * 1.0e18
    "0x" <> Integer.to_string(round(wei), 16)
  end

  defp integer_to_hex(value) do
    "0x" <> Integer.to_string(value, 16)
  end
end