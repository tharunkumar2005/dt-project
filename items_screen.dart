import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'payment_screen.dart';

class ItemsScreen extends StatelessWidget {
  final String? scannedBarcode;

  ItemsScreen({this.scannedBarcode});

  @override
  Widget build(BuildContext context) {
    var cart = Provider.of<CartProvider>(context, listen: true);

    return Scaffold(
      appBar: AppBar(title: const Text("Products")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No products available"));
          }

          var products = snapshot.data!.docs;

          if (scannedBarcode != null && scannedBarcode!.isNotEmpty) {
            products = products.where((doc) {
              var data = doc.data() as Map<String, dynamic>?;
              return data != null && data['barcode'] == scannedBarcode;
            }).toList();
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              var doc = products[index];
              var data = doc.data() as Map<String, dynamic>?;

              if (data == null) return const SizedBox();

              final String id = doc.id;
              final String name = data['name'] ?? 'Unnamed Product';
              final String imageUrl = data['image'] ?? '';
              final int price = (data['price'] as num?)?.toInt() ?? 0;
              final int stock = (data['stock'] as num?)?.toInt() ?? 0;
              final int cartQuantity = cart.getQuantity(id);

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: imageUrl.isNotEmpty
                      ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.image_not_supported, size: 50),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Price: ₹$price | Stock: ${stock - cartQuantity}"),
                  trailing: stock == 0
                      ? const Text("Out of Stock", style: TextStyle(color: Colors.red))
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: cartQuantity > 0
                                  ? () => cart.updateItem(id, name, price, imageUrl, stock, false, context)
                                  : null,
                            ),
                            Text("$cartQuantity"),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: cartQuantity < stock
                                  ? () => cart.updateItem(id, name, price, imageUrl, stock, true, context)
                                  : null,
                            ),
                          ],
                        ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cart, child) => Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total: ₹${cart.totalPrice}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentScreen(amount: cart.totalPrice.toInt()),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("Proceed to Pay"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
