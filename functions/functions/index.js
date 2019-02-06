const functions = require('firebase-functions');

// The Firebase Admin SDK to access the Firebase Realtime Database.
const admin = require('firebase-admin');
admin.initializeApp();

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
exports.helloWorld = functions.https.onRequest((request, response) => {
    response.send("Hello from Firebase!");
});

function send(message) {
    // Send a message to the device corresponding to the provided
    // registration token.
    admin.messaging().send(message)
        .then((response) => {
            // Response is a message ID string.
            console.log('Successfully sent message:', response);
            return;
        })
        .catch((error) => {
            console.log('Error sending message:', error);
        });
}

function isReceiver(user, lastSenderUid) { 
    return user.uid !== lastSenderUid;
}

// Listen for events
var badgeCount = 0;
exports.observeNewMessage = functions.firestore
    .document('chats/{chatUid}').onUpdate((change, context) => {
        var chatUid = context.params.chatUid;
        // Get an object representing the document
        // e.g. {'name': 'Marie', 'age': 66}
        const chat = change.after.data();
  
        // ...or the previous value before this update
        const previousValue = change.before.data();
        
        const lastSenderUid = chat.lastSenderUid;
        const memberUids = chat.memberUids;
        const receiverUid = memberUids.filter(uid => uid !== lastSenderUid)[0];
        
        const unreadCount = chat.unread[receiverUid];
        console.log("Unread " + unreadCount);
        // perform desired operations ...
        if (chat.isSending === false && chat.status === "DELIVERED") {
            
            const store = admin.firestore()
            store.collection('users').doc(receiverUid).get().then(doc => {
            if (doc.exists) {
                const receiver = doc.data();
                

                store.collection('users').doc(lastSenderUid).get().then(doc => {
                    if (doc.exists) {
                        var sender = doc.data();

                        
                        console.log(`Notification from ${sender.username}(${lastSenderUid}) to ${receiver.username}(${receiverUid})`);
                        console.log('fmctoken ' + receiver.fcmToken);
                        var message = {
                            token: receiver.fcmToken,
                            // notification: {
                            //     title: 'FUCK',
                            //     body: 'from ' + sender.username,
                            // },
                            data: {
                                chat: chatUid,
                            },
                            apns: {
                                payload: {
                                    aps: {
                                        'content-available': 1,
                                        alert: {
                                            // title: 'fuck fuch fuck',
                                            body: 'from ' + sender.username,
                                            badge: unreadCount,
                                            
                                        },
                                    }
                                }
                            }
                        }
                        
                        send(message);
                        return;
                    }
                    else {
                        console.log(`DOCUMENT /users/${lastSenderUid} DOES NOT EXIST`);
                        return;
                    }
                }).catch(reason => {
                    console.log(reason)

                })
                return;
            }
            else {
                console.log(`DOCUMENT /users/${sendToUid} DOES NOT EXIST`);
                return;
            }
        }).catch(reason => {
            console.log(reason)

        })
        }
});

exports.observeAddedUser = functions.firestore
    .document('/users/{uid}/friendRequests/{autoUid}')
    .onCreate((snap, context) => {

        var uid = context.params.uid;
        var autoUid = context.params.autoUid
        // Get an object representing the document
        // e.g. {'name': 'Marie', 'age': 66}
        const data = snap.data();
        const requestUid = Object.keys(data)[0];
        // access a particular field as you would any JS property
        console.log('User: ' + uid + ' added by: ' + requestUid);

        // perform desired operations ...
        const store = admin.firestore()
        store.collection('users').doc(uid).get().then(doc => {
            if (doc.exists) {
                const user = doc.data();
                console.log(doc.data());

                store.collection('users').doc(requestUid).get().then(doc => {
                    if (doc.exists) {
                        var requestedBy = doc.data();
                        var message = {
                            token: user.fcmToken,
                            notification: {

                                body: requestedBy.username + ' added you!',
                            },
                            data: {
                                requestedByUid: requestedBy.uid
                            }
                        }

                        send(message);
                        return;
                    }
                    else {
                        console.log(`DOCUMENT /users/${uid} DOES NOT EXIST`);
                        return;
                    }
                }).catch(reason => {
                    console.log(reason)

                })
                return;
            }
            else {
                console.log(`DOCUMENT /users/${uid} DOES NOT EXIST`);
                return;
            }
        }).catch(reason => {
            console.log(reason)

        })
    });

exports.sendPushNotifications = functions.https.onRequest((req, res) => {
    // res.send("com'n wtf");
    console.log("LOGGER --- Trying to send push message");

    var uid = 'bQGxknT8icZO7Dbhxab5DdTCR6g2';

    const store = admin.firestore()
    store.collection('users').doc(uid).get().then(doc => {
        if (doc.exists) {
            const user = doc.data();
            console.log(doc.data())
            res.send(doc.data())

            const fcmToken = user.fcmToken

            var message = {
                notification: {
                    title: 'FUCK',
                    body: 'fuckity',
                },
                token: fcmToken
            }

            send(message)

            return;
        }
        else {
            res.send("Nothing")
            return;
        }
    }).catch(reason => {
        console.log(reason)
        res.send(reason)
    })

});
    // admin.message().sendToDevice(token, payload)
    // This registration token comes from the client FCM SDKs.
    //var fcmToken = 'cfsDr-r1JYA:APA91bG-iq9dCUySp6oKQoFmxEOjgtQs9vxubNN-wj5S2MNjSe6m4WegprBmQS50Po1B4V4Eeumpn0X90DNEENSfYc_s963SdMfSYtE0kLLpTCmTnWjt73quyGX09GWp5p-KHNb4ieEi';

    // See documentation on defining a message payload.
    // var message = {
    //     notification: {
    //         title: "Push Notification TITLE",
    //         body: "Body of the message"
    //     },
    //     data: {
    //         score: '850',
    //         time: '2:45'
    //     },
    //     token: fcmToken
    // };


