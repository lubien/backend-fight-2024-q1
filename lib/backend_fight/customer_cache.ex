defmodule BackendFight.CustomerCache do
  use GenServer

  # Public API

  # Ensure that the guid has the correct data
  def set_customer_cache(key, data) do
    Cachex.put(:customer_cache, key, data)
  end

  def get_customer_cache(key) do
    case Cachex.get(:customer_cache, key) do
      {:ok, data} -> data
      _ ->  nil
     end
  end

  def fetch_customer_cache(key, func) do
    Cachex.fetch(:customer_cache, key, func)
  end

  def get_and_update_customer_cache!(key, func) do
    cached = get_customer_cache(key)
    with {:commit, data} <- func.(cached) do
      set_customer_cache_and_broadcast(key, data)
      data
    end
  end

  # To avoid local race conditions with the pubsub broadcast, we set locally first
  def set_customer_cache_and_broadcast(key, prefs) do
    set_customer_cache(key, prefs)
    Phoenix.PubSub.broadcast(BackendFight.PubSub, "cache", {:set_customer_cache, key, prefs})
  end

  def clear_all_caches() do
    Cachex.clear(:customer_cache)
    Phoenix.PubSub.broadcast(BackendFight.PubSub, "cache", {:clear_cache})
  end

  # GenServer Spec

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [])
  end

  def init(init_arg) do
    Phoenix.PubSub.subscribe(BackendFight.PubSub, "cache")
    {:ok, init_arg}
  end

  def handle_info({:set_customer_cache, key, data}, _state) do
   Cachex.put(:customer_cache, key, data)
   {:noreply, nil}
  end

  def handle_info({:clear_cache}, _state) do
    Cachex.clear(:customer_cache)
    {:noreply, nil}
  end
end
