import 'package:intl/intl.dart';

/*
  type : Class
  packages used: none
  function: holds all general methods used in the whole app
 */

class Functions{

  //creates a timestamp string with how long ago a task was done
  static String timeAgoSinceDate(String dateString, {bool numericDates = true}) {
    DateTime notificationDate = DateFormat("dd-MM-yyyy h:mma").parse(dateString);
    final date2 = DateTime.now();
    final difference = date2.difference(notificationDate);

    if (difference.inDays > 8) {
      return dateString;
    } else if ((difference.inDays / 7).floor() >= 1) {
      return (numericDates) ? '1w ago' : 'Last week';
    } else if (difference.inDays >= 2) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays >= 1) {
      return (numericDates) ? '1d ago' : 'Yesterday';
    } else if (difference.inHours >= 2) {
      return '${difference.inHours}h ago';
    } else if (difference.inHours >= 1) {
      return (numericDates) ? '1h ago' : 'An hour ago';
    } else if (difference.inMinutes >= 2) {
      return '${difference.inMinutes}mins ago';
    } else if (difference.inMinutes >= 1) {
      return (numericDates) ? '1mins ago' : 'A minute ago';
    } else if (difference.inSeconds >= 3) {
      return '${difference.inSeconds} seconds ago';
    } else {
      return 'Just now';
    }
  }

}