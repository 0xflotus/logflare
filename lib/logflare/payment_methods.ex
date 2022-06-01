defmodule Logflare.PaymentMethods do
  @moduledoc """
  The PaymentMethods context.
  """

  import Ecto.Query, warn: false
  alias Logflare.Repo
  alias Logflare.Billing

  alias Logflare.PaymentMethods.PaymentMethod

  def list_payment_methods_by(kv) do
    PaymentMethod
    |> where(^kv)
    |> Repo.all()
  end

  def get_payment_method_by(kv) do
    PaymentMethod
    |> Repo.get_by(kv)
  end

  def delete_all_payment_methods_by(kv) do
    PaymentMethod
    |> where(^kv)
    |> Repo.delete_all()
  end

  def sync_payment_methods(customer_id) do
    with {:ok, %Stripe.List{data: payment_methods}} <-
           Billing.Stripe.list_payment_methods(customer_id),
         {_count, _response} <-
           delete_all_payment_methods_by(customer_id: customer_id) do
      methods_list =
        Enum.map(payment_methods, fn x ->
          {:ok, payment_method} =
            create_payment_method(%{
              stripe_id: x.id,
              customer_id: x.customer,
              last_four: x.card.last4,
              exp_month: x.card.exp_month,
              exp_year: x.card.exp_year,
              brand: x.card.brand
            })

          payment_method
        end)

      {:ok, methods_list}
    else
      err -> err
    end
  end

  @doc """
  Returns the list of payment_methods.

  ## Examples

      iex> list_payment_methods()
      [%PaymentMethod{}, ...]

  """
  def list_payment_methods do
    Repo.all(PaymentMethod)
  end

  @doc """
  Gets a single payment_method.

  Raises `Ecto.NoResultsError` if the Payment method does not exist.

  ## Examples

      iex> get_payment_method!(123)
      %PaymentMethod{}

      iex> get_payment_method!(456)
      ** (Ecto.NoResultsError)

  """
  def get_payment_method!(id), do: Repo.get!(PaymentMethod, id)

  @doc """
  Creates a payment_method.

  ## Examples

      iex> create_payment_method(%{field: value})
      {:ok, %PaymentMethod{}}

      iex> create_payment_method(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_payment_method_with_stripe(
        %{"customer_id" => cust_id, "stripe_id" => pm_id} = params
      ) do
    with {:ok, _resp} <-
           Billing.Stripe.attatch_payment_method(cust_id, pm_id),
         {:ok, payment_method} <-
           create_payment_method(params) do
      {:ok, payment_method}
    else
      err -> err
    end
  end

  def create_payment_method(attrs \\ %{}) when is_map(attrs) do
    %PaymentMethod{}
    |> PaymentMethod.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a payment_method.

  ## Examples

      iex> update_payment_method(payment_method, %{field: new_value})
      {:ok, %PaymentMethod{}}

      iex> update_payment_method(payment_method, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_payment_method(%PaymentMethod{} = payment_method, attrs) do
    payment_method
    |> PaymentMethod.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a payment_method.

  ## Examples

      iex> delete_payment_method(payment_method)
      {:ok, %PaymentMethod{}}

      iex> delete_payment_method(payment_method)
      {:error, %Ecto.Changeset{}}

  """

  def delete_payment_method(%PaymentMethod{} = payment_method) do
    Repo.delete(payment_method)
  end

  def delete_payment_method_with_stripe(%PaymentMethod{} = payment_method) do
    with methods <- list_payment_methods_by(customer_id: payment_method.customer_id),
         count when count > 1 <- Enum.count(methods),
         {:ok, _respons} <-
           Billing.Stripe.detach_payment_method(payment_method.stripe_id),
         {:ok, response} <-
           Repo.delete(payment_method) do
      {:ok, response}
    else
      {:error, %Stripe.Error{message: message}} ->
        {:error, message}

      1 ->
        {:error, "You need at least one payment method!"}

      _err ->
        {:error, "Failed to delete payment method!"}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking payment_method changes.

  ## Examples

      iex> change_payment_method(payment_method)
      %Ecto.Changeset{data: %PaymentMethod{}}

  """
  def change_payment_method(%PaymentMethod{} = payment_method, attrs \\ %{}) do
    PaymentMethod.changeset(payment_method, attrs)
  end
end
