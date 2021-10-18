import 'package:loading_indicator/loading_indicator.dart';
import 'package:flutter/material.dart';

Widget loadingWidget(BuildContext context){
  return Center(
    child: Container(
      height: MediaQuery.of(context).size.height,
      color: Colors.transparent,
      child: LoadingIndicator(
        indicatorType: Indicator.ballPulse,

        /// Required, The loading type of the widget
        colors: const [Colors.white],
      ),
    ),
  );
}