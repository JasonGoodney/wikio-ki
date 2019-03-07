const functions = require('firebase-functions');
// const spawn = require('child-process-promise').spawn;
const path = require('path');
const os = require('os');
const fs = require('fs');
// The Firebase Admin SDK to access the Firebase Realtime Database.
const admin = require('firebase-admin');
admin.initializeApp();

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//

function send(message) {
    // Send a message to the device corresponding to the provided
    // registration token.
    console.log("BEGIN SENDING MESSAGE");
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

function sendToDevice(fcmToken, message) {
    // Send a message to the device corresponding to the provided
    // registration token.
    console.log("BEGIN SENDING MESSAGE");
    console.log("FMCToken:", fcmToken);
    admin.messaging().sendToDevice(fcmToken, message, {contentAvailable: true})
        .then((response) => {
            // Response is a message ID string.
            console.log('Successfully sent message:', response);
            return;
        })
        .catch((error) => {
            console.log('Error sending message:', error);
        });
}

async function getUser(uid, store) {
    let user = await store.collection('users').doc(uid)
        .get()
        .then(doc => {
            if (!doc.exists) {
                let error = "Document does not exist!";
                throw error;
            } 
            return doc.data();
        })
        .catch(reason => {
            console.log(reason);
        })
    return user;
}

async function badgeCount(userId) {
    
    var db = admin.firestore();
    
    let count = db.collection("chats").where(`unread.${userId}`, "==", true)
        .get()
        .then((querySnapshot) => {
            console.log("snap size:", querySnapshot.size);
            return querySnapshot.size;
            
        })
        .catch((error) => {
            console.log("Error getting documents: ", error);
            return 0;
        })
    return count;
}

// Listen for events

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
                
        const store = admin.firestore();
        // Handle Push Notifications
        if (chat.isSending === false && chat.status === "DELIVERED") {
            
            let receiver = getUser(receiverUid, store);
            let sender = getUser(lastSenderUid, store);

            var badge = badgeCount(receiverUid);

            Promise.all([receiver, sender, badge])
                .then(values => {
                    const receiver = values[0];
                    const sender = values[1];
                    const badge = values[2];

                    console.log(`Notification from ${sender.username}(${sender.uid}) to ${receiver.username}(${receiver.uid})`);
                    console.log('fmctoken ' + receiver.fcmToken);

                    const message = {
    
                        data: {
                            chat: chatUid,
                        },
                        notification: {
                            body: `from ${sender.username}`,
                            badge: `${badge}`,
                            sound: "default",
                        },
                    }

                    console.log("message:", message);
                    sendToDevice(receiver.fcmToken, message);
                    return;
                })
                .catch(reason => {
                    console.log(reason);
                })
        }  
});

function createMessage(data, body, badge, sound) {
    return {
        // token: token,

        data: data,
        apns: {
            payload: {
                aps: {
                    'content-available': 1,
                    alert: {
                        body: body,
                        badge: badge,
                        categoryIdentifier: "wikio-ki",
                        sound: sound
                    },
                }
            }
        }
    }
}

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

        var addedUid = context.params.uid;
        var autoUid = context.params.autoUid
        // Get an object representing the document
        // e.g. {'name': 'Marie', 'age': 66}
        const data = snap.data();
        const requestUid = Object.keys(data)[0];
        // access a particular field as you would any JS property
        console.log('User: ' + addedUid + ' added by: ' + requestUid);

        // perform desired operations ...
        const store = admin.firestore();

        let added = getUser(addedUid, store);
        let requestedBy = getUser(requestUid, store);

        Promise.all([added, requestedBy])
            .then(values => {
                const added = values[0];
                const requestedBy = values[1];

                const message = {
    
                    data: {
                        equestedByUid: requestedBy.uid
                    },
                    notification: {
                        body: `${requestedBy.username} added you!`,
                        sound: "default",
                    },
                }

                console.log("message:", message);
                sendToDevice(added.fcmToken, message);


                return;
            })
            .catch(reason => {
                console.log(reason);
            })
    });

// [START observeCreateAccount]
// exports.observeCreateAccount = functions.firestore
    // .document('/users/{uid}')
    // .onCreate((snap, context) => {
    //     const uid = context.params.uid;
    //     const store = admin.firestore();

    //     const user = snap.data();
    //     const bucket = admin.storage().bucket();



        
    // });
// [END observeCreateAccount]

// [START generateThumbnail]
/**
 * When an image is uploaded in the Storage bucket We generate a thumbnail automatically using
 * ImageMagick.
 */
// [START generateThumbnailTrigger]
// exports.generateThumbnail = functions.storage.object().onFinalize(async (object) => {
//     // [END generateThumbnailTrigger]
//       // [START eventAttributes]
//       const fileBucket = object.bucket; // The Storage bucket that contains the file.
//       const filePath = object.name; // File path in the bucket.
//       const contentType = object.contentType; // File content type.
//       const metageneration = object.metageneration; // Number of times metadata has been generated. New objects have a value of 1.
//       // [END eventAttributes]
    
//       // [START stopConditions]
//       // Exit if this is triggered on a file that is not an image.
//       if (!contentType.startsWith('image/')) {
//         return console.log('This is not an image.');
//       }
    
//       // Get the file name.
//       const fileName = path.basename(filePath);
//       // Exit if the image is already a thumbnail.
//       if (fileName.startsWith('thumb_')) {
//         return console.log('Already a Thumbnail.');
//       }
//       // [END stopConditions]
    
//       // [START thumbnailGeneration]
//       // Download file from bucket.
//       const bucket = admin.storage().bucket(fileBucket);
//       const tempFilePath = path.join(os.tmpdir(), fileName);
//       const metadata = {
//         contentType: contentType,
//       };
      
//       await bucket.file(filePath).download({destination: tempFilePath});
//       console.log('Image downloaded locally to', tempFilePath);
//       // Generate a thumbnail using ImageMagick.
//       await spawn('convert', [tempFilePath, '-thumbnail', '200x200>', tempFilePath]);
//       console.log('Thumbnail created at', tempFilePath);
//       // We add a 'thumb_' prefix to thumbnails file name. That's where we'll upload the thumbnail.
//       const thumbFileName = `thumb_${fileName}`;
//       const thumbFilePath = path.join(path.dirname(filePath), thumbFileName);
//       // Uploading the thumbnail.
//       await bucket.upload(tempFilePath, {
//         destination: thumbFilePath,
//         metadata: metadata,
//       });
//       // Once the thumbnail has been uploaded delete the local file to free up disk space.
//       return fs.unlinkSync(tempFilePath);
//       // [END thumbnailGeneration]
// });
// // [END generateThumbnail]