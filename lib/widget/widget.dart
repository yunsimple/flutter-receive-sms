import 'package:flutter/material.dart';

Widget emptyPageWidget({String title = 'No email received', String subTitle = 'Try the drop-down refresh', String image = 'empty'}) {
  Widget empty = SingleChildScrollView(
    child: Center(
      child: Column(
        children: [
          Image.asset('assets/images/$image.png'),
          Text(title, style: const TextStyle(
              color: Colors.grey,
            fontSize: 20
          )),
          const SizedBox(height: 10,),
          Text(subTitle, style: const TextStyle(
              color: Colors.grey,
              fontSize: 15
          )),
        ],
      ),
    ),
  );
  return empty;
}