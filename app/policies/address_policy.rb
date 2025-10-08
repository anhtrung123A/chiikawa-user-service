class AddressPolicy
  attr_reader :user, :address

  def initialize(user, address)
    @user = user
    @address = address
  end

  def create?
    true
  end

  def show?
    owner? || admin?
  end

  def update?
    owner?
  end

  def destroy?
    owner?
  end

  def set_default_address?
    owner?
  end

  private

  def owner?
    user == address.user
  end

  def admin?
    user.role == "admin"
  end
end
