
trigger TransactionTrigger on Transaction__c (before insert) {
    
    // Fetching the current date
    Date today = Date.today();
    
    // Fetching the user's daily credit limit and transaction count
    User user = [SELECT Daily_Credit_Limit__c, Transaction_Count__c FROM User WHERE Id = :UserInfo.getUserId()];

    // Initializing variables for credit limit and transaction count
    Decimal dailyCreditLimit = user.Daily_Credit_Limit__c;
    Integer transactionCount = user.Transaction_Count__c;
    
    // Initializing variables to track total credit and transaction count for the day
    Decimal totalCredit = 0;
    Integer totalTransactions = 0;
    
    // Querying existing transactions for the day
    AggregateResult[] existingTransactions = [SELECT SUM(Credit_Amount__c)totalCredit, COUNT(Id)totalTransactions 
                                             FROM Transaction__c 
                                             WHERE CreatedDate = TODAY AND CreatedById = :UserInfo.getUserId() 
                                             GROUP BY CreatedById];
    
    if (existingTransactions.size() > 0) {
        // Updating total credit and transaction count for the day
        totalCredit = (Decimal)existingTransactions[0].get('totalCredit');
        totalTransactions = (Integer)existingTransactions[0].get('totalTransactions');
    }
    
    // Iterating through the new transactions
    for (Transaction__c transaction : Trigger.new) {
        
        // Checking if the credit amount exceeds the daily credit limit
        if (transaction.Credit_Amount__c > dailyCreditLimit) {
            transaction.addError('Your daily credit limit is exceeded.');
        }
        
        // Checking if the transaction count exceeds the limit
        if (totalTransactions >= 3) {
            transaction.addError('Transaction limit exceeded. You cannot perform more than 3 transactions in a day.');
        }
        
        // Processing the transaction if credit and transaction count checks pass
        if (!transaction.hasErrors()) {
            // Updating total credit and transaction count
            totalCredit += transaction.Credit_Amount__c;
            totalTransactions++;
            
            // Updating user's daily credit spent and transaction count
            user.Daily_Credit_Spent__c = totalCredit;
            user.Transaction_Count__c = totalTransactions;
            
            // Confirming the successful completion of the transaction
            transaction.Status__c = 'Completed';
        }
    }
    
    // Updating the user record with the updated values
    update user;
    
}
