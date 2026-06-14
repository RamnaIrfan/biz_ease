const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

/**
 * 🔔 SEND PUSH NOTIFICATION FOR VERIFICATION
 * Triggered after an order is placed.
 */
exports.sendOrderVerification = functions.https.onCall(async (data, context) => {
  const { orderId, customerName, totalAmount, fcmToken } = data;

  if (!fcmToken) {
    throw new functions.https.HttpsError('invalid-argument', 'FCM Token is missing');
  }

  const message = {
    token: fcmToken,
    notification: {
      title: 'Action Required: Verify Your Order 🛍️',
      body: `Hello ${customerName}, please confirm your order #${orderId.substring(0, 8).toUpperCase()} for Rs. ${totalAmount}.`,
    },
    data: {
      orderId: orderId,
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
      type: 'order_verification'
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'order_verification',
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
      },
    },
    apns: {
      payload: {
        aps: {
          category: 'ORDER_VERIFICATION',
        },
      },
    },
  };

  try {
    const response = await messaging.send(message);
    console.log('Successfully sent message:', response);
    return { success: true };
  } catch (error) {
    console.error('Error sending message:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * 🧹 AUTO-CANCEL EXPIRED ORDERS
 * Runs every 5 minutes to cancel orders that weren't confirmed in 10 minutes.
 */
exports.cancelExpiredOrders = functions.pubsub.schedule('every 5 minutes').onRun(async (context) => {
  const tenMinutesAgo = admin.firestore.Timestamp.fromDate(new Date(Date.now() - 10 * 60 * 1000));
  
  const snapshot = await db.collection('orders')
    .where('status', '==', 'pending_confirmation')
    .where('createdAt', '<=', tenMinutesAgo)
    .get();

  if (snapshot.empty) return null;

  const batch = db.batch();
  snapshot.docs.forEach(doc => {
    batch.update(doc.ref, { 
      status: 'cancelled', 
      notes: 'Auto-cancelled: Verification timeout (10 min)' 
    });
  });

  await batch.commit();
  console.log(`Auto-cancelled ${snapshot.size} expired orders.`);
  return null;
});
