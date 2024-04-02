## Auction Portal System

The database of the auction portal allows users to create accounts and list or bid on products. The bidding process proceeds as follows: the seller sets the end date of the auction, the starting price, the buy now price, and other details. The bidder takes the lead if their offer is higher than the current highest bid. The auction ends when the bidder's offer equals or exceeds the buy now price (their offer matches the buy now price), and the transaction proceeds further (payments, followed by shipping). Based on the entry in the database about the completed order, the user can leave feedback about the buyer or seller.

Additionally, a recurring task should be created to run a procedure checking if the closed_at value for records in the Items table has exceeded the current time. If so, the availability column will be changed to 0, which would be equivalent to starting the fulfillment of the highest bid. If no bid exceeding the starting price has been received, the auction simply closes.

### Maintenance Strategy (Backup)

1. **Creating backups:**
   - Daily at 3:00 AM.
   - Use Maintenance Plans or SQL Server Agent in SQL Server to schedule an automatic backup creation process.
2. **Retention of backups:**
   - Retain backups for the last 7 days.
   - Configure Retention Policy in Maintenance Plans or SQL Server Agent to automatically delete backups older than 7 days.
3. **Testing backups:**
   - Perform restoration tests weekly in a test environment.
   - Utilize RESTORE commands in SQL Server to verify and confirm the correctness of the restoration process.

### ER Diagram

![alt text](https://github.com/iamk-cper/SQL-AuctionHouse/blob/main/er.jpg?raw=true)

### Database Schema

![alt text](https://github.com/iamk-cper/SQL-AuctionHouse/blob/main/schema.jpg?raw=true)

### Tables:
- Users - table containing user data
- RegistrationInfo - independent table storing user registration dates
- Categories - selectable categories of items
- Items - table of all listed items (ongoing and completed auctions)
- Wishlist - table of items added to the wishlist with information on whose wishlist they are on
- Bids - list of all submitted bids (including invalid or too low bids)
- Orders - table of created orders
- ShippingDetails - table of shipping details for orders forwarded for fulfillment, interpreted as inheriting from orders, its primary key orderid is also a foreign key. ShippingDetails extends order data with shipping details.
- Feedback - table of user ratings on buyers and sellers
- Reports - table of user reports

### Function Descriptions

- `GetUserWishlist(@userId INT)`: returns a table of items on the user's wishlist.
- `CheckLoginCredentials(@username VARCHAR(64), @password VARCHAR(64))`: returns 1 for correct login data or 0 for incorrect data.
- `GetItemsByCategory(@categoryName VARCHAR(64))`: lists available items from the specified category (by name).
- `CalculateSellerRating(@sellerId INT)`: calculates the rating of the selected seller.
- `CalculateBidderRating(@bidderId INT)`: calculates the rating of the selected buyer.
- `GetUserOrders(@userId INT)`: lists orders of the selected user.

### Procedure Descriptions

- `AddNewItem`: procedure adding a new item to the item list.
- `SubmitFeedback`: procedure allowing the user to submit feedback on the seller/buyer based on completed orders.
- `CreateReport`: procedure allowing the user to submit a report.
- `CreateUser`: procedure creating a new user based on provided data and displaying appropriate messages/errors.
- `CheckLoginProcedure`: procedure using the `CheckLoginCredentials` function, outputs an appropriate message depending on the correctness of the data.

### View Descriptions

- `BidderRatings`: view listing all buyers who received feedback along with their average rating.
- `SellerRatings`: view listing all sellers who received feedback along with their average rating.
- `ItemsCountByCategory`: view listing each category and the number of available items belonging to it.
- `AvailableItems`: view showing data only for available items (availability = 1).

### Trigger Descriptions

- `UpdateMaxBid`: trigger modifying the highest bid for an item if a higher bid than the current highest one appears.
- `Trigger_CheckBuyNow`: trigger checking if a newly incoming offer exceeds the buy now price and passing the item for fulfillment if so.
- `Trigger_CreatePaymentOnAvailabilityChange`: if the item is passed for fulfillment, this trigger will create an order in orders.
- `Trigger_OrderConfirmed`: if the order is confirmed, it will create shipping.
- `Trigger_UpdateOrdersStatus`: if shipping is confirmed, the order will be finalized.
- `Trigger_CreateUserRegistrationInfoTrigger`: for newly created accounts, it will save registration information in the database.
