require 'sinatra'
require 'securerandom'
require 'json'

ACCOUNTS_JSON ='accounts.json'

class Account
  attr_reader :num_account, :balance, :state_account, :user, :operations
  def initialize(user)
    @balance = 0
    @state_account=1
    @num_account=SecureRandom.uuid
    @operations = []
    @user=user
  end

  def deposite(amount)
    @balance += amount
    @operations << { type: "deposit", amount: amount, date: Time.now }
  end

  def withdraw(amount)
    @balance -= amount
    @operations << { type: "withdraw", amount: amount, date: Time.now }
  end

  #serialiser
  def to_h()
    {
      "user" => @user,
      "num_account" => @num_account,
      "balance" => @balance,
      "state_account" => @state_account,
      "operations" =>@operations
    }
  end
  #deserialiser
  def self.from_hash(hash)
    account = Account.new(hash["user"])
    account.instance_variable_set(:@num_account, hash["num_account"])
    account.instance_variable_set(:@balance, hash["balance"])
    account.instance_variable_set(:@state_account, hash["state_account"])
    account.instance_variable_set(:@operations, hash["operations"] || [])
    return account
  end
end

def load_accounts()
  if File.exist?(ACCOUNTS_JSON)
    #file.read lit le contenu du fichier json et la retourne sous forme de chaine de caracteres et parse convertit
    # la chaine json en un objet ruby comme un array ou un hash
    accounts = JSON.parse(File.read(ACCOUNTS_JSON)) 
  else
    accounts=[]
  end
end
def save_accounts(accounts)
  accounts_data=accounts.map(&:to_h)
  #pretty_generate fait le contraire de parse,elle convertit le tableau d'article en une chaine de caracteres au format JSON
  #file.write enregistre ou ecrit la chaine json genereé dan le fichier
  File.write(ACCOUNTS_JSON,JSON.pretty_generate(accounts_data))
end

get '/' do
  erb:'index'
end

get '/accounts' do
  @accounts=load_accounts()
  erb:'accounts'
end

get '/new' do
  erb:'new_account'
end

post '/account/create' do
  accounts=load_accounts()
  user_name = params["user"]
  new_account = Account.new(user_name)
  accounts.push(new_account)
  save_accounts(accounts)
  redirect '/accounts'
end

post '/accounts/:num_account/desactiver' do |num_account|
  accounts=load_accounts()
  account=accounts.find { |a| a["num_account"] == num_account }
  if account["state_account"] == 1
    account["state_account"] = 0
    save_accounts(accounts)
    redirect "/accounts"
  else
    "compte non trouvé"
  end
end

post '/accounts/:num_account/activer' do |num_account|
  accounts = load_accounts()
  account = accounts.find { |a| a["num_account"] == num_account }
  if account && account["state_account"] == 0
    account["state_account"] = 1
    save_accounts(accounts)
    redirect "/accounts"
  else
    "Compte non trouvé"
  end
end

get '/accounts/:num_account/deposit' do |num|
  accounts = load_accounts()
  @account = accounts.find { |a| a["num_account"] == num }
  erb:'deposit'
end

post '/accounts/:num_account/deposit' do |num|
  accounts = load_accounts()
  account_data = accounts.find { |a| a["num_account"] == num }
  if account_data.nil?
    return "Compte non trouvé"
  end
  amount = params["amount"].to_i
  if amount <= 0
    return erb:error, locals: { message: "Montant invalide" }
  end

  # Convertir en instance d'Account pour utiliser la méthode deposite
  account = Account.from_hash(account_data)
   account.deposite(amount)
    account_data["balance"] = account.balance  # Mettre à jour le solde dans le tableau
    save_accounts(accounts)  # Sauvegarder les comptes mis à jour
    #Transactions_log.write_file("depot sur le compte";account["num_account"];Time.now;account["user"])
    redirect "/accounts"
end

# Route pour afficher le formulaire de retrait
get '/accounts/:num_account/withdraw' do |num|
  accounts = load_accounts()
  @account = accounts.find { |a| a["num_account"] == num }
  erb:'withdraw' 
end

post '/accounts/:num_account/withdraw' do |num|
  accounts = load_accounts()
  account_data = accounts.find { |a| a["num_account"] == num }
  if account_data.nil?
    return "Compte non trouvé"
  end
  amount = params["amount"].to_i
  if amount <= 0
    return erb:error, locals: { message: "Montant invalide" }
  elsif amount > account_data["balance"]
    return erb:error, locals: { message: "fonds insuffisant" }
  end

  # Convertir l'objet JSON en instance Account pour utiliser la méthode withdraw
  account = Account.from_hash(account_data)
  account.withdraw(amount)
    account_data["balance"] = account.balance  # Met à jour le solde dans les données du compte
    save_accounts(accounts) 
    redirect "/accounts"
end

get '/user/accounts' do
  user_name = params["user"]
  accounts = load_accounts()
  @accounts = accounts.select { |account| account["user"] == user_name }
  erb:'user_accounts' 
end

get '/accounts/:num_account/operations' do |num_account|
  accounts = load_accounts()
  account_data = accounts.find { |a| a["num_account"] == num_account }
  if account_data.nil?
    return "Compte non trouvé"
  end
  @account = Account.from_hash(account_data)
  save_accounts(accounts)
    # Convertir le hash en objet Account
  erb :operations  # Afficher la page des opérations
end
