class AddressPolicy
  attr_reader :user, :address

  def initialize(user, address)
    @user = user
    @address = address
  end

  def create?
    true
  end

  def destroy?
    user == address.user
  end

  def update?
    user == address.user
  end
  def show?
    user == address.user || user.role == "admin"
  end
end
