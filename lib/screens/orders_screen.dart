import 'package:flutter/material.dart';
import 'package:flutter_complete_guide/widgets/app_drawer.dart';
import 'package:provider/provider.dart';
import '/providers/orders.dart';
import '/widgets/order_item.dart' as ord;

class OrdersScreen extends StatefulWidget {
  static const routeName = '/orders-screen';

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  Future? _ordersFuture;
  Future _obtainOrdersFuture() {
    return Provider.of<Orders>(context, listen: false).fetchAndSetOrders();
  }

  @override
  void initState() {
    _ordersFuture = _obtainOrdersFuture();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print('building ordersssss!!!!');

    return Scaffold(
        appBar: AppBar(
          title: Text('Your Orders'),
        ),
        drawer: AppDrawer(),
        body: FutureBuilder(
          future: _ordersFuture,
          builder: ((ctx, dataSnapshot) {
            if (dataSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else {
              if (dataSnapshot.error != null) {
                return Center(
                  child: Text('An Error Occured!!'),
                );
              } else {
                return Consumer<Orders>(
                  builder: (ctx, orderData, _) => ListView.builder(
                    itemBuilder: (ctx, i) => ord.OrderItem(
                      orderData.orders[i],
                    ),
                    itemCount: orderData.orders.length,
                  ),
                );
              }
            }
          }),
        ));
  }
}
