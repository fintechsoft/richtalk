const APP_ENV_DEV = true;
const ENABLE_TWILIO_AUTH = false;
const ENABLE_FIREBASE_AUTH = false;

//TWILIO SET UP ACCOUNTS
const accountSid = 'AC6005d61304e031b5852e8c5de6108306';// replace with Account SID
const authToken = '192197d8a1f28698eb393c67edd6a863';  // replace with Auth Token
const serviceSid = 'VA408404fe7d9a65a95b274f296a32dd26'; //

//agora app id
const APP_ID = '01813f6ae6d34ac58a2f9adea03d55eb';

//agora token path
const tokenpath = "https://agora-generate-token254.herokuapp.com/generaltokenkoodle";

//firebase server token
const serverToken =
    "AAAAZzAzU_o:APA91bFCGPapQRgLape62lBayyk_N8t3dsZsoWaKPtiBEStUcDqEK-ak7BqY8qh8KDRMxXCM8rli-_tg-L7SGRsBVAB9rwquBLHofcO7QrxwrC-wKvnVrH0U4GDLsI78KLKEL5jCjfQR";

/*
    sharing of links configurations
 */
//firebase deep link share url
const deeplinkuriPrefix = "https://roomiesroom.page.link";

/*
  valid website domain where users will be directed if the app is not installed
 */
const websitedomain = "https://koodle.webflow.io";

/*
    app package name
    package name to checked if its installed and if not then ${websitedomain} will invoked
 */
const packagename = "com.aluta.roomies";

/*
* google play store url, for users to update the app
* */
const playstoreUrl =
    "https://play.google.com/store/apps/details?id=com.aluta.roomies&hl=en_US&gl=US";
