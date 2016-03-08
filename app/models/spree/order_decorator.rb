Spree::Order.class_eval do

  has_one :order_subscription, class_name: "Spree::OrderSubscription", dependent: :destroy
  has_one :parent_subscription, through: :order_subscription
  has_many :subscriptions, class_name: "Spree::Subscription",
                           foreign_key: :parent_order_id,
                           dependent: :restrict_with_error

  self.state_machine.after_transition to: :complete, do: :enable_subscriptions, if: :any_disabled_subscription?

  def available_payment_methods
    if subscriptions.exists?
      @available_payment_methods = Spree::Gateway.active
    else
      @available_payment_methods ||= Spree::PaymentMethod.active
    end
  end

  private

    def enable_subscriptions
      subscriptions.each do |subscription|
        subscription.update(source: payments.from_credit_card.first.source,
          enabled: true, ship_address: ship_address.clone, bill_address: bill_address.clone)
      end
    end

    def any_disabled_subscription?
      subscriptions.disabled.any?
    end

end
