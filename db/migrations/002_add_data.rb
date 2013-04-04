Sequel.migration do
  up do
    
    users = DB[:users]
    names = %w/llama alpaca vicugna guanaco bactrian dromedary/
    names.each do |name| 
      users.insert(:name => name)
    end

    tasks = DB[:tasks]
    tasks.insert(:name => 'finder1', :description => 'find the key!')
    tasks.insert(:name => 'finder2', :description => 'find the key again!')

  end

end
