const functions = require('firebase-functions');
const spawn = require('child-process-promise').spawn;
const path = require('path');
const os = require('os');
const fs = require('fs');
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
        const chatBefore = change.before.data();

        if (chatBefore.lastMessageSent === chat.lastMessageSent) {
            return;
        }
        
        const lastSenderUid = chat.lastSenderUid;
        const memberUids = chat.memberUids;
        const receiverUid = memberUids.filter(uid => uid !== lastSenderUid)[0];
        
        var unreadCount = parseInt(chat.unread[receiverUid]);
        const store = admin.firestore();
        // Handle Push Notifications
        if (chat.isSending === false && chat.status === "DELIVERED") {
            
            
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


function increase(unreadCount, ref, unreadKey) {
    ref.update({
        [unreadKey]: unreadCount
    })
    .then(doc => {
        console.log(`${unreadKey} has ${unreadCount} unread messages`);
        return;
    })
    .catch(error => {
        // The document probably doesn't exist.
        console.error("Error updating document: ", error);
    }); 
}

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
    
// [START generateThumbnail]
/**
 * When an image is uploaded in the Storage bucket We generate a thumbnail automatically using
 * ImageMagick.
 */
// [START generateThumbnailTrigger]
exports.generateThumbnail = functions.storage.object().onFinalize(async (object) => {
    // [END generateThumbnailTrigger]
      // [START eventAttributes]
      const fileBucket = object.bucket; // The Storage bucket that contains the file.
      const filePath = object.name; // File path in the bucket.
      const contentType = object.contentType; // File content type.
      const metageneration = object.metageneration; // Number of times metadata has been generated. New objects have a value of 1.
      // [END eventAttributes]
    
      // [START stopConditions]
      // Exit if this is triggered on a file that is not an image.
      if (!contentType.startsWith('image/')) {
        return console.log('This is not an image.');
      }
    
      // Get the file name.
      const fileName = path.basename(filePath);
      // Exit if the image is already a thumbnail.
      if (fileName.startsWith('thumb_')) {
        return console.log('Already a Thumbnail.');
      }
      // [END stopConditions]
    
      // [START thumbnailGeneration]
      // Download file from bucket.
      const bucket = admin.storage().bucket(fileBucket);
      const tempFilePath = path.join(os.tmpdir(), fileName);
      const metadata = {
        contentType: contentType,
      };
      
      await bucket.file(filePath).download({destination: tempFilePath});
      console.log('Image downloaded locally to', tempFilePath);
      // Generate a thumbnail using ImageMagick.
      await spawn('convert', [tempFilePath, '-thumbnail', '200x200>', tempFilePath]);
      console.log('Thumbnail created at', tempFilePath);
      // We add a 'thumb_' prefix to thumbnails file name. That's where we'll upload the thumbnail.
      const thumbFileName = `thumb_${fileName}`;
      const thumbFilePath = path.join(path.dirname(filePath), thumbFileName);
      // Uploading the thumbnail.
      await bucket.upload(tempFilePath, {
        destination: thumbFilePath,
        metadata: metadata,
      });
      // Once the thumbnail has been uploaded delete the local file to free up disk space.
      return fs.unlinkSync(tempFilePath);
      // [END thumbnailGeneration]
});
// [END generateThumbnail]