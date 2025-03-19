class User 
  @@instances = []
  def initialize(name)
    @name = name
    @@instances << self
  end



  # Class Methods
  def self.generate_uniq_id
    SecureRandom.uuid
  end

  def self.find_by_id(id)
    all.find { |user| user.id == id }
  end

  def self.find_by_name(name)
    all.find_all { |user| user.name == name }
  end

  def self.all
    @@instances
  end
end



class Account
  @@instances = []

  def initialize(user)
    @id = self.generate_uniq_id
    @owner = user
    @operations = []
    @state = 1
    @@instances << self
  end

  def active?
    @state == 1
  end

  def inactive?
    @state == 0
  end

  def active! 
    @state = 1
  end
  
  def inactive!
    @state = 0
  end

  def can_withdraw?(amount)
    balance >= amount
  end


  # Class Methods
  def self.generate_uniq_id
    SecureRandom.uuid
  end

  def self.find_by_id(id)
    all.find { |account| account.id == id }
  end

  def self.find_by_user(user)
    all.find_all { |account| account.owner == user }
  end

  def self.all
    @@instances
  end

end

class Operation
  def initialize(type, amount, account)
    raise StandardError, "Account is inactive" if account.inactive?
    
    if type == "withdraw"
      raise StandardError, "Account is inactive" unless account.can_withdraw?(amount)
    end

    @id = self.generate_uniq_id
    @type = type
    @amount = amount
    @account = account
    @created_at = Time.now

  end

  def deposit
    @account.balance += @amount
    @account.operations << self
  end

  def withdraw
    raise StandardError, "Insufuscient Funds" unless account.can_withdraw?(amount)

    @account.balance -= @amount
    @account.operations << self
  end
  def self.generate_uniq_id
    SecureRandom.uuid
  end
end